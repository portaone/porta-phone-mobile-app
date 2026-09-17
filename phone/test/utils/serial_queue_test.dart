import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/utils/serial_queue.dart';

/// The queue exists for state that several asynchronous operations share, so
/// what it owes them is order, and independence from each other's failures.
void main() {
  test('actions run one at a time, in the order they were handed over', () async {
    final queue = SerialQueue();
    final log = <String>[];
    final first = Completer<void>();

    final one = queue.run(() async {
      log.add('one starts');
      await first.future;
      log.add('one ends');
    });
    final two = queue.run(() async => log.add('two runs'));

    await pumpEventQueue();
    expect(log, ['one starts'], reason: 'the second waits for the first to finish');

    first.complete();
    await Future.wait([one, two]);
    expect(log, ['one starts', 'one ends', 'two runs']);
  });

  test('a failed action is thrown to its own caller and to nobody else', () async {
    final queue = SerialQueue();

    final failing = queue.run(() async => throw StateError('no'));
    final after = queue.run(() async => 'ran anyway');

    await expectLater(failing, throwsStateError);
    expect(await after, 'ran anyway', reason: 'one failure must not poison the queue');
  });

  test('a failure nobody is waiting on yet still leaves the queue usable', () async {
    final queue = SerialQueue();

    final failing = queue.run(() async => throw StateError('no'));
    // Deliberately not awaited here: the queue's own tail must not carry the
    // error on to the next action.
    final after = queue.run(() async => 'ran anyway');

    expect(await after, 'ran anyway');
    await expectLater(failing, throwsStateError);
  });
}
