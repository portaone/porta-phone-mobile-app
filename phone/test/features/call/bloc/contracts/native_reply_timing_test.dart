import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'call_contract_harness.dart';

/// The contract of the moment the operating system hears back.
///
/// The platform asks the bloc to do something and waits for the answer. When
/// the answer comes decides what the platform can show: an answer that comes
/// before the work has begun says "accepted" while nothing has happened yet,
/// and an answer that comes after it says "accepted" only once the work is
/// really done - but the platform may not wait that long, and a slow answer
/// is a call the platform gives up on.
///
/// What the contract fixes is which of the two each request gets. The
/// decomposition that follows moves the work into components; the moment the
/// answer is given does not move with it, because the platform is on the
/// other side of it.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallContractHarness h;
  tearDown(() => h.close());

  /// A call that is up, so the platform has something to ask about.
  Future<void> callUp() async {
    await h.ringIncomingCall('c1');
    await h.answerIncomingCall('c1');
    await h.acceptIncomingCall('c1');
  }

  test('the platform is told "held" before the server has taken the hold', () async {
    h = await CallContractHarness.start();
    await callUp();

    // The server does not answer the hold.
    final gate = HeldWork();
    h.signaling.gate = gate.gate;

    final answered = h.bloc.performSetHeld('c1', true);

    expect(
      await answered,
      isTrue,
      reason: 'the platform is answered as soon as the request is taken, not when the server replies',
    );
    expect(h.signaling.requests.whereType<HoldRequest>(), isEmpty, reason: 'the request has not gone out yet');

    gate.release();
    h.signaling.gate = null;
    await h.settle(() => h.signaling.requests.whereType<HoldRequest>().isNotEmpty);
  });

  test('the platform is told "muted" before the mute is applied', () async {
    h = await CallContractHarness.start();
    await callUp();

    final answered = h.bloc.performSetMuted('c1', true);

    expect(await answered, isTrue);
    await h.settle(() => h.call('c1')?.muted == true);
    expect(h.call('c1')?.muted, isTrue, reason: 'the mute is applied after the platform was answered');
  });

  test('the platform is told "answered" before the answer is sent to the server', () async {
    h = await CallContractHarness.start();
    await h.ringIncomingCall('c1');

    // The server does not answer the accept request.
    final gate = HeldWork();
    h.signaling.gate = gate.gate;

    final answered = h.bloc.performAnswerCall('c1');

    expect(await answered, isTrue, reason: 'the platform is answered before the answer is sent');
    expect(h.signaling.requests.whereType<AcceptRequest>(), isEmpty);

    gate.release();
    h.signaling.gate = null;
    await h.settle(() => h.signaling.requests.whereType<AcceptRequest>().isNotEmpty);
  });

  test('the platform is told "ended" before the end is sent to the server', () async {
    h = await CallContractHarness.start();
    await callUp();

    final gate = HeldWork();
    h.signaling.gate = gate.gate;

    final answered = h.bloc.performEndCall('c1', CallkeepEndedBy.user);

    expect(await answered, isTrue);
    expect(h.signaling.requests.whereType<HangupRequest>(), isEmpty);

    gate.release();
    h.signaling.gate = null;
    await h.settle(() => h.signaling.requests.whereType<HangupRequest>().isNotEmpty);
  });

  test('the platform is told "started" only after the session is ready for an outgoing call', () async {
    // The session is not ready: the platform asks for a start, and the answer
    // waits - the start cannot go out before the signaling can carry it.
    h = await CallContractHarness.start(sessionReady: false);

    // The person places the call: the platform is asked to place it, and the
    // call waits for the session before its offer can go out.
    final callId = await h.placeOutgoingCall(number: '200');

    final answered = h.bloc.performStartCall(callId, const CallkeepHandle.number('200'), null, false);

    expect(h.signaling.requests.whereType<OutgoingCallRequest>(), isEmpty);
    // The answer is still outstanding: the start waits for the session.
    var answeredYet = false;
    unawaited(
      answered.then((_) {
        answeredYet = true;
      }),
    );
    await h.pump();
    expect(answeredYet, isFalse, reason: 'the start waits for the signaling to be ready');
    expect(h.signaling.requests.whereType<OutgoingCallRequest>(), isEmpty);

    // The session comes up; the start goes on and the platform hears back.
    await h.sessionBecomesReady();

    expect(await answered, isTrue, reason: 'the platform is answered once the session can carry the call');
    await h.settle(() => h.signaling.requests.whereType<OutgoingCallRequest>().isNotEmpty);
    expect(h.signaling.requests.whereType<OutgoingCallRequest>(), hasLength(1));
  });

  test('the platform is told "started" once the session is ready', () async {
    h = await CallContractHarness.start();

    final callId = await h.placeOutgoingCall(number: '200');
    expect(h.callkeep.starts, hasLength(1));

    // The session is ready, so the platform's start callback is answered and
    // the offer goes out.
    final answered = h.bloc.performStartCall(callId, const CallkeepHandle.number('200'), null, false);

    expect(await answered, isTrue);
    await h.settle(() => h.signaling.requests.whereType<OutgoingCallRequest>().isNotEmpty);
    expect(h.signaling.requests.whereType<OutgoingCallRequest>(), hasLength(1));
  });
}
