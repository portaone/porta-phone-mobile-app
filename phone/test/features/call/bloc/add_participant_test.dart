import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

import 'call_bloc_harness.dart';

/// Calling somebody into a call or a room from the call screen: a linked call
/// that joins the conversation once answered. Placing it and giving the
/// conversation back when it does not come up are the linked call's own (see
/// linked_call_test.dart); what is pinned here is what joining adds.
const _offer = {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'};

CallBlocHarness _harness({bool conferences = true}) =>
    CallBlocHarness(lines: 3, capabilities: CallCapabilitiesConfig(isConferenceEnabled: conferences));

/// Calls 200 into the conversation of [anchorCallId] and returns the new
/// call's id.
Future<String> _add(CallBlocHarness h, {required String anchorCallId}) async {
  h.bloc.add(CallControlEvent.participantCallPlaced(anchorCallId: anchorCallId, number: '200'));
  await h.settle(() => h.bloc.state.linkedCall != null);
  final callId = h.bloc.state.linkedCall!.callId;
  // The new call's connection, as the outgoing pipeline would have left it
  // once its offer was sent.
  h.peers.complete(callId, FakePeerConnection());
  return callId;
}

Future<void> _hangUp(CallBlocHarness h, String callId, int code) async {
  final line = h.bloc.state.retrieveActiveCall(callId)!.line;
  h.signaling.emit(HangupEvent(line: line, callId: callId, code: code, reason: 'test'));
  await h.settle(() => h.bloc.state.retrieveActiveCall(callId) == null && h.bloc.state.linkedCall == null);
}

Future<void> _answer(CallBlocHarness h, String callId) async {
  final line = h.bloc.state.retrieveActiveCall(callId)!.line;
  h.signaling.emit(AcceptedEvent(line: line, callId: callId));
  await h.settle(() => h.bloc.state.linkedCall == null || h.bloc.state.linkedCall!.awaitingRoom);
}

/// Room 7 with legs a and b, up: the merge acknowledged and the room's offer
/// answered.
Future<void> _roomUp(CallBlocHarness h) async {
  h.seedEstablishedCall('a', line: 0);
  h.seedEstablishedCall('b', line: 1);
  h.bloc.add(const CallControlEvent.merged(['a', 'b']));
  await pumpEventQueue();
  h.signaling.emit(
    ConferenceOfferEvent(
      room: 7,
      jsep: _offer,
      participants: const [
        ConferenceParticipant(line: 0, callId: 'a', muted: false),
        ConferenceParticipant(line: 1, callId: 'b', muted: false),
      ],
    ),
  );
  await h.settle(() => h.bloc.state.conference.phase == ConferencePhase.active);
  h.peerFactory.created.single.onConnectionState!(RTCPeerConnectionState.RTCPeerConnectionStateConnected);
  await pumpEventQueue();
}

void _setRoomPhase(CallBlocHarness h, ConferencePhase phase) {
  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
  h.bloc.emit(h.bloc.state.copyWith(conference: h.bloc.state.conference.copyWith(phase: phase)));
}

List<({String callId, bool onHold})> _resumes(CallBlocHarness h, String callId) =>
    h.callkeep.held.where((it) => it.callId == callId && !it.onHold).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallBlocHarness h;
  setUp(() => h = _harness());
  tearDown(() => h.close());

  group('into a call', () {
    test('holds the call and places a call that joins it', () async {
      h.seedEstablishedCall('b', line: 0);

      final c = await _add(h, anchorCallId: 'b');

      expect(h.callkeep.held, [(callId: 'b', onHold: true)]);
      expect(
        h.bloc.state.linkedCall,
        LinkedCall(callId: c, anchorCallId: 'b', purpose: LinkedCallPurpose.join, anchorWasLive: true),
      );
    });

    test('an answered call is merged with it, once', () async {
      h.seedEstablishedCall('b', line: 0);
      final c = await _add(h, anchorCallId: 'b');

      await _answer(h, c);

      final merges = h.signaling.requests.whereType<MergeRequest>().toList();
      expect(merges, hasLength(1));
      expect(merges.single.lines, [0, 1]);
      expect(h.bloc.state.linkedCall, isNull);
      expect(h.bloc.state.conference.legIds, {'b', c});
      expect(_resumes(h, 'b'), isEmpty);
    });

    test('a Merge pressed as the call is answered does not merge twice', () async {
      h.seedEstablishedCall('b', line: 0);
      final c = await _add(h, anchorCallId: 'b');

      h.signaling.emit(AcceptedEvent(line: 1, callId: c));
      h.bloc.add(CallControlEvent.merged(['b', c]));
      await h.settle(() => h.bloc.state.linkedCall == null);
      await h.settle(() => false);

      expect(h.signaling.requests.whereType<MergeRequest>(), hasLength(1));
    });

    test('a refused merge leaves the answered call as an ordinary one', () async {
      h.seedEstablishedCall('b', line: 0);
      final c = await _add(h, anchorCallId: 'b');
      h.signaling.failure = const WebtritSignalingErrorException(1, 500, 'conference_already_active');

      await _answer(h, c);

      expect(h.bloc.state.linkedCall, isNull);
      expect(h.bloc.state.retrieveActiveCall(c), isNotNull);
      expect(h.bloc.state.conference.isPresent, isFalse);
      expect(h.callkeep.endCalls, isEmpty);
      expect(_resumes(h, 'b'), isEmpty);
      expect(h.notifications.whereType<ConferenceRefusedNotification>(), hasLength(1));
    });

    test('a declined call gives the call back and says so', () async {
      h.seedEstablishedCall('b', line: 0);
      final c = await _add(h, anchorCallId: 'b');

      await _hangUp(h, c, 603);

      expect(_resumes(h, 'b'), hasLength(1));
      expect(h.notifications.whereType<LinkedCallFailedNotification>().map((it) => it.failure), [
        LinkedCallFailure.declined,
      ]);
    });
    test('a call gone by the time its merge is refused gives the call back', () async {
      // Every ending the bloc knows of is queued behind the join; this pins
      // what happens should one ever not be. The link has to outlive the join
      // so the give-back still finds it.
      h.seedEstablishedCall('b', line: 0);
      final c = await _add(h, anchorCallId: 'b');
      h.signaling.gate = Completer<void>();
      h.signaling.failure = const WebtritSignalingErrorException(1, 500, 'no_such_line');

      h.signaling.emit(AcceptedEvent(line: 1, callId: c));
      await h.settle(() => h.signaling.requests.whereType<MergeRequest>().isNotEmpty);
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      h.bloc.emit(h.bloc.state.copyWithPopActiveCall(c));
      h.signaling.gate!.complete();
      await h.settle(() => _resumes(h, 'b').isNotEmpty);

      expect(h.bloc.state.linkedCall, isNull);
      expect(_resumes(h, 'b'), hasLength(1));
    });

    test('merged into a room while it rang, it is added to that room', () async {
      // The call was placed for a plain call; by the answer that call is a leg,
      // and a merge asked for a leg would be turned down without a word.
      h.seedEstablishedCall('b', line: 0);
      final c = await _add(h, anchorCallId: 'b');
      h.seedEstablishedCall('d', line: 2, held: true);
      h.bloc.add(const CallControlEvent.merged(['b', 'd']));
      await pumpEventQueue();
      h.signaling.emit(
        ConferenceOfferEvent(
          room: 7,
          jsep: _offer,
          participants: const [
            ConferenceParticipant(line: 0, callId: 'b', muted: false),
            ConferenceParticipant(line: 2, callId: 'd', muted: false),
          ],
        ),
      );
      await h.settle(() => h.bloc.state.conference.phase == ConferencePhase.active);
      h.peerFactory.created.single.onConnectionState!(RTCPeerConnectionState.RTCPeerConnectionStateConnected);
      await pumpEventQueue();

      await _answer(h, c);

      expect(h.signaling.requests.whereType<MergeRequest>(), hasLength(1), reason: 'only the one that built the room');
      expect(h.signaling.requests.whereType<ConferenceAddRequest>().map((it) => it.line), [1]);
      expect(h.bloc.state.conference.isLeg(c), isTrue);
    });
  });

  group('into the room, through one of its legs', () {
    test('holds no leg, and the answered call is added to the room', () async {
      await _roomUp(h);
      final heldBefore = h.callkeep.held.length;

      final c = await _add(h, anchorCallId: 'a');
      expect(h.bloc.state.linkedCall!.intoRoom, isTrue);
      expect(h.bloc.state.linkedCall!.anchorWasLive, isFalse);
      expect(h.callkeep.held.skip(heldBefore).where((it) => it.onHold), isEmpty);
      expect(h.bloc.state.retrieveActiveCall(c)!.line, 2);

      await _answer(h, c);

      expect(h.signaling.requests.whereType<ConferenceAddRequest>().map((it) => it.line), [2]);
      expect(h.signaling.requests.whereType<MergeRequest>(), hasLength(1), reason: 'only the one that built the room');
      expect(h.bloc.state.linkedCall, isNull);
      expect(h.bloc.state.conference.isLeg(c), isTrue);
    });

    test('a call answered while the room is on its way back joins once it is up', () async {
      await _roomUp(h);
      final c = await _add(h, anchorCallId: 'a');
      _setRoomPhase(h, ConferencePhase.rejoining);

      await _answer(h, c);

      expect(h.bloc.state.linkedCall?.awaitingRoom, isTrue);
      expect(h.signaling.requests.whereType<ConferenceAddRequest>(), isEmpty);

      _setRoomPhase(h, ConferencePhase.active);
      await h.settle(() => h.bloc.state.linkedCall == null);

      expect(h.signaling.requests.whereType<ConferenceAddRequest>().map((it) => it.line), [2]);
    });

    test('a failed call leaves the room as it was, and says so', () async {
      await _roomUp(h);
      final heldBefore = h.callkeep.held.length;
      final c = await _add(h, anchorCallId: 'a');

      await _hangUp(h, c, 603);

      expect(h.callkeep.held.skip(heldBefore), isEmpty);
      expect(h.bloc.state.conference.legIds, {'a', 'b'});
      expect(h.notifications.whereType<LinkedCallFailedNotification>().map((it) => it.failure), [
        LinkedCallFailure.declined,
      ]);
    });

    test('the leg it was placed through leaving does not untie it from the room', () async {
      await _roomUp(h);
      final c = await _add(h, anchorCallId: 'a');

      await _hangUp(h, 'a', 200);

      expect(h.bloc.state.conference.isPresent, isTrue);
      expect(h.bloc.state.linkedCall?.callId, c);
    });
  });

  test('a conversation that can no longer take somebody gets no call', () async {
    h.seedEstablishedCall('b', line: 0);
    h.seedEstablishedCall('d', line: 1);
    h.seedEstablishedCall('e', line: 2);

    h.bloc.add(const CallControlEvent.participantCallPlaced(anchorCallId: 'b', number: '200'));
    await h.settle(() => h.notifications.isNotEmpty);

    expect(h.callkeep.startCalls, isEmpty);
    expect(h.callkeep.held, isEmpty);
    expect(h.bloc.state.linkedCall, isNull);
  });

  test('a server that builds no rooms gets no call', () async {
    await h.close();
    h = _harness(conferences: false);
    h.seedEstablishedCall('b', line: 0);

    h.bloc.add(const CallControlEvent.participantCallPlaced(anchorCallId: 'b', number: '200'));
    await h.settle(() => h.notifications.isNotEmpty);

    expect(h.callkeep.startCalls, isEmpty);
    expect(h.bloc.state.linkedCall, isNull);
  });

  test('picking who to call steps the screen aside', () async {
    h.bloc.add(const CallControlEvent.addParticipantInitiated());
    await h.settle(() => h.bloc.state.minimized == true);

    expect(h.bloc.state.minimized, isTrue);
  });
}
