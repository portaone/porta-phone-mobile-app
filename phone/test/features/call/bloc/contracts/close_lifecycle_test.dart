import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';

import 'call_contract_harness.dart';

/// The contract of the end of the bloc's life.
///
/// Closing the bloc is the one moment everything it owns has to go: the
/// microphone, the peer connections, the timers, the subscriptions, the
/// conference connection. What the contract fixes is that each of them goes
/// once and only once, that the close waits for the work that is still
/// running, and that a callback that arrives after the close - a signaling
/// event, a peer connection event - does not break anything.
///
/// The decomposition that follows moves the owners of these resources into
/// components of their own. The close has to keep releasing all of them, in
/// the same order, and exactly once.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallContractHarness h;
  tearDown(() => h.close());

  /// A call that is up, with its microphone and its peer connection.
  Future<void> callUp({String callId = 'c1'}) async {
    await h.ringIncomingCall(callId);
    await h.answerIncomingCall(callId);
    await h.acceptIncomingCall(callId);
  }

  test('closing the bloc releases the microphone of the calls it holds', () async {
    h = await CallContractHarness.start();
    await callUp();

    expect(h.media.microphoneLive, isTrue);

    await h.close();

    expect(h.media.microphoneLive, isFalse, reason: 'the microphone the call held is released');
  });

  test('closing the bloc disposes the peer connections of the calls it holds', () async {
    h = await CallContractHarness.start();
    await callUp();

    final peer = h.peerFactory.created.last;
    expect(peer.closes, 0);

    await h.close();

    expect(peer.closes, 1, reason: 'the connection of the call is disposed');
  });

  test('closing the bloc twice releases the resources once', () async {
    h = await CallContractHarness.start();
    await callUp();

    final peer = h.peerFactory.created.last;

    await h.close();
    await h.close();

    expect(peer.closes, 1, reason: 'a second close does not dispose the connection again');
  });

  test('the close waits for the work that is still running', () async {
    h = await CallContractHarness.start();
    await callUp();

    // The server does not answer the hold, so the mutation that carries it is
    // still running when the close begins.
    final gate = HeldWork();
    h.signaling.gate = gate.gate;

    h.bloc.performSetHeld('c1', true);
    await h.settle(() => h.signaling.requests.whereType<HoldRequest>().isNotEmpty);

    var closed = false;
    final closing = h.close().then((_) {
      closed = true;
    });

    await h.pump();
    expect(closed, isFalse, reason: 'the close waits for the handler that is mid-flight');

    gate.release();
    h.signaling.gate = null;
    await closing;

    expect(closed, isTrue);
  });

  test('a signaling event that arrives after the close does not break anything', () async {
    h = await CallContractHarness.start();
    await callUp();

    await h.close();

    // The server says something the bloc no longer listens for. Nothing may
    // throw: the bloc is gone, and the event has nowhere to go.
    h.signaling.emit(IncomingCallEvent(line: 0, callId: 'late', caller: '100', callee: '200'));
    await h.pump();

    expect(h.call('late'), isNull, reason: 'the call that arrived after the close was not taken on');
  });

  test('a peer connection event that arrives after the close throws', () async {
    h = await CallContractHarness.start();
    await callUp();

    final peer = h.peerFactory.created.last;
    await h.close();

    // Pinned as it is, not as it should be: the observer callbacks of a peer
    // connection add to the bloc without asking whether it is still open
    // (`CallBloc._createPeerConnection`, `phone/lib/features/call/bloc/call_bloc.dart`),
    // so a native callback that arrives after the close throws
    // "Cannot add new events after calling close".
    //
    // The contract of the close says a late callback must break nothing, so
    // this is a gap in the code, not a contract to keep: it is recorded in
    // `portaone/docs/refactor-notes.md` (the row of 2026-10-30) and the test
    // names it as it is.
    Object? thrown;
    try {
      peer.onConnectionState?.call(RTCPeerConnectionState.RTCPeerConnectionStateConnected);
    } catch (error) {
      thrown = error;
    }

    expect(thrown, isA<StateError>(), reason: 'the late callback throws, as it does today');
    expect((thrown! as StateError).message, contains('Cannot add new events after calling close'));
    expect(h.call('c1'), isNotNull, reason: 'the state of a closed bloc is left as it was');
  });

  test('a late mute report from the platform does not break anything', () async {
    h = await CallContractHarness.start();
    await callUp();

    await h.close();

    // The platform publishes a mute state for a call the bloc no longer has.
    // The fake relays it to the delegate the way the platform does; the bloc
    // is gone, so there is no delegate to relay to.
    await h.callkeep.setMuted('c1', muted: true);
    await h.pump();

    expect(h.call('c1'), isNotNull);
  });

  test('closing the bloc releases the connection of the room it held', () async {
    h = await CallContractHarness.start(conference: true);
    await h.roomUp();

    // The room's own connection is the last one the factory made: the two
    // calls have theirs, the mixer has one more.
    final mixer = h.peerFactory.created.last;
    expect(mixer.closes, 0);

    await h.close();

    expect(mixer.closes, 1, reason: 'the connection of the room is released');
  });

  test('the room is torn down after the handlers have stopped', () async {
    h = await CallContractHarness.start(conference: true, lines: 3);
    await h.roomUp();

    // The room's own connection is the last one the factory made: the two
    // calls have theirs, the mixer has one more.
    final mixer = h.peerFactory.created.last;

    // A third call, outside the room: a leg of the room is never held on its
    // own, so the hold that keeps a handler running has to belong to a call
    // the room does not own.
    await h.callUp('c', line: 2);

    // The server does not answer the hold, so the mutation that carries it is
    // still running when the close begins.
    final gate = HeldWork();
    h.signaling.gate = gate.gate;

    h.bloc.performSetHeld('c', true);
    await h.settle(() => h.signaling.requests.whereType<HoldRequest>().isNotEmpty);

    var closed = false;
    final closing = h.close().then((_) {
      closed = true;
    });

    await h.pump();
    expect(closed, isFalse, reason: 'the close waits for the handler that is mid-flight');
    expect(mixer.closes, 0, reason: 'the room is still standing while the handler runs');

    gate.release();
    h.signaling.gate = null;
    await closing;

    expect(mixer.closes, 1, reason: 'the room is torn down once the handlers have stopped');
  });

  test('the resources are released before the close waits for the running handler', () async {
    h = await CallContractHarness.start();
    await callUp();

    // The server does not answer the hold, so the mutation that carries it is
    // still running when the close begins.
    final gate = HeldWork();
    h.signaling.gate = gate.gate;

    h.bloc.performSetHeld('c1', true);
    await h.settle(() => h.signaling.requests.whereType<HoldRequest>().isNotEmpty);

    var closed = false;
    final closing = h.close().then((_) {
      closed = true;
    });

    await h.pump();
    expect(closed, isFalse, reason: 'the close waits for the handler that is mid-flight');
    expect(
      h.media.microphoneLive,
      isFalse,
      reason: 'the resources are released before the close waits, so the microphone is already gone',
    );

    gate.release();
    h.signaling.gate = null;
    await closing;

    expect(closed, isTrue);
  });

  test('the peer connections are disposed before the close waits for the running handler', () async {
    h = await CallContractHarness.start();
    await callUp();

    final peer = h.peerFactory.created.last;

    // The server does not answer the hold, so the mutation that carries it is
    // still running when the close begins.
    final gate = HeldWork();
    h.signaling.gate = gate.gate;

    h.bloc.performSetHeld('c1', true);
    await h.settle(() => h.signaling.requests.whereType<HoldRequest>().isNotEmpty);

    var closed = false;
    final closing = h.close().then((_) {
      closed = true;
    });

    await h.pump();
    expect(closed, isFalse, reason: 'the close waits for the handler that is mid-flight');
    expect(
      peer.closes,
      1,
      reason: 'the connections are disposed before the close waits, so the connection is already gone',
    );

    gate.release();
    h.signaling.gate = null;
    await closing;

    expect(closed, isTrue);
  });

  test('the platform is no longer the delegate of the bloc after the close', () async {
    h = await CallContractHarness.start();
    await callUp();

    await h.close();

    // The platform asks the bloc to do something it no longer does. The ask
    // throws, because the bloc that is gone cannot take on work - the
    // platform is not left waiting for an answer that will never come.
    Object? thrown;
    try {
      await h.bloc.performAnswerCall('c1');
    } catch (error) {
      thrown = error;
    }

    expect(thrown, isA<StateError>(), reason: 'a bloc that is closed does not take on work');
    expect((thrown! as StateError).message, contains('Cannot add new events after calling close'));
  });
}
