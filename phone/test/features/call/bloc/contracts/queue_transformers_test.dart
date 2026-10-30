import 'package:flutter_test/flutter_test.dart';

import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

import 'call_contract_harness.dart';

/// The contract of the queues that are not sequential: a restartable one and
/// a debounced one.
///
/// What the contract is here is the shape of the rule, not the handler behind
/// it: the decomposition that follows may move a handler into a component of
/// its own, and the queue it runs in stays the queue.
///
/// Not every transformer of the bloc is visible from the outside, and this
/// file says where it is not rather than pretending otherwise: a rule that
/// cannot be seen cannot be kept, and the next step of the decomposition has
/// to know which rules those are.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallContractHarness h;
  tearDown(() => h.close());

  test('the restartable client-event queue lets the newest event win', () async {
    h = await CallContractHarness.start();

    // The client-event queue is restartable: an event that arrives while
    // another one is being handled takes over, and the running one is
    // abandoned.
    //
    // The handler of that queue never waits for anything, so the running one
    // has always finished before the next arrives and there is nothing to
    // abandon: the newest event is the one that counts. The rule is still
    // the rule, and it is what the decomposition has to keep.
    await h.signalingConnected();

    expect(h.bloc.state.callServiceState.signalingClientStatus, SignalingClientStatus.connect);

    await h.signalingDisconnected();

    expect(h.bloc.state.callServiceState.signalingClientStatus, SignalingClientStatus.disconnect);
  });

  test('a burst of client events leaves the state with the last one', () async {
    h = await CallContractHarness.start();

    h.signaling.emitLifecycle(SignalingConnected());
    h.signaling.emitLifecycle(
      SignalingDisconnected(
        code: 1000,
        reason: 'test',
        knownCode: SignalingDisconnectCode.unmappedError,
        recommendedReconnectDelay: Duration.zero,
      ),
    );
    h.signaling.emitLifecycle(SignalingConnected());
    await h.settle(() => h.bloc.state.callServiceState.signalingClientStatus == SignalingClientStatus.connect);

    expect(h.bloc.state.callServiceState.signalingClientStatus, SignalingClientStatus.connect);
  });

  test('the client-event queue keeps the connection the last event reported', () async {
    h = await CallContractHarness.start();

    await h.signalingDisconnected();

    expect(h.bloc.state.callServiceState.signalingClientStatus, SignalingClientStatus.disconnect);

    await h.signalingConnected();

    expect(h.bloc.state.callServiceState.signalingClientStatus, SignalingClientStatus.connect);
    expect(h.bloc.state.callServiceState.lastSignalingClientConnectError, isNull);
  });
}
