import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

import '../bloc/call_bloc_harness.dart';

/// A room does not carry the host's half of a call he takes outside it.
///
/// The microphone is one pooled track lent to every connection, so a call
/// outside the room would otherwise be heard by every participant, and the
/// room's own mix heard over the person the host is talking to. The rule is
/// [CallState.conferenceMustPark]; the connection applies it.
ActiveCall _call(
  String callId, {
  int? line = 0,
  bool accepted = true,
  bool held = false,
  bool leavingRoom = false,
  bool hungUp = false,
  CallProcessingStatus status = CallProcessingStatus.connected,
}) => ActiveCall(
  direction: CallDirection.outgoing,
  line: line,
  callId: callId,
  handle: CallkeepHandle.number('100'),
  createdTime: DateTime(2026),
  video: false,
  held: held,
  leavingRoom: leavingRoom,
  processingStatus: status,
  acceptedTime: accepted ? DateTime(2026) : null,
  hungUpTime: hungUp ? DateTime(2026) : null,
);

CallState _state(List<ActiveCall> calls, {Map<String, int> legs = const {}}) => CallState(
  activeCalls: calls,
  conference: legs.isEmpty
      ? const ConferenceState()
      : ConferenceState(phase: ConferencePhase.active, room: 1, legs: legs),
);

