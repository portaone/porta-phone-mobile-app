import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';

import 'call_bloc_harness.dart';

/// After a cold restart the app restores the calls the server still has. A
/// call held on the server comes back held: its microphone is offered
/// inactive, so the restore's re-INVITE does not resume it on the server, and
/// CallKit is told without a hold being sent - the gateway still counts the
/// call on hold and would answer one without sending it. Every call but the
/// last comes back held too: CallKit keeps one live. A resume puts the
/// microphone back.
void main() {
  late CallBlocHarness h;

  setUp(() => h = CallBlocHarness());
  tearDown(() => h.close());

  StateHandshake handshake(List<Line?> lines) => StateHandshake(
    keepaliveInterval: const Duration(seconds: 30),
    timestamp: 0,
    registration: const Registration(status: RegistrationStatus.registered),
    lines: lines,
    presenceInfos: const [],
    dialogInfos: const [],
    guestLine: null,
  );

  /// A line the server reports as accepted; [held] adds a hold after it.
  Line line(int line, String callId, {bool held = false}) => Line(
    callId: callId,
    callLogs: [
      if (held)
        CallEventLog(
          timestamp: 2,
          callEvent: HoldingEvent(line: line, callId: callId),
        ),
      CallEventLog(
        timestamp: 1,
        callEvent: AcceptedEvent(line: line, callId: callId),
      ),
    ],
  );

  FakeRtpTransceiver microphoneOf(FakePeerConnection peer) =>
      peer.fakeTransceivers.firstWhere((t) => t.sender.track?.kind == 'audio');

  Iterable<Request> holdRequests() => h.signaling.requests.where((r) => r is HoldRequest || r is UnholdRequest);

  test('a call held on the server is offered held and nothing more is sent', () async {
    h.signaling.emitHandshake(handshake([line(0, 'b', held: true), line(1, 'c')]));
    await pumpEventQueue();

    expect(h.bloc.state.activeCalls.map((c) => c.callId), containsAll(['b', 'c']));
    final b = h.peerFactory.created.first;
    final c = h.peerFactory.created.last;
    expect(microphoneOf(b).direction, TransceiverDirection.Inactive);
    expect(microphoneOf(c).direction, TransceiverDirection.SendRecv);
    expect(
      b.offerConstraints.last?['mandatory']['OfferToReceiveAudio'],
      isFalse,
      reason: 'asked to receive, libwebrtc would add a second, recvonly audio line',
    );
    expect(c.offerConstraints.last?['mandatory']['OfferToReceiveAudio'], isTrue);
    expect(h.bloc.state.retrieveActiveCall('b')!.held, isTrue);
    expect(h.callkeep.held, contains((callId: 'b', onHold: true)));

    // CallKit performs the hold it was told of: nothing goes to the server.
    await h.bloc.performSetHeld('b', true);
    await pumpEventQueue();
    expect(holdRequests(), isEmpty);
  });

  test('a call live on the server but restored before the last comes back held', () async {
    h.signaling.emitHandshake(handshake([line(0, 'a'), line(1, 'b')]));
    await pumpEventQueue();

    final first = h.peerFactory.created.first;
    final last = h.peerFactory.created.last;
    expect(microphoneOf(first).direction, TransceiverDirection.Inactive);
    expect(microphoneOf(last).direction, TransceiverDirection.SendRecv);
    expect(h.bloc.state.activeCalls.where((c) => c.held), hasLength(1));
  });

  test('a resume of a call restored held sends it and puts the microphone back', () async {
    h.signaling.emitHandshake(handshake([line(0, 'b', held: true), line(1, 'c')]));
    await pumpEventQueue();
    await h.bloc.performSetHeld('b', true);
    await pumpEventQueue();

    await h.bloc.performSetHeld('b', false);
    await pumpEventQueue();
    expect(holdRequests(), isEmpty, reason: 'the microphone first, the unhold once its offer is answered');
    expect(microphoneOf(h.peerFactory.created.first).direction, TransceiverDirection.SendRecv);
    h.signaling.emit(const AcceptedEvent(line: 0, callId: 'b'));
    await pumpEventQueue();

    expect(holdRequests().single, isA<UnholdRequest>());
    expect(h.bloc.state.retrieveActiveCall('b')!.held, isFalse);
    expect(microphoneOf(h.peerFactory.created.first).direction, TransceiverDirection.SendRecv);
  });

  test('once resumed, a call restored held is held again through the server', () async {
    h.signaling.emitHandshake(handshake([line(0, 'b', held: true), line(1, 'c')]));
    await pumpEventQueue();
    await h.bloc.performSetHeld('b', false);
    await pumpEventQueue();
    h.signaling.emit(const AcceptedEvent(line: 0, callId: 'b'));
    await pumpEventQueue();

    await h.bloc.performSetHeld('b', true);
    await pumpEventQueue();

    expect(holdRequests().map((r) => r.runtimeType), [UnholdRequest, HoldRequest]);
    expect(h.bloc.state.retrieveActiveCall('b')!.held, isTrue);
  });

  test('a hold of a call that was not restored held is sent as before', () async {
    h.seedEstablishedCall('a');

    await h.bloc.performSetHeld('a', true);
    await pumpEventQueue();

    expect(holdRequests().single, isA<HoldRequest>());
  });
}
