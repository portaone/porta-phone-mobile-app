import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';

import 'package:webtrit_phone/models/models.dart';

import 'call_bloc_harness.dart';

/// A hangup or decline the user made while the request could not be sent is
/// queued and replayed by the next handshake. One the server refused is not:
/// it would be refused again, and a replayed refusal used to stop the whole
/// handshake plan, leaving a live call unanswered. Seen on a Xiaomi Redmi
/// against the stand right after a phantom call had been declined with 410.
const _offer = {'type': 'offer', 'sdp': 'v=0\r\no=- 1 1 IN IP4 127.0.0.1\r\nm=audio 9 RTP/AVP 0\r\n'};

StateHandshake _ringing(String callId, {String? alsoRinging}) {
  final buffer = SignalingEventBuffer();
  buffer.onEvent(
    SignalingHandshakeReceived(
      handshake: const StateHandshake(
        keepaliveInterval: Duration(seconds: 30),
        timestamp: 1,
        registration: Registration(status: RegistrationStatus.registered),
        lines: [null, null],
        presenceInfos: [],
        dialogInfos: [],
        guestLine: null,
      ),
    ),
  );
  buffer.onEvent(
    SignalingProtocolEvent(
      event: IncomingCallEvent(line: 0, callId: callId, caller: '100', callee: '200', jsep: _offer),
    ),
  );
  if (alsoRinging != null) {
    buffer.onEvent(
      SignalingProtocolEvent(
        event: IncomingCallEvent(line: 1, callId: alsoRinging, caller: '101', callee: '200', jsep: _offer),
      ),
    );
  }
  return buffer.snapshot.whereType<SignalingHandshakeReceived>().single.handshake;
}

const _callGone = WebtritSignalingErrorException(1, 410, 'Call gone while taking action');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a decline the server refused is not queued for retry', () async {
    final h = CallBlocHarness();
    addTearDown(h.close);
    h.signaling.emitHandshake(_ringing('call'));
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls.map((c) => c.callId), ['call']);

    h.signaling.failure = _callGone;
    await h.bloc.performEndCall('call');
    await pumpEventQueue();

    expect(h.signaling.requests.whereType<DeclineRequest>(), hasLength(1));
    expect(h.terminationQueue.requests, isEmpty, reason: 'the server answered; there is nothing to retry');
  });

  test('a decline that did not reach the server stays queued', () async {
    final h = CallBlocHarness();
    addTearDown(h.close);
    h.signaling.emitHandshake(_ringing('call'));
    await pumpEventQueue();

    h.signaling.failure = NotConnectedException('down');
    await h.bloc.performEndCall('call');
    await pumpEventQueue();

    expect(h.terminationQueue.requests.keys, ['call']);
  });

  test('a queued decline the server refuses does not stop the plan for a live call', () async {
    final h = CallBlocHarness();
    addTearDown(h.close);
    h.terminationQueue.requests['dead'] = const QueuedTerminationRequest(
      type: QueuedTerminationRequestType.decline,
      callId: 'dead',
      line: 0,
    );
    h.signaling.failure = _callGone;

    // The session still shows the declined call, so the decline is replayed
    // - and refused - ahead of a live call on the other line.
    h.signaling.emitHandshake(_ringing('dead', alsoRinging: 'live'));
    await pumpEventQueue();

    expect(h.signaling.requests.whereType<DeclineRequest>().map((r) => r.callId), ['dead']);
    expect(h.bloc.state.activeCalls.map((c) => c.callId), ['live'], reason: 'the live call is presented');
    expect(h.terminationQueue.requests, isEmpty, reason: 'the replayed entry is consumed');
  });
}