ConferenceParticipant _participant(String callId, int line) => ConferenceParticipant(line: line, callId: callId);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the rule', () {
    test('an accepted call outside the room makes the room stand aside', () {
      final state = _state([_call('a', line: 0), _call('b', line: 1), _call('c', line: 2)], legs: {'a': 0, 'b': 1});

      expect(state.conferenceMustPark, isTrue);
    });

    test('the legs themselves never make it stand aside', () {
      final state = _state([_call('a', line: 0), _call('b', line: 1)], legs: {'a': 0, 'b': 1});

      expect(state.conferenceMustPark, isFalse);
    });

    test('a ringing call does not, there being nobody on it yet', () {
      final state = _state(
        [
          _call('a', line: 0),
          _call('b', line: 1),
          _call('c', line: 2, accepted: false, status: CallProcessingStatus.incomingFromOffer),
        ],
        legs: {'a': 0, 'b': 1},
      );

      expect(state.conferenceMustPark, isFalse, reason: 'an incoming call the host may decline must not cut the room');
    });

    test('a call on its way out does not hold the room aside', () {
      final hungUp = _state(
        [_call('a', line: 0), _call('b', line: 1), _call('c', line: 2, hungUp: true)],
        legs: {'a': 0, 'b': 1},
      );
      final disconnecting = _state(
        [_call('a', line: 0), _call('b', line: 1), _call('c', line: 2, status: CallProcessingStatus.disconnecting)],
        legs: {'a': 0, 'b': 1},
      );

      expect(hungUp.conferenceMustPark, isFalse);
      expect(disconnecting.conferenceMustPark, isFalse);
    });

    test('a held call outside the room gives the room back', () {
      final state = _state(
        [_call('a', line: 0), _call('b', line: 1), _call('c', line: 2, held: true)],
        legs: {'a': 0, 'b': 1},
      );

      expect(state.conferenceMustPark, isFalse, reason: 'the server stops a held call\'s media; the host is back');
    });

    test('a leg the room dropped is not a call taken outside it', () {
      // The server takes a participant out of the room and this client still
      // holds their call. It is on its way to being an ordinary held call; read
      // as a call the host went off to, it would make the room stand aside and
      // silence the conference for everyone still in it.
      final state = _state([_call('a', line: 0), _call('b', line: 1, held: true)], legs: {'a': 0});

      expect(state.conferenceMustPark, isFalse);
    });

    test('a call the room released is not yet a call the host went off to', () {
      final leaving = _state([_call('a', line: 0), _call('b', line: 1, leavingRoom: true)], legs: {'a': 0});
      // The hold was refused, so it is an ordinary live call after all.
      final refused = _state([_call('a', line: 0), _call('b', line: 1)], legs: {'a': 0});

      expect(leaving.conferenceMustPark, isFalse);
      expect(refused.conferenceMustPark, isTrue);
    });

    test('without a room there is nothing to stand aside', () {
      expect(_state([_call('c', line: 0)]).conferenceMustPark, isFalse);
    });
  });

  group('the wiring', () {
    test('a hold the server refuses leaves the released call live, not falsely held', () async {
      // `held` means a hold the server took. Claiming one it refused would show
      // the user a call on hold that is in fact live - and the room, seeing a
      // held call, would carry his microphone into it.
      final h = CallBlocHarness(capabilities: const CallCapabilitiesConfig(isConferenceEnabled: true));
      addTearDown(h.close);
      h.seedEstablishedCall('a', line: 0);
      h.seedEstablishedCall('b', line: 1);
      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      await pumpEventQueue();
      h.signaling.emit(
        ConferenceOfferEvent(
          room: 7,
          jsep: const {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'},
          participants: [_participant('a', 0), _participant('b', 1)],
        ),
      );
      await pumpEventQueue();
      final mixer = h.peerFactory.created.single;

      h.signaling.emit(ConferenceUpdatedEvent(room: 7, participants: [_participant('a', 0)]));
      await _settle(() => h.bloc.state.conference.legs.length == 1);

      final released = h.bloc.state.retrieveActiveCall('b')!;
      expect(released.held, isFalse, reason: 'the server has not taken a hold yet');
      expect(released.leavingRoom, isTrue);
      expect(mixer.fakeSenders.single.track, isNotNull, reason: 'and the room is not aside for it meanwhile');

      // The platform asks for the hold and the server refuses it.
      h.signaling.failure = const WebtritSignalingErrorException(1, 500, 'Server Internal Error');
      await h.bloc.performSetHeld('b', true);
      await _settle(() => h.bloc.state.retrieveActiveCall('b')?.leavingRoom == false);

      final after = h.bloc.state.retrieveActiveCall('b')!;
      expect(after.held, isFalse, reason: 'a refused hold is a hold that did not happen');
      expect(after.leavingRoom, isFalse, reason: 'and it is settled: an ordinary live call outside the room');
      await _settle(() => mixer.fakeSenders.single.track == null);
      expect(mixer.fakeSenders.single.track, isNull, reason: 'so the room does stand aside for it after all');
    });

    test('the room can still be ended while its offer is being answered', () async {
      // The mixer's connection serialises its own work, so a park asked for
      // while the room is still being answered queues behind that answer.
      // Awaited, it would hold the mutation queue - and the room's own End and
      // its assembly deadline sit in that queue.
      final gate = Completer<void>();
      final h = CallBlocHarness(capabilities: const CallCapabilitiesConfig(isConferenceEnabled: true));
      final gated = _GatedMedia(h.media, gate);
      final gatedHarness = CallBlocHarness(
        capabilities: const CallCapabilitiesConfig(isConferenceEnabled: true),
        userMediaBuilder: gated,
      );
      await h.close();
      addTearDown(() async {
        if (!gate.isCompleted) gate.complete();
        await gatedHarness.close();
      });
      gatedHarness.seedEstablishedCall('a', line: 0);
      gatedHarness.seedEstablishedCall('b', line: 1);
      gatedHarness.bloc.add(const CallControlEvent.merged(['a', 'b']));
      await pumpEventQueue();
      gatedHarness.signaling.emit(
        ConferenceOfferEvent(
          room: 7,
          jsep: const {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'},
          participants: [_participant('a', 0), _participant('b', 1)],
        ),
      );
      await pumpEventQueue();
      expect(gated.pending, isTrue, reason: 'the room is still opening its connection');

      // A call outside the room: the park is planned and queued.
      gatedHarness.seedEstablishedCall('c', line: 2, number: '300');
      await pumpEventQueue();

      gatedHarness.bloc.add(const CallControlEvent.conferenceEnded());
      await _settle(() => gatedHarness.signaling.requests.whereType<ConferenceHangupRequest>().isNotEmpty);

      expect(
        gatedHarness.signaling.requests.whereType<ConferenceHangupRequest>(),
        isNotEmpty,
        reason: 'End reached the server without waiting for the answer',
      );
    });

    test('a participant leaving does not make the room stand aside', () async {
      final h = CallBlocHarness(capabilities: const CallCapabilitiesConfig(isConferenceEnabled: true));
      addTearDown(h.close);
      h.seedEstablishedCall('a', line: 0);
      h.seedEstablishedCall('b', line: 1);
      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      await pumpEventQueue();
      h.signaling.emit(
        ConferenceOfferEvent(
          room: 7,
          jsep: const {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'},
          participants: [_participant('a', 0), _participant('b', 1)],
        ),
      );
      await pumpEventQueue();
      final mixer = h.peerFactory.created.single;

      // The server drops one participant; their call is still up here, and the
      // hold that turns it back into an ordinary call is a round trip away.
      h.signaling.emit(ConferenceUpdatedEvent(room: 7, participants: [_participant('a', 0)]));
      await _settle(() => h.bloc.state.conference.legs.length == 1);
      for (var turn = 0; turn < 10; turn++) {
        await pumpEventQueue();
      }

      expect(h.bloc.state.conferenceMustPark, isFalse);
      expect(mixer.fakeSenders.single.track, isNotNull, reason: 'the room still carries the host');
      expect(
        mixer.fakeTransceivers.single.receiver.track!.enabled,
        isTrue,
        reason: 'and he still hears the participants who stayed',
      );
    });

    test('a call taken outside a live room parks it, and ending that call brings the room back', () async {
      final h = CallBlocHarness(capabilities: const CallCapabilitiesConfig(isConferenceEnabled: true));
      addTearDown(h.close);
      h.seedEstablishedCall('a', line: 0);
      h.seedEstablishedCall('b', line: 1);
      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      await pumpEventQueue();
      h.signaling.emit(
        ConferenceOfferEvent(
          room: 7,
          jsep: const {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'},
          participants: [_participant('a', 0), _participant('b', 1)],
        ),
      );
      await pumpEventQueue();

      final mixer = h.peerFactory.created.single;
      expect(mixer.fakeSenders.single.track, h.media.microphone, reason: 'the host is in the room');
      expect(mixer.fakeTransceivers.single.receiver.track!.enabled, isTrue);

      h.seedEstablishedCall('c', line: 2, number: '300');
      await _settle(() => mixer.fakeSenders.single.track == null);

      expect(h.bloc.state.conferenceMustPark, isTrue);
      expect(mixer.fakeSenders.single.track, isNull, reason: 'the room no longer hears the host');
      expect(mixer.fakeTransceivers.single.receiver.track!.enabled, isFalse, reason: 'nor he it');
      expect(h.media.microphone.enabled, isTrue, reason: 'the outside call still carries his voice');

      h.signaling.emit(const HangupEvent(line: 2, callId: 'c', code: 200, reason: 'Normal Clearing'));
      await _settle(() => mixer.fakeSenders.single.track != null);

      expect(h.bloc.state.retrieveActiveCall('c'), isNull);
      expect(mixer.fakeSenders.single.track, h.media.microphone, reason: 'the host is back in the room');
      expect(mixer.fakeTransceivers.single.receiver.track!.enabled, isTrue);
    });

    test('a mute the host set before the outside call outlives it', () async {
      final h = CallBlocHarness(capabilities: const CallCapabilitiesConfig(isConferenceEnabled: true));
      addTearDown(h.close);
      h.seedEstablishedCall('a', line: 0);
      h.seedEstablishedCall('b', line: 1);
      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      await pumpEventQueue();
      h.signaling.emit(
        ConferenceOfferEvent(
          room: 7,
          jsep: const {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'},
          participants: [_participant('a', 0), _participant('b', 1)],
        ),
      );
      await pumpEventQueue();
      final mixer = h.peerFactory.created.single;

      h.bloc.add(const CallControlEvent.conferenceSelfMuted(true));
      await pumpEventQueue();
      expect(mixer.fakeSenders.single.track, isNull);

      h.seedEstablishedCall('c', line: 2, number: '300');
      await _settle(() => !mixer.fakeTransceivers.single.receiver.track!.enabled);
      // Stated rather than only waited for: a mute alone would keep the sender
      // empty, so without this the test would pass on a room that never parked.
      expect(
        mixer.fakeTransceivers.single.receiver.track!.enabled,
        isFalse,
        reason: 'the room did stand aside, mute or no mute',
      );

      h.signaling.emit(const HangupEvent(line: 2, callId: 'c', code: 200, reason: 'Normal Clearing'));
      await _settle(() => h.bloc.state.retrieveActiveCall('c') == null);

      expect(mixer.fakeSenders.single.track, isNull, reason: 'unparking must not undo a mute nobody asked to lift');
      expect(mixer.fakeTransceivers.single.receiver.track!.enabled, isTrue, reason: 'a muted host still hears');
      expect(h.bloc.state.conference.selfMuted, isTrue);
    });
  });
}

/// Pumps until [done], or gives up after enough turns for anything the bloc
/// queues in response to one change.
Future<void> _settle(bool Function() done) async {
  for (var turn = 0; turn < 50 && !done(); turn++) {
    await pumpEventQueue();
  }
}

/// Holds the room's microphone request open, so a park can be asked for while
/// the room is still answering the mixer.
class _GatedMedia extends Fake implements UserMediaBuilder {
  _GatedMedia(this._inner, this._gate);

  final FakeUserMediaBuilder _inner;
  final Completer<void> _gate;

  bool pending = false;

  @override
  Future<MediaStream> build({required bool video, bool? frontCamera, bool allowAudioFallback = false}) async {
    pending = true;
    await _gate.future;
    pending = false;
    return _inner.build(video: video, frontCamera: frontCamera, allowAudioFallback: allowAudioFallback);
  }

  @override
  Future<void> release(MediaStream stream) => _inner.release(stream);
}
