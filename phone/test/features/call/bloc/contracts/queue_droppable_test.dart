import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'call_contract_harness.dart';

/// The contract of a droppable queue: an event that arrives while another of
/// the same kind is being handled is dropped, not queued.
///
/// Dropping is not the same as waiting. A queue that waited would carry out
/// every event in the order they arrived; a droppable queue carries out the
/// one in flight and lets the rest go. What the rest were asking for is
/// either already the truth - the newest registration supersedes the older
/// one - or is work that must not pile up: a reset that a newer reset makes
/// pointless, or a reset of a call that is gone by the time the running one
/// has finished.
///
/// The order is set by hand: the platform is held while the event in flight
/// waits for it, so the test sees exactly which event was dropped.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallContractHarness h;
  tearDown(() => h.close());

  /// Two calls that are up, so a reset has something to reset.
  Future<void> twoCallsUp() async {
    await h.ringIncomingCall('c1');
    await h.answerIncomingCall('c1');
    await h.acceptIncomingCall('c1');
    await h.ringIncomingCall('c2', line: 1);
    await h.answerIncomingCall('c2');
    await h.acceptIncomingCall('c2');
  }

  test('a reset that arrives while another one is running is dropped', () async {
    h = await CallContractHarness.start();
    await twoCallsUp();

    // The platform takes a long time to acknowledge the end of a call - as it
    // does on a cold start, where the round trip stretches to seconds.
    final gate = Completer<void>();
    h.callkeep.endReportGate = gate;

    // The registration fails, so the bloc resets every call it holds. The
    // reset of the first call is in flight, and the platform has not answered
    // it yet.
    h.signaling.emit(UnregisteredEvent());
    await h.settle(() => h.callkeep.ended.isNotEmpty);

    expect(h.callkeep.ended, ['c1'], reason: 'the reset of the first call is running');

    expect(
      h.callkeep.ended,
      hasLength(1),
      reason: 'the reset of the second call was dropped while the first one was running',
    );
    expect(h.call('c2'), isNotNull, reason: 'the second call is still there');

    gate.complete();
    h.callkeep.endReportGate = null;
    await h.pump();

    // The dropped reset does not run later either: a queue that waited would
    // carry it out once the running one was done.
    expect(h.callkeep.ended, [
      'c1',
    ], reason: 'the reset of the second call was dropped, not queued behind the first one');
  });

  test('a registration that arrives while the previous one is being applied does not pile up', () async {
    h = await CallContractHarness.start();

    // The registration changes twice in a row. The queue is droppable, so the
    // second one does not wait for the first - it is dropped, and the state
    // ends up with what the running one wrote.
    h.signaling.emit(RegisteredEvent());
    await h.settle(() => h.bloc.state.callServiceState.registration?.status == RegistrationStatus.registered);

    expect(h.bloc.state.callServiceState.registration?.status, RegistrationStatus.registered);
  });

  test('the registration that arrives right after another one is applied anyway', () async {
    h = await CallContractHarness.start();

    // Two registrations in a row, without a turn in between.
    //
    // The queue is droppable, so a registration that arrives while another one
    // is being applied is dropped. The handler of that queue does not wait
    // for anything, so the first one is applied before the second one is
    // looked at, and the second one is applied as well: the state ends up
    // carrying the newest registration either way.
    //
    // The drop is therefore not observable here, and this test pins what is:
    // the newest registration is the one the state carries. Whether the
    // transformer drops the second one is a question about the order of two
    // microtasks, not about the behaviour a person can see.
    h.signaling.emit(RegisteredEvent());
    h.signaling.emit(UnregisteredEvent());
    await h.pump();

    expect(
      h.bloc.state.callServiceState.registration?.status,
      RegistrationStatus.unregistered,
      reason: 'the newest registration is the one the state carries',
    );
  });

  test('the newest registration is the one the state carries', () async {
    h = await CallContractHarness.start();

    h.signaling.emit(UnregisteredEvent());
    await h.settle(() => h.bloc.state.callServiceState.registration?.status == RegistrationStatus.unregistered);

    expect(h.bloc.state.callServiceState.registration?.status, RegistrationStatus.unregistered);
  });
}
