import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';

import 'call_contract_harness.dart';

/// The contract of the sequential queues: a handler that is still working
/// holds the queue, and the next event does not start until it has finished.
///
/// Every event family in [CallBloc] has its own queue, and the mutation
/// queue is the one all the operations share. What the contract fixes here is
/// the shape of the rule, not the code that implements it: the decomposition
/// that follows may move a handler into its own component, and the queue it
/// runs in is still the queue.
///
/// The order is set by hand - a signaling request is held until the test
/// releases it - so no test waits for real time and no test pumps in a loop
/// hoping the work has run.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallContractHarness h;
  tearDown(() => h.close());

  /// A call that is up and can be held: an incoming call, answered, accepted.
  Future<String> answeredCall() async {
    await h.ringIncomingCall('c1');
    await h.answerIncomingCall('c1');
    await h.acceptIncomingCall('c1');
    return 'c1';
  }

  test('a second hold does not start while the first one is still with the server', () async {
    h = await CallContractHarness.start();
    await answeredCall();

    // The server has not answered the first hold yet.
    final held = HeldWork();
    h.signaling.gate = held.gate;

    h.bloc.add(CallControlEvent.setHeld('c1', true));
    await h.settle(() => h.signaling.requests.whereType<HoldRequest>().isNotEmpty);

    expect(h.signaling.requests.whereType<HoldRequest>(), hasLength(1));
    expect(h.call('c1')?.held, isFalse, reason: 'the server has not taken the hold yet');

    // The second hold is asked for while the first is in flight.
    h.bloc.add(CallControlEvent.setHeld('c1', false));
    await h.pump();

    expect(
      h.signaling.requests.whereType<HoldRequest>(),
      hasLength(1),
      reason: 'the second hold waits behind the first one in the queue',
    );
    expect(h.signaling.requests.whereType<UnholdRequest>(), isEmpty);

    // The server answers the first hold; the queue then runs the second.
    held.release();
    h.signaling.gate = null;
    await h.settle(() => h.signaling.requests.whereType<UnholdRequest>().isNotEmpty);

    expect(h.signaling.requests.whereType<HoldRequest>(), hasLength(1));
    expect(h.signaling.requests.whereType<UnholdRequest>(), hasLength(1));
  });

  test('the holds reach the server in the order they were asked for', () async {
    h = await CallContractHarness.start();
    await answeredCall();

    h.bloc.add(CallControlEvent.setHeld('c1', true));
    await h.settle(() => h.signaling.requests.whereType<HoldRequest>().isNotEmpty);
    h.bloc.add(CallControlEvent.setHeld('c1', false));
    await h.settle(() => h.signaling.requests.whereType<UnholdRequest>().isNotEmpty);

    final order = h.signaling.requests.whereType<Request>().toList();
    expect(order.whereType<HoldRequest>(), hasLength(1));
    expect(order.whereType<UnholdRequest>(), hasLength(1));
    expect(
      order.indexOf(order.whereType<HoldRequest>().single),
      lessThan(order.indexOf(order.whereType<UnholdRequest>().single)),
    );
  });

  test('the hold of one call does not start until the hold of another call has finished', () async {
    // The queue is one for all the calls, not one per call: the races it
    // settles are cross-call as well as same-call.
    h = await CallContractHarness.start(lines: 3);
    await h.ringIncomingCall('c1');
    await h.answerIncomingCall('c1');
    await h.acceptIncomingCall('c1');
    await h.ringIncomingCall('c2', line: 1);
    await h.answerIncomingCall('c2');
    await h.acceptIncomingCall('c2');

    final held = HeldWork();
    h.signaling.gate = held.gate;

    h.bloc.add(CallControlEvent.setHeld('c1', true));
    await h.settle(() => h.signaling.requests.whereType<HoldRequest>().isNotEmpty);
    h.bloc.add(CallControlEvent.setHeld('c2', true));
    await h.pump();

    expect(
      h.signaling.requests.whereType<HoldRequest>(),
      hasLength(1),
      reason: 'the hold of the second call waits for the hold of the first one',
    );

    held.release();
    h.signaling.gate = null;
    await h.settle(() => h.signaling.requests.whereType<HoldRequest>().length == 2);

    expect(h.signaling.requests.whereType<HoldRequest>(), hasLength(2));
  });

  test('a control event does not overtake the mutation that is running', () async {
    // The control handler only queues the work; the work itself is in the
    // mutation queue. So a control event asked for while a mutation runs is
    // not carried out until the mutation has finished - even when it is a
    // control of another kind, on the same call.
    h = await CallContractHarness.start();
    await answeredCall();

    final held = HeldWork();
    h.signaling.gate = held.gate;

    h.bloc.add(CallControlEvent.setHeld('c1', true));
    await h.settle(() => h.signaling.requests.whereType<HoldRequest>().isNotEmpty);

    // The person mutes while the hold is with the server.
    h.bloc.add(CallControlEvent.setMuted('c1', true));
    await h.pump();

    expect(h.callkeep.muted, isEmpty, reason: 'the mute is a mutation too, so it waits behind the hold in the queue');
    expect(h.call('c1')?.held, isFalse, reason: 'the hold has not been taken yet');

    held.release();
    h.signaling.gate = null;
    await h.settle(() => h.callkeep.muted.isNotEmpty);

    expect(h.callkeep.muted, [(callId: 'c1', muted: true)]);
    expect(h.call('c1')?.held, isTrue);
  });
}
