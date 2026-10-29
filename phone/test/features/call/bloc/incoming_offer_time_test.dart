import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';

import 'call_bloc_harness.dart';

/// A blind transfer repeated after the target declined offers the same call id again, and callkeep
/// refuses an id the app ended before presenting it unless the call was offered after that end.
/// The bloc says when: an incoming the socket delivers is offered now; one a handshake lists is a
/// replay of the server's lines, with no time.
const _offer = {'type': 'offer', 'sdp': 'v=0\r\no=- 1 1 IN IP4 127.0.0.1\r\nm=audio 9 RTP/AVP 0\r\n'};
const _incoming = IncomingCallEvent(line: 0, callId: 'call', caller: '100', callee: '200', jsep: _offer);

StateHandshake _ringing() {
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
  buffer.onEvent(SignalingProtocolEvent(event: _incoming));
  return buffer.snapshot.whereType<SignalingHandshakeReceived>().single.handshake;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an incoming the socket delivers is reported as offered when it arrived', () async {
    final h = CallBlocHarness();
    addTearDown(h.close);
    final before = DateTime.now();

    h.signaling.emit(_incoming);
    await pumpEventQueue();

    final (callId, offeredAt) = h.callkeep.incomingReports.single;
    expect(callId, 'call');
    expect(offeredAt, isNotNull);
    expect(offeredAt!.isBefore(before), isFalse);
  });

  test('an incoming a handshake replays is reported with no offer time', () async {
    final h = CallBlocHarness();
    addTearDown(h.close);

    h.signaling.emitHandshake(_ringing());
    await pumpEventQueue();

    expect(h.callkeep.incomingReports, [('call', null)]);
  });
}
