import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/call/conference/conference.dart';

/// The wait for the mixer's offer on its own: which attempt is current and
/// when the wait is overdue.
void main() {
  const timeout = Duration(seconds: 20);

  test('work started for an earlier attempt is no longer current', () {
    final wait = RoomOfferWait(timeout: timeout);
    wait.begin();
    final first = wait.attempt;
    expect(wait.isCurrent(first), isTrue);

    wait.begin();

    expect(wait.isCurrent(first), isFalse);
    expect(wait.isCurrent(wait.attempt), isTrue);
  });

  test('leaving the room voids what was in flight for it', () {
    final wait = RoomOfferWait(timeout: timeout);
    wait.begin();
    final attempt = wait.attempt;

    wait.end();

    expect(wait.isCurrent(attempt), isFalse);
  });

  test('an offer that does not come is overdue once, after the timeout', () {
    fakeAsync((async) {
      final wait = RoomOfferWait(timeout: timeout);
      var overdue = 0;
      wait.arm(() => overdue++);

      async.elapse(const Duration(seconds: 19));
      expect(overdue, 0);
      async.elapse(const Duration(seconds: 2));
      expect(overdue, 1);
      async.elapse(const Duration(minutes: 1));
      expect(overdue, 1);
    });
  });

  test('an answered offer is never overdue', () {
    fakeAsync((async) {
      final wait = RoomOfferWait(timeout: timeout);
      var overdue = 0;
      wait.arm(() => overdue++);

      wait.offerAnswered();
      async.elapse(const Duration(minutes: 1));

      expect(overdue, 0);
    });
  });

  test('a new attempt drops the deadline of the one before', () {
    fakeAsync((async) {
      final wait = RoomOfferWait(timeout: timeout);
      var overdue = 0;
      wait.arm(() => overdue++);

      wait.begin();
      async.elapse(const Duration(minutes: 1));

      expect(overdue, 0);
    });
  });

  test('armed again, only the later deadline stands', () {
    fakeAsync((async) {
      final wait = RoomOfferWait(timeout: timeout);
      final overdue = <String>[];
      wait.arm(() => overdue.add('first'));
      async.elapse(const Duration(seconds: 10));
      wait.arm(() => overdue.add('second'));

      async.elapse(const Duration(seconds: 15));
      expect(overdue, isEmpty, reason: 'the first one would have passed by now');
      async.elapse(const Duration(seconds: 6));
      expect(overdue, ['second']);
    });
  });

  test('the deadline is made by the timer it is given', () {
    final asked = <Duration>[];
    void Function()? overdue;
    final wait = RoomOfferWait(
      timeout: timeout,
      createTimer: (duration, onOverdue) {
        asked.add(duration);
        overdue = onOverdue;
        return Timer(Duration.zero, () {})..cancel();
      },
    );
    var passed = 0;

    wait.arm(() => passed++);
    overdue!();

    expect(asked, [timeout]);
    expect(passed, 1);
  });

  test('nothing is overdue after disposal', () {
    fakeAsync((async) {
      final wait = RoomOfferWait(timeout: timeout);
      var overdue = 0;
      wait.arm(() => overdue++);

      wait.dispose();
      async.elapse(const Duration(minutes: 1));

      expect(overdue, 0);
    });
  });
}
