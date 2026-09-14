import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'call_bloc_harness.dart';

/// A termination the user asked for is an intent kept until the server
/// confirms it. A decline recorded before the offer arrived is sent by the
/// next handshake with the line it shows, and a further handshake before the
/// server's hangup - or after a send that never reached it - must still hold
/// the call back and send the decline again. The probes were written by the
/// review of the handshake race change and are adopted as its coverage.
class _Connections extends Fake implements CallkeepConnections {
  final entered = Completer<void>();
  final release = Completer<List<CallkeepConnection>>();

  @override
  Future<List<CallkeepConnection>> getConnections() {
    if (!entered.isCompleted) entered.complete();
    return release.future;
  }

  @override
  Future<CallkeepConnection?> getConnection(String callId) async => null;
}

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
  for (final offline in [false, true]) {
    test('a pre-offer decline survives another handshake until hangup (offline=$offline)', () async {
      final connections = _Connections();
      final h = CallBlocHarness(callkeepConnections: connections);
      addTearDown(h.close);
      h.bloc.didPushIncomingCall(const CallkeepHandle.number('100'), null, false, 'call', null);
      await pumpEventQueue();
      h.signaling.emitHandshake(_ringing(callId: 'call'));
      await connections.entered.future.timeout(const Duration(seconds: 2));

      unawaited(h.bloc.performEndCall('call'));
      await pumpEventQueue();
      expect(h.bloc.state.activeCalls, isEmpty);
      expect(h.terminationQueue.requests['call']?.line, isNull);
      expect(h.terminationQueue.requests, hasLength(1));

      if (offline) h.signaling.failure = NotConnectedException('transport dropped during native read');
      connections.release.complete(const []);
      await pumpEventQueue();
      expect(h.bloc.state.activeCalls, isEmpty, reason: 'first plan suppresses the declined call');
      expect(h.signaling.requests.whereType<DeclineRequest>(), hasLength(1));
      expect(h.signaling.requests.whereType<DeclineRequest>().single.line, 0);

      // No server HangupEvent has confirmed the intent. The next reconnect
      // still reports the same ringing call, whether the prior request was
      // acknowledged but not completed, or failed to reach the server.
      h.signaling.failure = null;
      h.signaling.emitHandshake(_ringing(callId: 'call'));
      await pumpEventQueue();
      expect(h.bloc.state.activeCalls, isEmpty, reason: 'a consumed replay must not forget the native decline');
      expect(h.signaling.requests.whereType<DeclineRequest>(), hasLength(2));
    });
  }
}
