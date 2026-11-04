import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'call_bloc_harness.dart';

// An update of the far end that a handshake finds unanswered in the call's
// log (a re-INVITE that arrived while the socket was down) is handed to the
// handler of a live update. These tests are about the two ways that hand-over
// can go wrong around the handler: answering an update twice, and never
// answering it again after one failed attempt.

const _callId = 'a';

const _update = UpdatingCallEvent(
  line: 0,
  callId: _callId,
  caller: '100',
  callee: '200',
  jsep: {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'},
);

/// The session as the server reports it; the log is newest first.
StateHandshake _handshake({bool updateUnanswered = false, UpdatingCallEvent loggedUpdate = _update}) => StateHandshake(
  keepaliveInterval: const Duration(seconds: 30),
  timestamp: 1,
  registration: const Registration(status: RegistrationStatus.registered),
  lines: [
    Line(
      callId: _callId,
      callLogs: [
        if (updateUnanswered) CallEventLog(timestamp: 10, callEvent: loggedUpdate),
        const CallEventLog(timestamp: 2, callEvent: AcceptedEvent(line: 0, callId: _callId)),
        const CallEventLog(
          timestamp: 1,
          callEvent: IncomingCallEvent(line: 0, callId: _callId, caller: '100', callee: '200'),
        ),
      ],
    ),
  ],
  presenceInfos: [],
  dialogInfos: [],
  guestLine: null,
);

/// Callkeep whose read of the connections stays open until the test lets it go.
class _HeldConnections extends Fake implements CallkeepConnections {
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

/// Callkeep whose first read of the connections returns at once and whose
/// second one stays open until the test lets it go.
class _SecondReadHeld extends Fake implements CallkeepConnections {
  var _reads = 0;
  final entered = Completer<void>();
  final release = Completer<List<CallkeepConnection>>();

  @override
  Future<List<CallkeepConnection>> getConnections() async {
    if (++_reads == 1) return [];
    if (!entered.isCompleted) entered.complete();
    return release.future;
  }

  @override
  Future<CallkeepConnection?> getConnection(String callId) async => null;
}

List<UpdateRequest> _answers(CallBlocHarness harness) =>
    harness.signaling.requests.whereType<UpdateRequest>().where((r) => r.jsep['type'] == 'answer').toList();

/// The server's word that the last answer was taken, and then that the offer
/// the client makes once its answer is out (the renegotiation its reconnect
/// owes the call) was taken too - the handler of each waits for that word.
Future<void> _confirmLastAnswer(CallBlocHarness harness) async {
  harness.signaling.emit(UpdatedEvent(line: 0, callId: _callId, transaction: _answers(harness).last.transaction));
  await pumpEventQueue();
  final offers = harness.signaling.requests.whereType<UpdateRequest>().where((r) => r.jsep['type'] == 'offer');
  for (final offer in offers.toList()) {
    harness.signaling.emit(UpdatedEvent(line: 0, callId: _callId, transaction: offer.transaction));
  }
  await pumpEventQueue();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an update left unanswered in the log is answered', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    harness.seedEstablishedCall(_callId);

    harness.signaling.emitHandshake(_handshake(updateUnanswered: true));
    await pumpEventQueue();

    expect(_answers(harness), hasLength(1));
    await _confirmLastAnswer(harness);
  });

  group('a call restored after the app was gone', () {
    List<String> sent(CallBlocHarness harness) =>
        harness.signaling.requests.whereType<UpdateRequest>().map((r) => r.jsep['type'] as String).toList();

    test('answers the update left unanswered instead of making an offer of its own', () async {
      final harness = CallBlocHarness();
      addTearDown(harness.close);

      harness.signaling.emitHandshake(_handshake(updateUnanswered: true));
      await pumpEventQueue();

      expect(harness.bloc.state.retrieveActiveCall(_callId), isNotNull);
      expect(sent(harness), ['answer'], reason: 'an offer of its own would wait behind the update for good');
      await _confirmLastAnswer(harness);
    });

    test('makes no ICE restart of its own after the answer', () {
      fakeAsync((async) {
        final harness = CallBlocHarness();
        harness.signaling.emitHandshake(_handshake(updateUnanswered: true));
        async.flushMicrotasks();
        expect(_answers(harness), hasLength(1));

        async.elapse(const Duration(seconds: 3));
        expect(harness.peerFactory.created.single.iceRestarts, 0, reason: 'the answer is not taken yet');

        // The media server restarts its own ICE checks for an answer from a
        // new connection: a restart of ours would be one more renegotiation.
        harness.signaling.emit(UpdatedEvent(line: 0, callId: _callId, transaction: _answers(harness).last.transaction));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 3));
        expect(harness.peerFactory.created.single.iceRestarts, 0);
        expect(_answers(harness), hasLength(1));

        harness.close();
        async.flushMicrotasks();
      });
    });

    test('with nothing missed makes the offer of a restored call', () async {
      final harness = CallBlocHarness();
      addTearDown(harness.close);

      harness.seedSignalingReady();
      harness.signaling.emitHandshake(_handshake());
      await pumpEventQueue();

      expect(sent(harness), ['offer']);
      expect(harness.peerFactory.created.single.iceRestarts, 0);
      final offer = harness.signaling.requests.whereType<UpdateRequest>().single;
      harness.signaling.emit(UpdatedEvent(line: 0, callId: _callId, transaction: offer.transaction));
      await pumpEventQueue();
    });
  });

  test('after a reconnect the answer to the missed update goes out before the client\'s own offer', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    harness.seedEstablishedCall(_callId);

    // A reconnect owes every call that lived through it a renegotiation. Sent
    // ahead of the answer, that offer is held by the media server behind the
    // unanswered update and answered only after the client has rolled it back.
    harness.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();
    harness.signaling.emitHandshake(_handshake(updateUnanswered: true));
    await pumpEventQueue();

    List<String> sent() =>
        harness.signaling.requests.whereType<UpdateRequest>().map((r) => r.jsep['type'] as String).toList();
    expect(sent(), ['answer'], reason: 'the offer waits for the answer to be taken');

    await _confirmLastAnswer(harness);
    expect(sent(), ['answer', 'offer']);
  });

  test('a reconnect with nothing missed renegotiates the call at once', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    harness.seedEstablishedCall(_callId);

    harness.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();
    harness.signaling.emitHandshake(_handshake());
    await pumpEventQueue();

    final sent = harness.signaling.requests.whereType<UpdateRequest>().toList();
    expect(sent.map((r) => r.jsep['type']), ['offer']);
    harness.signaling.emit(UpdatedEvent(line: 0, callId: _callId, transaction: sent.single.transaction));
    await pumpEventQueue();
  });

  test('a live update answered while the handshake waits on callkeep is not answered twice', () async {
    final connections = _HeldConnections();
    final harness = CallBlocHarness(callkeepConnections: connections);
    addTearDown(harness.close);
    harness.seedEstablishedCall(_callId);

    // The handshake stops at its callkeep reads; the update arrives live and
    // is answered. The session the plan reads now holds the update and not
    // the client's answer to it.
    harness.signaling.emitHandshake(_handshake());
    await connections.entered.future;
    harness.signaling.emit(_update);
    await pumpEventQueue();
    expect(_answers(harness), hasLength(1));
    await _confirmLastAnswer(harness);

    connections.release.complete([]);
    await pumpEventQueue();

    final answers = _answers(harness).length;
    if (answers > 1) await _confirmLastAnswer(harness);
    expect(answers, 1);
  });

  test('a second handshake that arrives before the answer is sent does not answer the update again', () async {
    final connections = _SecondReadHeld();
    final harness = CallBlocHarness(callkeepConnections: connections);
    addTearDown(harness.close);
    harness.seedEstablishedCall(_callId);

    // The first handshake hands the update over; its handler stops at the
    // native report, before any answer.
    harness.callkeep.updateGate = Completer<void>();
    harness.signaling.emitHandshake(_handshake(updateUnanswered: true));
    await pumpEventQueue();
    expect(_answers(harness), isEmpty);

    // The second one is accurate too - nothing has been answered yet - and
    // stops at its callkeep reads. The first handler finishes meanwhile.
    harness.signaling.emitHandshake(_handshake(updateUnanswered: true));
    await connections.entered.future;
    harness.callkeep.updateGate!.complete();
    await pumpEventQueue();
    expect(_answers(harness), hasLength(1));
    await _confirmLastAnswer(harness);

    connections.release.complete([]);
    await pumpEventQueue();

    final answers = _answers(harness).length;
    if (answers > 1) await _confirmLastAnswer(harness);
    expect(answers, 1);
  });

  test('an answered update does not keep the next one of the same call from being handed over', () async {
    final uncaught = <Object>[];
    var answers = -1;
    var offersApplied = -1;

    await runZonedGuarded<Future<void>>(() async {
      final connections = _HeldConnections();
      final harness = CallBlocHarness(callkeepConnections: connections);
      final peer = harness.seedEstablishedCall(_callId);

      // The handshake stops at its callkeep reads; one update is heard live,
      // answered and confirmed.
      harness.signaling.emitHandshake(_handshake());
      await connections.entered.future;
      harness.signaling.emit(_update);
      await pumpEventQueue();
      await _confirmLastAnswer(harness);

      // A second one, with another offer, fails at the native report.
      const nextUpdate = UpdatingCallEvent(
        line: 0,
        callId: _callId,
        caller: '100',
        callee: '200',
        jsep: {'type': 'offer', 'sdp': 'v=0\r\no=- 1 2 IN IP4 127.0.0.1\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'},
      );
      harness.callkeep.updateError = StateError('transient native failure on the second update');
      harness.signaling.emit(nextUpdate);
      await pumpEventQueue();
      harness.callkeep.updateError = null;

      // The handshake goes on and finds the second update unanswered.
      connections.release.complete([]);
      await pumpEventQueue();

      answers = _answers(harness).length;
      offersApplied = peer.remoteDescriptions.map((d) => d.sdp).toSet().length;
      if (answers > 1) await _confirmLastAnswer(harness);
      await harness.close();
    }, (error, stack) => uncaught.add(error));

    expect(uncaught, hasLength(1), reason: 'the native failure itself still surfaces');
    expect(answers, 2, reason: 'the first answer belongs to another offer');
    expect(offersApplied, 2);
  });

  test('a live update still being answered is not answered again when a reconnect reports it', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    harness.seedEstablishedCall(_callId);
    harness.signaling.emitHandshake(_handshake());
    await pumpEventQueue();

    // The update is heard live; its handler stops at the native report.
    harness.callkeep.updateGate = Completer<void>();
    harness.signaling.emit(_update);
    await pumpEventQueue();
    expect(_answers(harness), isEmpty);

    // The socket reconnects. The server reports the same update as it parses
    // it from its log: another object, with a timestamp the client never saw.
    harness.signaling.emitLifecycle(SignalingConnecting());
    harness.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();
    final reparsed = UpdatingCallEvent.fromJson(_update.toJson());
    expect(identical(reparsed, _update), isFalse);
    harness.signaling.emitHandshake(_handshake(updateUnanswered: true, loggedUpdate: reparsed));
    await pumpEventQueue();

    harness.callkeep.updateGate!.complete();
    await pumpEventQueue();
    expect(_answers(harness), hasLength(1));
    await _confirmLastAnswer(harness);

    final answers = _answers(harness).length;
    if (answers > 1) await _confirmLastAnswer(harness);
    expect(answers, 1);
  });

  test('a live update answered while a reconnect\'s handshake waits is not answered again', () async {
    final connections = _SecondReadHeld();
    final harness = CallBlocHarness(callkeepConnections: connections);
    addTearDown(harness.close);
    harness.seedEstablishedCall(_callId);
    harness.signaling.emitHandshake(_handshake());
    await pumpEventQueue();
    harness.callkeep.updateGate = Completer<void>();
    harness.signaling.emit(_update);
    await pumpEventQueue();
    expect(_answers(harness), isEmpty);
    harness.signaling.emitLifecycle(SignalingConnecting());
    harness.signaling.emitLifecycle(SignalingConnected());
    await pumpEventQueue();
    final reparsed = UpdatingCallEvent.fromJson(_update.toJson());
    expect(identical(reparsed, _update), isFalse);
    harness.signaling.emitHandshake(_handshake(updateUnanswered: true, loggedUpdate: reparsed));
    await connections.entered.future;
    harness.callkeep.updateGate!.complete();
    await pumpEventQueue();
    expect(_answers(harness), hasLength(1));
    await _confirmLastAnswer(harness);
    connections.release.complete([]);
    await pumpEventQueue();
    final count = _answers(harness).length;
    // The reconnect still owes the call a renegotiation; its offer goes out
    // once the plan is done and waits for the server's word like any other.
    await _confirmLastAnswer(harness);
    expect(count, 1, reason: 'the handshake describes the same live update');
  });

  test('an update handed over from a log is not handled again when it also comes live', () async {
    final connections = _HeldConnections();
    final harness = CallBlocHarness(callkeepConnections: connections);
    addTearDown(harness.close);
    harness.seedEstablishedCall(_callId);

    // The handshake stops at its callkeep reads. The update arrives then: the
    // session holds it at once, its delivery to the bloc is still on the way.
    harness.signaling.emitHandshake(_handshake());
    await connections.entered.future;
    harness.signaling.holdProtocolEvents = true;
    harness.signaling.emit(_update);
    await pumpEventQueue();
    expect(_answers(harness), isEmpty, reason: 'the bloc has not heard the update yet');

    // The plan is made from the session and hands the update over from it.
    connections.release.complete([]);
    await pumpEventQueue();
    expect(_answers(harness), hasLength(1), reason: 'answered from the session\'s log');
    await _confirmLastAnswer(harness);

    // Now the live event of the same update gets through.
    harness.signaling.releaseProtocolEvents();
    await pumpEventQueue();

    expect(_answers(harness), hasLength(1));
  });

  test('what was answered for a call is forgotten when the far end hangs up', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    harness.seedEstablishedCall(_callId);

    harness.signaling.emitHandshake(_handshake(updateUnanswered: true));
    await pumpEventQueue();
    expect(_answers(harness), hasLength(1));
    await _confirmLastAnswer(harness);

    // An ordinary end of the call: it leaves the state without a reset.
    harness.signaling.emit(const HangupEvent(line: 0, callId: _callId, code: 200, reason: 'Bye'));
    await pumpEventQueue();
    expect(harness.bloc.state.activeCalls, isEmpty);

    // Were the ledger still holding the answered update, a call that came to
    // carry the same id and the same log entry would be taken for answered.
    harness.seedEstablishedCall(_callId);
    harness.signaling.emitHandshake(_handshake(updateUnanswered: true));
    await pumpEventQueue();

    expect(_answers(harness), hasLength(2));
    await _confirmLastAnswer(harness);
  });

  test('an update whose native report failed is handed over again by the next handshake', () async {
    final uncaught = <Object>[];
    var answersAfterRecovery = -1;

    await runZonedGuarded<Future<void>>(() async {
      final harness = CallBlocHarness();
      harness.seedEstablishedCall(_callId);

      harness.callkeep.updateError = StateError('transient native reportUpdateCall failure');
      harness.signaling.emitHandshake(_handshake(updateUnanswered: true));
      await pumpEventQueue();

      harness.callkeep.updateError = null;
      harness.signaling.emitLifecycle(SignalingConnected());
      await pumpEventQueue();
      harness.signaling.emitHandshake(_handshake(updateUnanswered: true));
      await pumpEventQueue();

      answersAfterRecovery = _answers(harness).length;
      if (answersAfterRecovery > 0) await _confirmLastAnswer(harness);
      await harness.close();
    }, (error, stack) => uncaught.add(error));

    expect(uncaught, hasLength(1), reason: 'the native failure itself still surfaces');
    expect(answersAfterRecovery, 1);
  });

  test('a second update with the very same offer is answered as well', () async {
    final uncaught = <Object>[];
    var answers = -1;
    await runZonedGuarded<Future<void>>(() async {
      final connections = _HeldConnections();
      final harness = CallBlocHarness(callkeepConnections: connections);
      harness.seedEstablishedCall(_callId);
      harness.signaling.emitHandshake(_handshake());
      await connections.entered.future;

      // The first update is heard live, answered and confirmed.
      harness.signaling.emit(UpdatingCallEvent.fromJson(_update.toJson()));
      await pumpEventQueue();
      await _confirmLastAnswer(harness);

      // The far end sends the same offer again; this time the native report fails.
      harness.callkeep.updateError = StateError('transient native failure');
      harness.signaling.emit(UpdatingCallEvent.fromJson(_update.toJson()));
      await pumpEventQueue();
      harness.callkeep.updateError = null;

      // The handshake goes on and finds the second one unanswered.
      connections.release.complete([]);
      await pumpEventQueue();
      answers = _answers(harness).length;
      if (answers > 1) await _confirmLastAnswer(harness);
      await harness.close();
    }, (error, stack) => uncaught.add(error));
    expect(answers, 2, reason: 'the second update is owed an answer of its own');
  });

  test('an answer that could not be sent leaves the update to the next handshake', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    harness.seedEstablishedCall(_callId);
    harness.signaling.emitHandshake(_handshake());
    await pumpEventQueue();

    // The socket is down by the time the answer is ready.
    harness.signaling.sendable = false;
    harness.signaling.emit(_update);
    await pumpEventQueue();
    expect(_answers(harness), isEmpty);

    // It reconnects; the server still shows the update unanswered.
    harness.signaling.sendable = true;
    harness.signaling.emitHandshake(_handshake(updateUnanswered: true));
    await pumpEventQueue();

    expect(_answers(harness), hasLength(1));
    await _confirmLastAnswer(harness);
  });

  test('an answer lost with the signaling on the way leaves the update to the next handshake', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);
    harness.seedEstablishedCall(_callId);
    harness.signaling.emitHandshake(_handshake());
    await pumpEventQueue();

    // The request is taken but the socket closes under it.
    harness.signaling.failure = NotConnectedException('closed');
    harness.signaling.connected = false;
    harness.signaling.emit(_update);
    await pumpEventQueue();
    expect(_answers(harness), hasLength(1));
    expect(harness.bloc.state.activeCalls, hasLength(1), reason: 'a lost signaling does not end the call');
    expect(harness.callkeep.ended, isEmpty);

    harness.signaling.failure = null;
    harness.signaling.connected = true;
    harness.reconnect();
    harness.signaling.emitHandshake(_handshake(updateUnanswered: true));
    await pumpEventQueue();

    expect(_answers(harness), hasLength(2), reason: 'the update is answered again on the new connection');
    await _confirmLastAnswer(harness);
  });

  test('an answer the server never replied to before a reconnect leaves the update to the next handshake', () {
    fakeAsync((async) {
      final harness = CallBlocHarness();
      harness.seedEstablishedCall(_callId);
      harness.signaling.emitHandshake(_handshake());
      async.flushMicrotasks();

      // The request completes - the queue completes one whose connection was
      // replaced without an error - and no reply to it ever comes.
      harness.signaling.emit(_update);
      async.flushMicrotasks();
      expect(_answers(harness), hasLength(1));

      // The session reconnects; its handshake comes once the reply is given up.
      harness.signaling.emitLifecycle(SignalingConnected());
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 11));

      expect(harness.bloc.state.activeCalls, hasLength(1), reason: 'the call outlives the lost reply');
      expect(harness.callkeep.ended, isEmpty);

      expect(
        harness.bloc.state.activeCalls.single.updating,
        isFalse,
        reason: 'no exchange is in flight: the call\'s own offers are not held back by the flag',
      );

      harness.signaling.emitHandshake(_handshake(updateUnanswered: true));
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));
      expect(_answers(harness), hasLength(2), reason: 'the update was not taken as answered');

      final offers = harness.signaling.requests.whereType<UpdateRequest>().where((r) => r.jsep['type'] == 'offer');
      expect(offers, isEmpty, reason: 'the reconnect\'s own offer waits for the answer');

      harness.signaling.emit(UpdatedEvent(line: 0, callId: _callId, transaction: _answers(harness).last.transaction));
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));
      expect(offers, hasLength(1), reason: 'and goes once the answer is taken');
      harness.signaling.emit(UpdatedEvent(line: 0, callId: _callId, transaction: offers.single.transaction));
      async.flushMicrotasks();
      unawaited(harness.close());
      async.flushMicrotasks();
    });
  });

  test('a reconnect that reports the update while its answer waits for a reply hands it over once that wait ends', () {
    fakeAsync((async) {
      final harness = CallBlocHarness();
      harness.seedEstablishedCall(_callId);
      harness.signaling.emitHandshake(_handshake());
      async.flushMicrotasks();

      // The answer goes out on the session that is about to be lost; no reply to it comes.
      harness.signaling.emit(_update);
      async.flushMicrotasks();
      expect(_answers(harness), hasLength(1));

      // The session reconnects and its handshake still shows the update unanswered,
      // while the answer above still waits for its reply.
      harness.signaling.emitLifecycle(SignalingConnected());
      async.flushMicrotasks();
      harness.signaling.emitHandshake(_handshake(updateUnanswered: true));
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));
      final offers = harness.signaling.requests.whereType<UpdateRequest>().where((r) => r.jsep['type'] == 'offer');
      expect(offers, isEmpty, reason: 'the reconnect\'s own offer waits behind the update');

      // The wait for the reply ends: the answer was lost with its session.
      async.elapse(const Duration(seconds: 10));
      expect(_answers(harness), hasLength(2), reason: 'the update the new session still waits for is answered');
      expect(offers, isEmpty, reason: 'and the client\'s offer still waits for that answer');

      harness.signaling.emit(UpdatedEvent(line: 0, callId: _callId, transaction: _answers(harness).last.transaction));
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));
      expect(offers, hasLength(1));
      harness.signaling.emit(UpdatedEvent(line: 0, callId: _callId, transaction: offers.single.transaction));
      async.flushMicrotasks();
      unawaited(harness.close());
      async.flushMicrotasks();
    });
  });

  test('a restored call whose missed update carries no offer makes the offer of its own', () async {
    final harness = CallBlocHarness();
    addTearDown(harness.close);

    const noOffer = UpdatingCallEvent(line: 0, callId: _callId, caller: '100', callee: '200');
    harness.seedSignalingReady();
    harness.signaling.emitHandshake(_handshake(updateUnanswered: true, loggedUpdate: noOffer));
    await pumpEventQueue();

    final offers = harness.signaling.requests.whereType<UpdateRequest>().where((r) => r.jsep['type'] == 'offer');
    expect(_answers(harness), isEmpty);
    expect(offers, hasLength(1), reason: 'nothing else negotiates the new connection');
    harness.signaling.emit(UpdatedEvent(line: 0, callId: _callId, transaction: offers.single.transaction));
    await pumpEventQueue();
  });

  test('an answer the server refuses leaves the call\'s renegotiation to the randomized retry', () {
    fakeAsync((async) {
      final harness = CallBlocHarness();
      final peerConnection = harness.seedEstablishedCall(_callId);
      harness.signaling.emitHandshake(_handshake());
      async.flushMicrotasks();

      // A reconnect with a missed update: the reconnect's own offer is held behind it.
      harness.signaling.emitLifecycle(SignalingConnected());
      async.flushMicrotasks();
      harness.signaling.emitHandshake(_handshake(updateUnanswered: true));
      async.flushMicrotasks();
      expect(_answers(harness), hasLength(1));

      harness.signaling.emit(
        CallErrorEvent(
          transaction: _answers(harness).single.transaction,
          line: 0,
          callId: _callId,
          code: 491,
          reason: 'Request Pending',
        ),
      );
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 500));
      final offers = harness.signaling.requests.whereType<UpdateRequest>().where((r) => r.jsep['type'] == 'offer');
      expect(offers, isEmpty, reason: 'an offer at once would collide again');

      async.elapse(const Duration(seconds: 13));
      expect(peerConnection.iceRestarts, 1, reason: 'the retry after a random delay');
      expect(offers, isEmpty, reason: 'one retry, not an offer besides it');
      unawaited(harness.close());
      async.flushMicrotasks();
    });
  });
}
