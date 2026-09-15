import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';

import 'call_bloc_harness.dart';

/// A termination the server acknowledged stays recorded until its hangup
/// confirms it. When that hangup is missed over a reconnect and the next
/// session no longer carries the call, the record is dropped rather than sent
/// again to a call id the server has forgotten. The probes were written by
/// the review of the handshake race change and are adopted as its coverage.
const _offer = {'type': 'offer', 'sdp': 'v=0\r\no=- 1 1 IN IP4 127.0.0.1\r\nm=audio 9 RTP/AVP 0\r\n'};

StateHandshake _ringing({required String callId, bool accepted = false}) {
  final buffer = SignalingEventBuffer();
  buffer.onEvent(
    SignalingHandshakeReceived(
      handshake: const StateHandshake(
        keepaliveInterval: Duration(seconds: 30),
        timestamp: 1,
        registration: Registration(status: RegistrationStatus.registered),
        lines: [null],
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
  if (accepted) buffer.onEvent(SignalingProtocolEvent(event: AcceptedEvent(line: 0, callId: callId)));
  return buffer.snapshot.whereType<SignalingHandshakeReceived>().single.handshake;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final established in [false, true]) {
    test('an acknowledged termination is not replayed for an empty session (established=$established)', () async {
      final h = CallBlocHarness();
      addTearDown(h.close);
      if (established) h.seedEstablishedCall('call');
      h.signaling.emitHandshake(_ringing(callId: 'call'));
      await pumpEventQueue();
      await h.bloc.performEndCall('call');
      await pumpEventQueue();
      expect(h.bloc.state.activeCalls, isEmpty);
      final initial = h.signaling.requests.where((r) => r is DeclineRequest || r is HangupRequest).toList();
      expect(initial, hasLength(1));
      expect(initial.single, established ? isA<HangupRequest>() : isA<DeclineRequest>());

      // The ack reached the client, but the final HangupEvent was missed
      // during a reconnect. The fresh server handshake confirms no call.
      h.signaling.emitHandshake(
        const StateHandshake(
          keepaliveInterval: Duration(seconds: 30),
          timestamp: 2,
          registration: Registration(status: RegistrationStatus.registered),
          lines: [null],
          presenceInfos: [],
          dialogInfos: [],
          guestLine: null,
        ),
      );
      await pumpEventQueue();
      expect(
        h.signaling.requests.where((r) => r is DeclineRequest || r is HangupRequest),
        hasLength(1),
        reason: 'the server has confirmed that call is gone; do not address a stale call id',
      );
      expect(h.terminationQueue.requests, isEmpty);
    });
  }
}
