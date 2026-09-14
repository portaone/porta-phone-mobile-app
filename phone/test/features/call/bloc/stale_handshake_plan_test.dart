import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'call_bloc_harness.dart';

/// The handshake plan is decided before the callkeep reads inside
/// HandshakeProcessor.process() and executed after them; what happened to a
/// call in between must win over the plan. The probes were written by the
/// review of the handshake plan change and are adopted as its coverage.

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

const _oldOffer = {'type': 'offer', 'sdp': 'v=0\r\no=- 1 1 IN IP4 127.0.0.1\r\nm=audio 9 RTP/AVP 0\r\n'};
const _newOffer = {'type': 'offer', 'sdp': 'v=0\r\no=- 1 2 IN IP4 127.0.0.1\r\nm=audio 9 RTP/AVP 0\r\n'};
IncomingCallEvent _incoming(Map<String, String> offer) =>
    IncomingCallEvent(line: 0, callId: 'push-call', caller: '100', callee: '200', jsep: offer);

StateHandshake _snapshot() {
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
  buffer.onEvent(SignalingProtocolEvent(event: _incoming(_oldOffer)));
  return buffer.snapshot.whereType<SignalingHandshakeReceived>().single.handshake;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('a pending handshake plan must not replace an offer received live while reading Callkeep', () async {
    final connections = _Connections();
    final h = CallBlocHarness(callkeepConnections: connections);
    addTearDown(h.close);
    h.bloc.didPushIncomingCall(const CallkeepHandle.number('100'), null, false, 'push-call', null);
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls.single.incomingOffer, isNull);
    h.signaling.emitHandshake(_snapshot());
    await connections.entered.future.timeout(const Duration(seconds: 2));

    h.signaling.emit(_incoming(_newOffer));
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls.single.incomingOffer?.sdp, _newOffer['sdp']);

    connections.release.complete(const []);
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls.single.incomingOffer?.sdp, _newOffer['sdp']);
  });

  test('a pending handshake plan must not revive a push call ended while reading Callkeep', () async {
    final connections = _Connections();
    final h = CallBlocHarness(callkeepConnections: connections);
    addTearDown(h.close);
    h.bloc.didPushIncomingCall(const CallkeepHandle.number('100'), null, false, 'push-call', null);
    await pumpEventQueue();
    h.signaling.emitHandshake(_snapshot());
    await connections.entered.future.timeout(const Duration(seconds: 2));

    // Native end before the offer arrives removes the pre-offer push state.
    unawaited(h.bloc.performEndCall('push-call'));
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls, isEmpty);

    connections.release.complete(const []);
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls, isEmpty);
  });
}
