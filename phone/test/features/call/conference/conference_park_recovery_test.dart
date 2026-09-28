import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

import '../bloc/call_bloc_harness.dart';

const _offer = {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'};

Future<void> _merge(CallBlocHarness h) async {
  h.bloc.add(const CallControlEvent.merged(['a', 'b']));
  await pumpEventQueue();
  h.signaling.emit(
    const ConferenceOfferEvent(
      room: 7,
      jsep: _offer,
      participants: [
        ConferenceParticipant(line: 0, callId: 'a'),
        ConferenceParticipant(line: 1, callId: 'b'),
      ],
    ),
  );
  await pumpEventQueue();
  expect(h.bloc.state.conference.phase, ConferencePhase.active);
}

void _expectQuiet(CallBlocHarness h, FakePeerConnection peer, String callId) {
  expect(peer.fakeSenders.single.track, isNull, reason: '$callId must not receive the private microphone');
  expect(h.bloc.state.retrieveActiveCall(callId)!.remoteStream!.getAudioTracks().single.enabled, isFalse);
}

Future<void> _confirmHolds(CallBlocHarness h) async {
  // FakeCallkeep records requests but does not deliver their native callbacks.
  for (final request in List.of(h.callkeep.held)) {
    await h.bloc.performSetHeld(request.callId, request.onHold);
  }
  await pumpEventQueue();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallBlocHarness h;
  late _FaultFactory factory;
  late FakePeerConnection a;
  late FakePeerConnection b;

  setUp(() async {
    factory = _FaultFactory();
    h = CallBlocHarness(
      peerConnectionFactory: factory,
      capabilities: const CallCapabilitiesConfig(isConferenceEnabled: true),
    );
    a = h.seedEstablishedCall('a', line: 0);
    b = h.seedEstablishedCall('b', line: 1);
    await _merge(h);
  });

  tearDown(() async => h.close());

  test('failed parking keeps every former leg quiet before and after hold confirmation', () async {
    factory.mixer.failuresRemaining = 2;
    final outside = h.seedEstablishedCall('c', line: 2);
    await pumpEventQueue();

    expect(h.bloc.state.conference.isPresent, isFalse);
    expect(factory.mixer.closes, 1);
    _expectQuiet(h, a, 'a');
    _expectQuiet(h, b, 'b');
    expect(h.callkeep.held, [(callId: 'a', onHold: true), (callId: 'b', onHold: true)]);

    await _confirmHolds(h);

    expect(h.bloc.state.retrieveActiveCall('a')!.held, isTrue);
    expect(h.bloc.state.retrieveActiveCall('b')!.held, isTrue);
    _expectQuiet(h, a, 'a');
    _expectQuiet(h, b, 'b');
    expect(h.bloc.state.retrieveActiveCall('c')!.held, isFalse);
    expect(outside.fakeSenders.single.track, h.media.microphone);
    expect(h.media.microphone.enabled, isTrue);
  });

  test('refused holds and mute callbacks cannot undo isolation; a later resume restores audio', () async {
    factory.mixer.failuresRemaining = 2;
    h.seedEstablishedCall('c', line: 2);
    await pumpEventQueue();
    h.signaling.failure = const WebtritSignalingErrorException(1, 500, 'hold refused');

    await _confirmHolds(h);
    await h.bloc.performSetMuted('a', false);
    await pumpEventQueue();

    expect(h.bloc.state.retrieveActiveCall('a')!.held, isFalse);
    _expectQuiet(h, a, 'a');
    _expectQuiet(h, b, 'b');

    h.signaling.failure = null;
    await _confirmHolds(h);
    await h.bloc.performSetHeld('c', true);
    await h.bloc.performSetHeld('a', false);
    await pumpEventQueue();

    expect(h.bloc.state.retrieveActiveCall('a')!.held, isFalse);
    expect(a.fakeSenders.single.track, h.media.microphone);
    expect(h.bloc.state.retrieveActiveCall('a')!.remoteStream!.getAudioTracks().single.enabled, isTrue);
    _expectQuiet(h, b, 'b');
  });

  test('failed unparking restores a survivor when the outside call is held', () async {
    h.seedEstablishedCall('c', line: 2);
    await pumpEventQueue();
    factory.mixer.failuresRemaining = 2;
    await h.bloc.performSetHeld('c', true);
    await pumpEventQueue();

    expect(h.bloc.state.conference.isPresent, isFalse);
    expect(factory.mixer.closes, 1);
    expect(a.fakeSenders.single.track, h.media.microphone);
    expect(h.callkeep.held, [(callId: 'a', onHold: false), (callId: 'b', onHold: true)]);
  });

  test('an unsent resume cannot release a former leg', () async {
    factory.mixer.failuresRemaining = 2;
    h.seedEstablishedCall('c', line: 2);
    await pumpEventQueue();
    await _confirmHolds(h);

    h.signaling.sendable = false;
    await h.bloc.performSetHeld('a', false);
    await pumpEventQueue();

    expect(h.bloc.state.retrieveActiveCall('a')!.held, isTrue);
    _expectQuiet(h, a, 'a');
  });

  test('resuming a former leg preserves its own mute intent', () async {
    factory.mixer.failuresRemaining = 2;
    h.seedEstablishedCall('c', line: 2);
    await pumpEventQueue();
    await _confirmHolds(h);
    await h.bloc.performSetMuted('a', true);
    await h.bloc.performSetHeld('c', true);
    await h.bloc.performSetHeld('a', false);
    await pumpEventQueue();

    expect(h.bloc.state.retrieveActiveCall('a')!.muted, isTrue);
    expect(a.fakeSenders.single.track, isNull);
    expect(h.bloc.state.retrieveActiveCall('a')!.remoteStream!.getAudioTracks().single.enabled, isTrue);
  });

  test('a superseded final park failure cannot end the room', () async {
    final secondAttempt = Completer<void>();
    factory.mixer.failuresRemaining = 2;
    factory.mixer.lastFailureGate = secondAttempt;
    h.seedEstablishedCall('c', line: 2);
    await pumpEventQueue();
    expect(factory.mixer.failuresRemaining, 0, reason: 'the second attempt is waiting');

    await h.bloc.performSetHeld('c', true);
    await pumpEventQueue();
    expect(h.bloc.state.conferenceMustPark, isFalse);
    secondAttempt.complete();
    await pumpEventQueue();

    expect(h.bloc.state.conference.phase, ConferencePhase.active);
    expect(factory.mixer.closes, 0);
    expect(factory.mixer.fakeSenders.single.track, h.media.microphone);
    expect(factory.mixer.fakeTransceivers.single.receiver.track!.enabled, isTrue);
    expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), isEmpty);
  });

  test('joining another room releases the former-leg audio barrier', () async {
    factory.mixer.failuresRemaining = 2;
    h.seedEstablishedCall('c', line: 2);
    await pumpEventQueue();
    await _confirmHolds(h);
    await h.bloc.performSetHeld('c', true);
    await pumpEventQueue();

    await _merge(h);
    h.signaling.emit(const ConferenceTerminatedEvent(room: 7));
    await pumpEventQueue();

    expect(h.bloc.state.conference.isPresent, isFalse);
    expect(a.fakeSenders.single.track, h.media.microphone);
    expect(b.fakeSenders.single.track, h.media.microphone);
  });
}

class _FaultFactory extends FakePeerConnectionFactory {
  _FaultPeer get mixer => created.last as _FaultPeer;

  @override
  Future<RTCPeerConnection> create([
    Map<String, dynamic> configuration = const {},
    Map<String, dynamic> constraints = const {},
  ]) async {
    final peer = _FaultPeer();
    created.add(peer);
    return peer;
  }
}

class _FaultPeer extends FakePeerConnection {
  int failuresRemaining = 0;
  Completer<void>? lastFailureGate;

  @override
  Future<List<RTCRtpTransceiver>> getTransceivers() async {
    if (failuresRemaining > 0) {
      failuresRemaining--;
      if (failuresRemaining == 0) await lastFailureGate?.future;
      throw StateError('injected audio lookup failure');
    }
    return super.getTransceivers();
  }
}
