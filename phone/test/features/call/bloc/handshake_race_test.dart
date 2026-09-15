import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'call_bloc_harness.dart';

/// A handshake plan is decided from the handshake and executed after the
/// callkeep reads inside HandshakeProcessor.process(), which take seconds on
/// a slow device. A hangup that lands in that window ends the call for good:
/// the plan must not bring it back. Seen on a Xiaomi Redmi against the stand
/// as a ringing screen for a call the caller had already given up on.
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

const _hangup = HangupEvent(line: 0, callId: 'call', code: 487, reason: 'Request Terminated');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a push call hung up while the plan is decided is not presented again', () async {
    // The order seen on the device: the handshake is being planned when the
    // native side replays the ringing connection to the fresh Activity (the
    // placeholder), then the hangup lands. The placeholder is in the state
    // when it does, so callkeep is told the call ended as unanswered and
    // would accept the same call a second time.
    final connections = _Connections();
    final h = CallBlocHarness(callkeepConnections: connections);
    addTearDown(h.close);
    h.signaling.emitHandshake(_ringing(callId: 'call'));
    await connections.entered.future.timeout(const Duration(seconds: 2));
    h.bloc.didPushIncomingCall(const CallkeepHandle.number('100'), null, false, 'call', null);
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls.map((c) => c.callId), ['call']);

    h.signaling.emit(_hangup);
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls, isEmpty, reason: 'the hangup ended the placeholder');
    expect(h.callkeep.ended, ['call']);

    connections.release.complete(const []);
    await pumpEventQueue();

    expect(h.bloc.state.activeCalls, isEmpty, reason: 'the plan must not bring the call back');
    expect(h.callkeep.ended, ['call'], reason: 'nothing was presented and ended a second time');
  });

  test('a ringing call unknown here that hung up while the plan is decided is not presented', () async {
    final connections = _Connections();
    final h = CallBlocHarness(callkeepConnections: connections);
    addTearDown(h.close);
    h.signaling.emitHandshake(_ringing(callId: 'call'));
    await connections.entered.future.timeout(const Duration(seconds: 2));

    h.signaling.emit(_hangup);
    await pumpEventQueue();
    connections.release.complete(const []);
    await pumpEventQueue();

    expect(h.bloc.state.activeCalls, isEmpty);
  });

  test('an accepted call hung up while the plan is decided is not restored', () async {
    final connections = _Connections();
    final h = CallBlocHarness(callkeepConnections: connections);
    addTearDown(h.close);
    h.signaling.emitHandshake(_ringing(callId: 'call', accepted: true));
    await connections.entered.future.timeout(const Duration(seconds: 2));

    h.signaling.emit(const HangupEvent(line: 0, callId: 'call', code: 200, reason: 'OK'));
    await pumpEventQueue();
    connections.release.complete(const []);
    await pumpEventQueue();

    expect(h.bloc.state.activeCalls, isEmpty);
  });

  test('a hangup before the handshake does not shadow the same call in a later handshake', () async {
    // The set is per handshake: a call that ended, then rang again under the
    // same id before the next handshake, is planned as the handshake says.
    final h = CallBlocHarness();
    addTearDown(h.close);
    h.signaling.emit(_hangup);
    await pumpEventQueue();

    h.signaling.emitHandshake(_ringing(callId: 'call'));
    await pumpEventQueue();

    expect(h.bloc.state.activeCalls.map((c) => c.callId), ['call']);
  });
}
