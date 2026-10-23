import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

import 'call_bloc_harness.dart';

/// A call that settled on a codec the room's mixer does not speak is moved
/// onto the conference codecs before it is merged or added: renegotiated with
/// them alone, and the request asked again once it has its answer.
///
/// What a browser-grade WebRTC stack offers: opus, redundancy, G.722 and the
/// G.711 pair, comfort noise and DTMF.
const _webrtcOffer =
    'v=0\r\no=- 0 0 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\n'
    'm=audio 9 UDP/TLS/RTP/SAVPF 111 63 9 0 8 13 110 126\r\nc=IN IP4 0.0.0.0\r\n'
    'a=rtpmap:111 opus/48000/2\r\na=fmtp:111 minptime=10;useinbandfec=1\r\n'
    'a=rtpmap:63 red/48000/2\r\na=fmtp:63 111/111\r\n'
    'a=rtpmap:9 G722/8000\r\na=rtpmap:0 PCMU/8000\r\na=rtpmap:8 PCMA/8000\r\n'
    'a=rtpmap:13 CN/8000\r\na=rtpmap:110 telephone-event/48000\r\na=rtpmap:126 telephone-event/8000\r\n'
    'a=sendrecv\r\n';

/// An answer from the far end that settled on [payload] [codec].
String _answerOn(int payload, String codec) =>
    'v=0\r\no=- 0 0 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\n'
    'm=audio 9 UDP/TLS/RTP/SAVPF $payload 126\r\nc=IN IP4 0.0.0.0\r\n'
    'a=rtpmap:$payload $codec\r\na=rtpmap:126 telephone-event/8000\r\na=sendrecv\r\n';

final _g722 = _answerOn(9, 'G722/8000');
final _pcmu = _answerOn(0, 'PCMU/8000');

