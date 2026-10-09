import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/call/conference/conference.dart';

/// The wait for the mixer's offer on its own: which attempt is current,
/// whether this session was asked for a rejoin, and when the wait is overdue.
void main() {
  const timeout = Duration(seconds: 20);

  test('work started for an earlier attempt is no longer current', () {
    final wait = RoomOfferWait(timeout: timeout);
    wait.begin();
    final merge = wait.attempt;
    expect(wait.isCurrent(merge), isTrue);

    wait.begin();

    expect(wait.isCurrent(merge), isFalse);
    expect(wait.isCurrent(wait.attempt), isTrue);
  });

  test('leaving the room voids what was in flight for it', () {
    final wait = RoomOfferWait(timeout: timeout);
    wait.begin();
    final attempt = wait.attempt;
    wait.markRejoinAsked();

    wait.end();

    expect(wait.isCurrent(attempt), isFalse);
    expect(wait.rejoinAsked, isFalse);
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

  test('an answered offer is never overdue, and the session may be asked again', () {
    fakeAsync((async) {
      final wait = RoomOfferWait(timeout: timeout);
      var overdue = 0;
      wait.beginRejoin();
      wait.markRejoinAsked();
      wait.arm(() => overdue++);

      wait.offerAnswered();
      async.elapse(const Duration(minutes: 1));

      expect(overdue, 0);
      expect(wait.rejoinAsked, isFalse);
    });
  });

  test('a session is asked for a rejoin once, and the next session anew', () {
    final wait = RoomOfferWait(timeout: timeout);
    wait.beginRejoin();
    expect(wait.rejoinAsked, isFalse);

    wait.markRejoinAsked();
    expect(wait.rejoinAsked, isTrue);

    wait.sessionLost();
    expect(wait.rejoinAsked, isFalse, reason: 'the request, or its offer, went with the session');
  });

  test('a refused rejoin leaves the session to be asked again, and no deadline', () {
    fakeAsync((async) {
      final wait = RoomOfferWait(timeout: timeout);
      var overdue = 0;
      wait.beginRejoin();
      wait.markRejoinAsked();
      wait.arm(() => overdue++);

      wait.rejoinRefused();
      async.elapse(const Duration(minutes: 1));

      expect(wait.rejoinAsked, isFalse);
      expect(overdue, 0, reason: 'a request that brings no offer has nothing to be overdue');
    });
  });

  test('a rejoin goes with the session it was asked of: its attempt is void and its deadline stops', () {
    // The request, the offer that was to follow and an answer in flight were
    // all that session's. Whatever comes back from it later - an
    // acknowledgement as much as a failure - must find its attempt gone, and
    // must not be judged by a connection that is by then another session's.
    fakeAsync((async) {
      final wait = RoomOfferWait(timeout: timeout);
      var overdue = 0;
      wait.beginRejoin();
      final ofTheLostSession = wait.attempt;
      wait.markRejoinAsked();
      wait.arm(() => overdue++);

      wait.sessionLost();
      async.elapse(const Duration(minutes: 1));

      expect(wait.isCurrent(ofTheLostSession), isFalse);
      expect(overdue, 0, reason: 'nothing can deliver the offer, and the next handshake asks again');
    });
  });

  test('a merge is not the session\'s: its attempt and its deadline run on through a session loss', () {
    // The legs are silent until the offer, and the server's word that the
    // room failed is an event the dropped socket took with it.
    fakeAsync((async) {
      final wait = RoomOfferWait(timeout: timeout);
      var overdue = 0;
      wait.begin();
      final merge = wait.attempt;
      wait.arm(() => overdue++);

      wait.sessionLost();
      expect(wait.isCurrent(merge), isTrue);
      async.elapse(const Duration(seconds: 21));

      expect(overdue, 1);
    });
  });

  test('a merge after a rejoin is a merge again', () {
    final wait = RoomOfferWait(timeout: timeout);
    wait.beginRejoin();
    wait.end();
    wait.begin();
    final merge = wait.attempt;

    wait.sessionLost();

    expect(wait.isCurrent(merge), isTrue);
  });

  test('once the host is back in the room, a session loss voids nothing', () {
    final wait = RoomOfferWait(timeout: timeout);
    wait.beginRejoin();
    final attempt = wait.attempt;
    wait.offerAnswered();

    wait.sessionLost();

    expect(wait.isCurrent(attempt), isTrue);
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
