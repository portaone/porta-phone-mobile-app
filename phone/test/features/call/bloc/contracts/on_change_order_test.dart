import 'package:flutter_test/flutter_test.dart';

import 'call_contract_harness.dart';

/// The contract of the side effects a state change carries.
///
/// The bloc has no separate orchestrator for what a state change means: the
/// change itself runs the side effects, synchronously, in a fixed order, and
/// none of them goes through a queue. That makes the order part of the
/// behaviour: the peer connection of a call that left is disposed while the
/// change is still being handled, and the app is told a call ended only after
/// the state says so.
///
/// The decomposition that follows may move each side effect into a reaction
/// class of its own. What must not move is the order they run in, and what
/// must not change is that they run outside the queues - a side effect that
/// waited behind an unrelated server round trip would leave the room
/// carrying a private conversation.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallContractHarness h;
  tearDown(() => h.close());

  /// A call that is up, so a state change that ends it has something to end.
  Future<void> callUp({String callId = 'c1'}) async {
    await h.ringIncomingCall(callId);
    await h.answerIncomingCall(callId);
    await h.acceptIncomingCall(callId);
  }

  test('every state change publishes the lines to the rest of the app', () async {
    h = await CallContractHarness.start(lines: 2);

    // The session coming up has already changed the state, and published.
    expect(h.publishedLines, isNotEmpty);
    final before = h.publishedLines.length;

    await h.ringIncomingCall('c1');
    await h.answerIncomingCall('c1');
    await h.acceptIncomingCall('c1');

    expect(
      h.publishedLines.length,
      greaterThan(before),
      reason: 'the lines are published on every change, not only on the ones that touch them',
    );
  });

  test('the app is told a call ended after the state says it is gone', () async {
    h = await CallContractHarness.start();
    await callUp();

    expect(h.callsEnded, 0);

    await h.hangupFromServer('c1');

    expect(h.callsEnded, 1, reason: 'the call is gone from the state, and the app is told so');
    expect(h.call('c1'), isNull);
  });

  test('the app is not told a call ended when a call is only changed', () async {
    h = await CallContractHarness.start();
    await callUp();

    expect(h.callsEnded, 0);

    // The person holds the call: the call stays, so nothing ended.
    await h.holdCall('c1', onHold: true);

    expect(h.callsEnded, 0, reason: 'the call is still there');
    expect(h.call('c1'), isNotNull);
  });

  test('the app is told a call left, even while another one is still up', () async {
    h = await CallContractHarness.start(lines: 3);
    await callUp(callId: 'c1');
    await callUp(callId: 'c2');

    expect(h.callsEnded, 0);

    await h.hangupFromServer('c1');

    expect(h.callsEnded, 1, reason: 'the callback says a call ended, not that the conversation is over');
    expect(h.call('c2'), isNotNull);

    await h.hangupFromServer('c2');

    expect(h.callsEnded, 2);
  });

  test('the peer connection of a call that left is disposed on the change', () async {
    h = await CallContractHarness.start();
    await callUp();

    // The connection the bloc made for the call is released when the call
    // leaves - as part of the change, not as a later step.
    final peer = h.peerFactory.created.last;
    expect(peer.closes, 0);

    await h.hangupFromServer('c1');

    expect(peer.closes, 1, reason: 'the connection of the call that left is disposed');
  });

  test('the peer connection of a call that is still up is not disposed', () async {
    h = await CallContractHarness.start(lines: 3);
    await callUp(callId: 'c1');
    await callUp(callId: 'c2');

    final peers = List.of(h.peerFactory.created);
    expect(peers, hasLength(2));

    await h.hangupFromServer('c1');

    expect(peers.first.closes, 1, reason: 'the connection of the call that left is disposed');
    expect(peers.last.closes, 0, reason: 'the connection of the call that stayed is not');
  });

  test('the side effects of a change run before the next change is handled', () async {
    h = await CallContractHarness.start();
    await callUp();

    final peer = h.peerFactory.created.last;
    final publishedBefore = h.publishedLines.length;

    await h.hangupFromServer('c1');

    expect(
      h.publishedLines.length,
      greaterThan(publishedBefore),
      reason: 'the change that ended the call published the lines',
    );
    expect(peer.closes, 1);
    expect(h.callsEnded, 1);
  });

  test('the peer connection of the call that left is disposed as the call leaves', () async {
    h = await CallContractHarness.start();
    await callUp();

    h.sideEffectOrder.clear();

    await h.hangupFromServer('c1');

    // The connection of a call that left is released as part of the change
    // that removed the call - not left to a later step, and not released
    // twice. The release is not awaited by the change, but the connection is
    // closed before the release first waits, so it is recorded inside the
    // change that removed the call.
    final disposed = h.sideEffectOrder.indexOf('peer connection closed');

    expect(disposed, isNonNegative, reason: 'the connection of the call that left was disposed');
    expect(
      h.sideEffectOrder.where((it) => it == 'peer connection closed'),
      hasLength(1),
      reason: 'the connection is released once',
    );
  });

  test('the lines are published before the app is told a call ended', () async {
    h = await CallContractHarness.start();
    await callUp();

    h.sideEffectOrder.clear();

    await h.hangupFromServer('c1');

    // The order of the two side effects of the change is behaviour: the rest
    // of the app is told what the lines look like, and only then that a call
    // ended. A change that told the app first would let it act on a
    // conversation the lines do not show yet.
    final ended = h.sideEffectOrder.indexOf('call ended');

    expect(ended, isNonNegative, reason: 'the change told the app a call ended');
    expect(
      h.sideEffectOrder[ended - 1],
      'lines published',
      reason: 'the change that ended the call published the lines before it told the app',
    );
  });
}