String _audioLine(String sdp) => sdp.split('\r\n').firstWhere((line) => line.startsWith('m=audio'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallBlocHarness h;
  setUp(() {
    h = CallBlocHarness(lines: 3, capabilities: CallCapabilitiesConfig(isConferenceEnabled: true));
    h.seedSignalingReady();
  });
  tearDown(() => h.close());

  /// An answered outgoing call on [answer]: the far end's answer is its remote
  /// description.
  FakePeerConnection seedCallOn(String callId, int line, String answer, {bool held = false}) {
    final peer = h.seedEstablishedCall(callId, line: line, held: held, offerSdp: _webrtcOffer);
    peer.remoteDescriptions.add(RTCSessionDescription(answer, 'answer'));
    return peer;
  }

  Future<UpdateRequest> updateOf(String callId) async {
    await h.settle(() => h.signaling.requests.whereType<UpdateRequest>().any((it) => it.callId == callId));
    return h.signaling.requests.whereType<UpdateRequest>().singleWhere((it) => it.callId == callId);
  }

  /// The server's interim ack, then the far end's answer through the
  /// accepted event - the way Core answers a renegotiation.
  Future<void> answer(FakePeerConnection peer, UpdateRequest update, String sdp) async {
    peer.signalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
    h.signaling.emit(UpdatingEvent(transaction: update.transaction, line: update.line!, callId: update.callId));
    await pumpEventQueue();
    h.signaling.emit(AcceptedEvent(line: update.line!, callId: update.callId, jsep: {'type': 'answer', 'sdp': sdp}));
  }

  test('calls on the conference codecs are merged at once', () async {
    seedCallOn('a', 0, _pcmu);
    seedCallOn('b', 1, _answerOn(111, 'opus/48000/2'));

    h.bloc.add(const CallControlEvent.merged(['a', 'b']));
    await h.settle(() => h.signaling.requests.whereType<MergeRequest>().isNotEmpty);

    expect(h.signaling.requests.whereType<UpdateRequest>(), isEmpty);
  });

  test('a call on G.722 is moved onto the conference codecs, then the calls are merged', () async {
    final a = seedCallOn('a', 0, _g722);
    seedCallOn('b', 1, _pcmu);

    h.bloc.add(const CallControlEvent.merged(['a', 'b']));
    final update = await updateOf('a');

    expect(_audioLine(update.jsep['sdp'] as String), 'm=audio 9 UDP/TLS/RTP/SAVPF 111 0 8 13 110 126');
    expect(h.signaling.requests.whereType<MergeRequest>(), isEmpty, reason: 'not before the call has its answer');

    await answer(a, update, _pcmu);
    await h.settle(() => h.signaling.requests.whereType<MergeRequest>().isNotEmpty);

    expect(h.signaling.requests.whereType<MergeRequest>().single.lines, unorderedEquals([0, 1]));
    expect(h.signaling.requests.whereType<UpdateRequest>(), hasLength(1));
    expect(h.notifications, isEmpty);
  });

  test('a held call moved for a merge that is refused is held again', () async {
    // The move offers sendrecv, as the connection does, which takes the call
    // off hold on the far end; the merge would have done so too. With no room
    // after all, the hold is asked for again.
    final a = seedCallOn('a', 0, _g722, held: true);
    seedCallOn('b', 1, _pcmu);

    h.bloc.add(const CallControlEvent.merged(['a', 'b']));
    final update = await updateOf('a');
    h.signaling.failure = const WebtritSignalingErrorException(1, 500, 'conference_already_active');
    await answer(a, update, _pcmu);
    await h.settle(() => h.signaling.requests.whereType<HoldRequest>().isNotEmpty);

    expect(h.signaling.requests.whereType<MergeRequest>(), hasLength(1));
    expect(h.signaling.requests.whereType<HoldRequest>().single.callId, 'a');
    expect(h.bloc.state.retrieveActiveCall('a')!.held, isTrue);
  });

  test('a held call moved and merged is not held again', () async {
    final a = seedCallOn('a', 0, _g722, held: true);
    seedCallOn('b', 1, _pcmu);

    h.bloc.add(const CallControlEvent.merged(['a', 'b']));
    final update = await updateOf('a');
    await answer(a, update, _pcmu);
    await h.settle(() => h.signaling.requests.whereType<MergeRequest>().isNotEmpty);
    await pumpEventQueue();

    expect(h.signaling.requests.whereType<HoldRequest>(), isEmpty);
  });

  test('a far end that turns the conference codecs down keeps its call as it was', () async {
    final a = seedCallOn('a', 0, _g722);
    seedCallOn('b', 1, _pcmu);

    h.bloc.add(const CallControlEvent.merged(['a', 'b']));
    final update = await updateOf('a');
    h.signaling.emit(
      CallErrorEvent(
        transaction: update.transaction,
        line: update.line!,
        callId: 'a',
        code: 488,
        reason: 'Not Acceptable Here',
      ),
    );
    await h.settle(() => h.notifications.isNotEmpty);

    expect(a.localDescriptions.last.type, 'rollback', reason: 'rolled back, not kept to be sent again');
    expect(h.bloc.state.retrieveActiveCall('a')!.updating, isFalse);
    expect(h.signaling.requests.whereType<MergeRequest>(), isEmpty);
    expect(h.notifications.single, isA<ConferenceFailedNotification>());
  });

  test('a call that ends while it is moved takes the merge with it', () async {
    seedCallOn('a', 0, _g722);
    seedCallOn('b', 1, _pcmu);

    h.bloc.add(const CallControlEvent.merged(['a', 'b']));
    final update = await updateOf('a');
    h.signaling.emit(UpdatingEvent(transaction: update.transaction, line: 0, callId: 'a'));
    await pumpEventQueue();
    h.signaling.emit(const HangupEvent(line: 0, callId: 'a', code: 200, reason: 'test'));
    await h.settle(() => h.bloc.state.retrieveActiveCall('a') == null);
    await pumpEventQueue();

    // The merge is asked again and finds one call: nothing to merge, and the
    // person has seen the call end.
    expect(h.signaling.requests.whereType<MergeRequest>(), isEmpty);
    expect(h.notifications, isEmpty);
  });

  test('a call still off the codecs after its move is not merged nor moved again', () async {
    // A far end that answers the restricted offer on G.722 anyway.
    final a = seedCallOn('a', 0, _g722);
    seedCallOn('b', 1, _pcmu);

    h.bloc.add(const CallControlEvent.merged(['a', 'b']));
    final update = await updateOf('a');
    await answer(a, update, _g722);
    await h.settle(() => h.notifications.isNotEmpty);

    expect(h.signaling.requests.whereType<MergeRequest>(), isEmpty);
    expect(h.signaling.requests.whereType<UpdateRequest>(), hasLength(1));
    expect(h.notifications.single, isA<ConferenceFailedNotification>());
  });

  test('a call on G.722 added to a room is moved first, then added', () async {
    seedCallOn('a', 0, _pcmu);
    seedCallOn('b', 1, _pcmu);
    final c = seedCallOn('c', 2, _g722);
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    h.bloc.emit(
      h.bloc.state.copyWith(
        conference: const ConferenceState(room: 7, phase: ConferencePhase.active, legs: {'a': 0, 'b': 1}),
      ),
    );

    h.bloc.add(const CallControlEvent.conferenceAdded('c'));
    final update = await updateOf('c');
    expect(h.signaling.requests.whereType<ConferenceAddRequest>(), isEmpty);

    await answer(c, update, _pcmu);
    await h.settle(() => h.signaling.requests.whereType<ConferenceAddRequest>().isNotEmpty);

    expect(h.signaling.requests.whereType<ConferenceAddRequest>().single.line, 2);
    expect(h.signaling.requests.whereType<UpdateRequest>().map((it) => it.callId), [
      'c',
    ], reason: 'the legs are not touched');
  });

  group('the codecs from the build and the media settings', () {
    Future<void> restart({
      Set<RTPCodec> codecs = EncodingConfig.defaultConferenceAudioCodecs,
      List<Enableble<RTPCodecProfile>>? Function()? profiles,
    }) async {
      await h.close();
      h = CallBlocHarness(
        lines: 3,
        capabilities: CallCapabilitiesConfig(isConferenceEnabled: true),
        conferenceAudioCodecs: codecs,
        conferenceAudioProfiles: profiles,
      );
      h.seedSignalingReady();
    }

    test('the move offers the person\'s codecs in their order', () async {
      await restart(
        profiles: () => [
          (option: RTPCodecProfile.pcma, enabled: true),
          (option: RTPCodecProfile.pcmu, enabled: true),
          (option: RTPCodecProfile.opus, enabled: false),
        ],
      );
      final a = seedCallOn('a', 0, _g722);
      seedCallOn('b', 1, _pcmu);

      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      final update = await updateOf('a');

      expect(_audioLine(update.jsep['sdp'] as String), 'm=audio 9 UDP/TLS/RTP/SAVPF 8 0 13 110 126');

      await answer(a, update, _answerOn(8, 'PCMA/8000'));
      await h.settle(() => h.signaling.requests.whereType<MergeRequest>().isNotEmpty);
    });

    test('a call on a codec the build\'s mixer speaks is merged as it is', () async {
      await restart(codecs: {RTPCodec.g722, RTPCodec.pcmu});
      seedCallOn('a', 0, _g722);
      seedCallOn('b', 1, _pcmu);

      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      await h.settle(() => h.signaling.requests.whereType<MergeRequest>().isNotEmpty);

      expect(h.signaling.requests.whereType<UpdateRequest>(), isEmpty);
    });
  });

  group('review', () {
    test('an Add participant whose anchor is moved keeps its link until the join is made', () async {
      final b = seedCallOn('b', 0, _g722);
      h.bloc.add(const CallControlEvent.participantCallPlaced(anchorCallId: 'b', number: '200'));
      await h.settle(() => h.bloc.state.linkedCall != null);
      final c = h.bloc.state.linkedCall!.callId;
      h.peers.complete(c, FakePeerConnection());
      h.signaling.emit(AcceptedEvent(line: h.bloc.state.retrieveActiveCall(c)!.line!, callId: c));

      final update = await updateOf('b');
      expect(h.bloc.state.linkedCall?.callId, c, reason: 'the join is not made yet');

      await answer(b, update, _pcmu);
      await h.settle(() => h.signaling.requests.whereType<MergeRequest>().isNotEmpty);
      expect(h.bloc.state.linkedCall, isNull);
    });

    test('the anchor is given back when the new call ends while the anchor is moved', () async {
      seedCallOn('b', 0, _g722);
      h.bloc.add(const CallControlEvent.participantCallPlaced(anchorCallId: 'b', number: '200'));
      await h.settle(() => h.bloc.state.linkedCall != null);
      final c = h.bloc.state.linkedCall!.callId;
      h.peers.complete(c, FakePeerConnection());
      final line = h.bloc.state.retrieveActiveCall(c)!.line!;
      h.signaling.emit(AcceptedEvent(line: line, callId: c));
      final update = await updateOf('b');
      h.signaling.emit(UpdatingEvent(transaction: update.transaction, line: 0, callId: 'b'));
      await pumpEventQueue();

      h.signaling.emit(HangupEvent(line: line, callId: c, code: 200, reason: 'test'));
      await h.settle(() => h.bloc.state.linkedCall == null);

      expect(h.callkeep.held.where((it) => it.callId == 'b' && !it.onHold), isNotEmpty, reason: 'b is resumed');
      expect(h.signaling.requests.whereType<MergeRequest>(), isEmpty);
    });

    test('a request asked while calls are moved waits and is asked after them', () async {
      final a = seedCallOn('a', 0, _g722);
      seedCallOn('b', 1, _pcmu);

      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      final update = await updateOf('a');
      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      await pumpEventQueue();
      expect(h.signaling.requests.whereType<UpdateRequest>(), hasLength(1), reason: 'not moved twice');

      await answer(a, update, _pcmu);
      await h.settle(() => h.signaling.requests.whereType<MergeRequest>().isNotEmpty);
      await pumpEventQueue();
      expect(h.signaling.requests.whereType<MergeRequest>(), hasLength(1), reason: 'the second finds the room there');
    });

    test('a merge asked again with too few calls left holds the moved call again and forgets it', () async {
      final a = seedCallOn('a', 0, _g722, held: true);
      seedCallOn('b', 1, _pcmu);
      seedCallOn('c', 2, _pcmu);

      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      final update = await updateOf('a');
      h.signaling.emit(UpdatingEvent(transaction: update.transaction, line: 0, callId: 'a'));
      await pumpEventQueue();
      h.signaling.emit(const HangupEvent(line: 1, callId: 'b', code: 200, reason: 'test'));
      await h.settle(() => h.bloc.state.retrieveActiveCall('b') == null);
      a.signalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
      h.signaling.emit(AcceptedEvent(line: 0, callId: 'a', jsep: {'type': 'answer', 'sdp': _pcmu}));
      await h.settle(() => h.signaling.requests.whereType<HoldRequest>().isNotEmpty);

      expect(h.signaling.requests.whereType<HoldRequest>().single.callId, 'a');
      expect(h.signaling.requests.whereType<MergeRequest>(), isEmpty);
    });

    test('an updated with no answer does not stand for one', () async {
      final a = seedCallOn('a', 0, _g722);
      seedCallOn('b', 1, _pcmu);

      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      final update = await updateOf('a');
      a.signalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
      h.signaling.emit(UpdatedEvent(transaction: update.transaction, line: update.line, callId: 'a'));
      await pumpEventQueue();
      expect(h.signaling.requests.whereType<MergeRequest>(), isEmpty);
      expect(h.notifications, isEmpty);

      h.signaling.emit(AcceptedEvent(line: 0, callId: 'a', jsep: {'type': 'answer', 'sdp': _pcmu}));
      await h.settle(() => h.signaling.requests.whereType<MergeRequest>().isNotEmpty);
    });

    test('an error that is not a refusal is retried with the same offer, not given up', () async {
      final a = seedCallOn('a', 0, _g722);
      seedCallOn('b', 1, _pcmu);

      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      final update = await updateOf('a');
      h.signaling.emit(
        CallErrorEvent(transaction: update.transaction, line: 0, callId: 'a', code: 491, reason: 'Request Pending'),
      );
      await pumpEventQueue();

      expect(a.localDescriptions.where((it) => it.type == 'rollback'), isEmpty);
      expect(h.notifications, isEmpty);
    });

    test('a late error on a call of a move given up rolls its offer back instead of keeping it', () async {
      await h.close();
      void Function()? overdue;
      h = CallBlocHarness(
        lines: 3,
        capabilities: CallCapabilitiesConfig(isConferenceEnabled: true),
        roomCodecMoveTimer: (duration, callback) {
          overdue = callback;
          return Timer(const Duration(days: 1), () {});
        },
      );
      h.seedSignalingReady();
      final a = seedCallOn('a', 0, _g722);
      final b = seedCallOn('b', 1, _g722);

      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      final updateA = await updateOf('a');
      h.signaling.emit(UpdatingEvent(transaction: updateA.transaction, line: 0, callId: 'a'));
      final updateB = await updateOf('b');
      // The answers are overdue while b's offer is out.
      overdue!();
      h.signaling.emit(
        CallErrorEvent(transaction: updateB.transaction, line: 1, callId: 'b', code: 500, reason: 'Server Error'),
      );
      await h.settle(() => b.localDescriptions.any((it) => it.type == 'rollback'));

      expect(b.localDescriptions.last.type, 'rollback', reason: 'not kept to be sent again');
      expect(a.localDescriptions.where((it) => it.type == 'rollback'), isEmpty);
    });

    test('an offer kept from before, with every codec, is withdrawn for the move\'s own', () async {
      final a = seedCallOn('a', 0, _g722);
      seedCallOn('b', 1, _pcmu);
      // A renegotiation whose result was lost keeps its offer to replay.
      h.signaling.failure = TimeoutException('update result was not received');
      h.signaling.emitLifecycle(SignalingConnected());
      await h.settle(() => h.signaling.requests.whereType<UpdateRequest>().length >= 2);
      h.signaling.failure = null;
      a.nativeSignalingStateValue = RTCSignalingState.RTCSignalingStateHaveLocalOffer;
      final before = h.signaling.requests.whereType<UpdateRequest>().length;

      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      await h.settle(() => h.signaling.requests.whereType<UpdateRequest>().length > before);

      final move = h.signaling.requests.whereType<UpdateRequest>().last;
      expect(move.callId, 'a');
      expect(_audioLine(move.jsep['sdp'] as String), 'm=audio 9 UDP/TLS/RTP/SAVPF 111 0 8 13 110 126');
      expect(a.localDescriptions.map((it) => it.type), contains('rollback'));
    });

    test('a refused held call is not held again: it never left hold', () async {
      seedCallOn('a', 0, _g722, held: true);
      seedCallOn('b', 1, _pcmu);

      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      final update = await updateOf('a');
      h.signaling.emit(
        CallErrorEvent(transaction: update.transaction, line: 0, callId: 'a', code: 488, reason: 'Not Acceptable'),
      );
      await h.settle(() => h.notifications.isNotEmpty);
      await pumpEventQueue();

      expect(h.signaling.requests.whereType<HoldRequest>(), isEmpty);
    });
  });
}
