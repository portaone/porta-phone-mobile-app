import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';

import 'call_contract_harness.dart';

/// The contract of the places that deliberately step out of the operation
/// queue.
///
/// The queue holds every operation that touches the call's connection, the
/// platform or the server. A handful of places step out of it on purpose, and
/// each of them has a reason that is worth keeping:
///
///   - the early media of a call is applied to the connection at once, so the
///     network's own voice is heard while the call is still being set up;
///   - the remote's camera state is told to the platform at once, so the
///     incoming-call screen is right before the person answers;
///   - a transfer the server refused takes the call off hold at once, so the
///     person is not left in silence;
///   - the local ringback is decided at once, so the tone cannot start over
///     a conversation that is already connected.
///
/// The contract is that these really are outside the queue: a mutation that is
/// still with the server does not hold them up. The decomposition that follows
/// may move each of them into a component; whether it waits for the queue is
/// the thing that must not change by accident.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallContractHarness h;
  tearDown(() => h.close());

  /// A call that is up, so the bypasses have a call to act on.
  Future<void> callUp({String callId = 'c1'}) async {
    await h.ringIncomingCall(callId);
    await h.answerIncomingCall(callId);
    await h.acceptIncomingCall(callId);
  }

  test('the refused transfer takes the call off hold while the queue is busy', () async {
    h = await CallContractHarness.start();
    await callUp();

    // The queue is busy with a hold the server has not answered.
    final gate = HeldWork();
    h.signaling.gate = gate.gate;

    h.bloc.add(CallControlEvent.setHeld('c1', true));
    await h.settle(() => h.signaling.requests.whereType<HoldRequest>().isNotEmpty);

    // The server refuses the transfer. The call is taken off hold at once,
    // without waiting for the hold to come back.
    h.signaling.emit(TransferFailedEvent(line: 0, callId: 'c1', code: 500));
    await h.settle(() => h.callkeep.held.any((it) => it.onHold == false));

    expect(
      h.callkeep.held.where((it) => it.onHold == false),
      hasLength(1),
      reason: 'the refused transfer takes the call off hold, and does not wait for the queue',
    );

    gate.release();
    h.signaling.gate = null;
    await h.pump();
  });

  test('the remote camera state reaches the platform while the queue is busy', () async {
    h = await CallContractHarness.start();
    await callUp();

    final gate = HeldWork();
    h.signaling.gate = gate.gate;

    h.bloc.add(CallControlEvent.setHeld('c1', true));
    await h.settle(() => h.signaling.requests.whereType<HoldRequest>().isNotEmpty);

    // The remote says its camera is off. The platform is told at once.
    h.signaling.emit(MediaStatePeerMessageEvent(line: 0, callId: 'c1', video: false));
    await h.settle(() => h.call('c1')?.remoteCameraEnabled == false);

    expect(
      h.call('c1')?.remoteCameraEnabled,
      isFalse,
      reason: 'the camera state is applied without waiting for the queue',
    );

    gate.release();
    h.signaling.gate = null;
    await h.pump();
  });

  test('the refused REFER takes the call off hold while the queue is busy', () async {
    h = await CallContractHarness.start();
    await callUp();

    final gate = HeldWork();
    h.signaling.gate = gate.gate;

    h.bloc.add(CallControlEvent.setHeld('c1', true));
    await h.settle(() => h.signaling.requests.whereType<HoldRequest>().isNotEmpty);

    // The server reports that the transfer it was given has failed.
    h.signaling.emit(
      ReferNotifyEvent(
        line: 0,
        callId: 'c1',
        subscriptionState: SubscriptionState.terminated,
        state: const ReferFailed(sipCode: 500, reason: 'refused'),
      ),
    );
    await h.settle(() => h.callkeep.held.any((it) => it.onHold == false));

    expect(
      h.callkeep.held.where((it) => it.onHold == false),
      hasLength(1),
      reason: 'the refused transfer takes the call off hold, and does not wait for the queue',
    );

    gate.release();
    h.signaling.gate = null;
    await h.pump();
  });
}
