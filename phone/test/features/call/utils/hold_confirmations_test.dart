import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/call/utils/utils.dart';

void main() {
  late HoldConfirmations confirmations;

  setUp(() => confirmations = HoldConfirmations(timeout: const Duration(seconds: 1)));

  test('an answer that came before the wait counts', () async {
    final hold = confirmations.expect('a', onHold: true);
    confirmations.confirmed('a', onHold: true);

    expect(await hold.received, isTrue);
  });

  test('an answer within the timeout counts', () {
    fakeAsync((async) {
      final unhold = confirmations.expect('a', onHold: false);
      bool? received;
      unhold.received.then((value) => received = value);

      async.elapse(const Duration(milliseconds: 900));
      confirmations.confirmed('a', onHold: false);
      async.flushMicrotasks();

      expect(received, isTrue);
    });
  });

  test('no answer within the timeout is a dropped request', () {
    fakeAsync((async) {
      final unhold = confirmations.expect('a', onHold: false);
      bool? received;
      unhold.received.then((value) => received = value);

      async.elapse(const Duration(milliseconds: 999));
      expect(received, isNull);
      async.elapse(const Duration(milliseconds: 1));
      expect(received, isFalse);

      // A late answer confirms nothing and does not throw.
      confirmations.confirmed('a', onHold: false);
    });
  });

  test('the answer of the other kind or of another call does not confirm', () {
    fakeAsync((async) {
      final unhold = confirmations.expect('a', onHold: false);
      bool? received;
      unhold.received.then((value) => received = value);

      confirmations.confirmed('a', onHold: true);
      confirmations.confirmed('b', onHold: false);
      async.elapse(const Duration(seconds: 1));

      expect(received, isFalse);
    });
  });

  test('a new wait of the call gives up the earlier one', () async {
    final first = confirmations.expect('a', onHold: true);
    final second = confirmations.expect('a', onHold: true);
    confirmations.confirmed('a', onHold: true);

    expect(await first.received, isFalse);
    expect(await second.received, isTrue);
  });

  test('a removed call ends its wait unanswered', () async {
    final hold = confirmations.expect('a', onHold: true);
    confirmations.callRemoved('a');
    confirmations.confirmed('a', onHold: true);

    expect(await hold.received, isFalse);
  });

  test('a cancelled wait does not take the answer of the next one', () async {
    final cancelled = confirmations.expect('a', onHold: false)..cancel();
    final next = confirmations.expect('a', onHold: false);
    confirmations.confirmed('a', onHold: false);

    expect(await cancelled.received, isFalse);
    expect(await next.received, isTrue);
  });
}
