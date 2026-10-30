import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';

import 'call_contract_harness.dart';

/// The contract of the one queue the operations share.
///
/// Every operation that touches the call's connection, the platform or the
/// server goes through the same queue, for every call. That is the point of
/// it: the races it settles are cross-call as well as same-call, and a queue
/// per call would leave the two calls of a conversation free to work on the
/// same connection at the same time.
///
/// The contract here is that the queue is one. An operation of one kind
/// waits for an operation of another kind, and the order they run in is the
/// order they were asked for.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallContractHarness h;
  tearDown(() => h.close());

  /// A call that is up, so there is something to hold, mute and end.
  Future<void> callUp({String callId = 'c1'}) async {
    await h.ringIncomingCall(callId);
    await h.answerIncomingCall(callId);
    await h.acceptIncomingCall(callId);
  }

  test('a hold waits for the DTMF that was asked for before it', () async {
    h = await CallContractHarness.start();
    await callUp();

    // The DTMF goes to the platform, the hold to the server: two different
    // operations, one queue.
    final gate = HeldWork();
    h.signaling.gate = gate.gate;

    h.bloc.add(CallControlEvent.setHeld('c1', true));
    await h.settle(() => h.signaling.requests.whereType<HoldRequest>().isNotEmpty);

    h.bloc.add(CallControlEvent.sentDTMF('c1', '1'));
    await h.pump();

    expect(h.callkeep.dtmfKeys, isEmpty, reason: 'the DTMF waits behind the hold in the shared queue');

    gate.release();
    h.signaling.gate = null;
    await h.settle(() => h.callkeep.dtmfKeys.isNotEmpty);

    expect(h.callkeep.dtmfKeys, ['1']);
  });

  test('the operations of two calls share one queue', () async {
    h = await CallContractHarness.start(lines: 3);
    await callUp(callId: 'c1');
    await callUp(callId: 'c2');

    final gate = HeldWork();
    h.signaling.gate = gate.gate;

    // The hold of the first call is with the server.
    h.bloc.add(CallControlEvent.setHeld('c1', true));
    await h.settle(() => h.signaling.requests.whereType<HoldRequest>().isNotEmpty);

    // The DTMF of the other call is asked for while the hold is in flight.
    h.bloc.add(CallControlEvent.sentDTMF('c2', '2'));
    await h.pump();

    expect(
      h.callkeep.dtmfKeys,
      isEmpty,
      reason: 'the queue is one for all the calls, so the DTMF of the second call waits too',
    );

    gate.release();
    h.signaling.gate = null;
    await h.settle(() => h.callkeep.dtmfKeys.isNotEmpty);

    expect(h.callkeep.dtmfKeys, ['2']);
  });

  test('the operations run in the order they were asked for', () async {
    h = await CallContractHarness.start();
    await callUp();

    h.bloc.add(CallControlEvent.sentDTMF('c1', '1'));
    h.bloc.add(CallControlEvent.setHeld('c1', true));
    h.bloc.add(CallControlEvent.sentDTMF('c1', '2'));

    await h.settle(() => h.callkeep.dtmfKeys.length == 2);

    expect(h.callkeep.dtmfKeys, ['1', '2'], reason: 'the DTMFs kept their order');
    expect(h.signaling.requests.whereType<HoldRequest>(), hasLength(1));
  });
}
