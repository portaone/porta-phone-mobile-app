import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/utils/call_update_ledger.dart';

const _callId = 'call-abc';

void main() {
  late CallUpdateLedger ledger;

  setUp(() => ledger = CallUpdateLedger());

  /// Takes a live update through an attempt that ends with [answer] and
  /// returns its number.
  int handleLive(CallUpdateAnswer answer) {
    final ordinal = ledger.nextLiveUpdateOrdinal(_callId);
    ledger.finish(ledger.begin(_callId, ordinal)!, answer);
    return ordinal;
  }

  test('a call\'s updates are numbered from one, on top of what a handshake counted', () {
    expect(ledger.nextLiveUpdateOrdinal(_callId), 1);
    expect(ledger.nextLiveUpdateOrdinal(_callId), 2);

    ledger.setObservedUpdateCount(_callId, 5);
    expect(ledger.nextLiveUpdateOrdinal(_callId), 6);

    expect(ledger.nextLiveUpdateOrdinal('another call'), 1);
  });

  test('an update being handled is not taken in again', () {
    final attempt = ledger.begin(_callId, 1);

    expect(attempt, isNotNull);
    expect(ledger.begin(_callId, 1), isNull);
  });

  test('an update that was answered is not taken in again', () {
    ledger.finish(ledger.begin(_callId, 1)!, CallUpdateAnswer.acknowledged);

    expect(ledger.begin(_callId, 1), isNull);
  });

  test('an update whose attempt ended without an answer is taken in again', () {
    ledger.finish(ledger.begin(_callId, 1)!, CallUpdateAnswer.notSent);

    expect(ledger.begin(_callId, 1), isNotNull);
  });

  test('an answered update does not keep the next one of the call out', () {
    final first = handleLive(CallUpdateAnswer.acknowledged);
    final second = handleLive(CallUpdateAnswer.notSent);

    expect(ledger.begin(_callId, first), isNull);
    expect(ledger.begin(_callId, second), isNotNull);
  });

  test('a handshake that counts the same updates names them by the same numbers', () {
    final answered = handleLive(CallUpdateAnswer.acknowledged);

    // The socket reconnects; the new handshake's log shows that one update.
    ledger.setObservedUpdateCount(_callId, 1);

    expect(ledger.begin(_callId, answered), isNull);
    expect(ledger.nextLiveUpdateOrdinal(_callId), 2);
  });

  test('an attempt ends the update it was opened for, whatever else is open', () {
    final first = ledger.begin(_callId, 1)!;
    final second = ledger.begin(_callId, 2)!;

    // The later one ends first.
    ledger.finish(second, CallUpdateAnswer.notSent);

    expect(ledger.begin(_callId, 1), isNull, reason: 'the first is still being handled');
    expect(ledger.begin(_callId, 2), isNotNull, reason: 'the second is free again');

    ledger.finish(first, CallUpdateAnswer.acknowledged);
    expect(ledger.begin(_callId, 1), isNull, reason: 'answered');
  });

  test('ending an attempt twice changes nothing the second time', () {
    final attempt = ledger.begin(_callId, 1)!;
    ledger.finish(attempt, CallUpdateAnswer.notSent);

    ledger.finish(attempt, CallUpdateAnswer.acknowledged);

    expect(ledger.begin(_callId, 1), isNotNull, reason: 'the first ending stands');
  });

  test('a call that is over is forgotten with its count', () {
    final ordinal = handleLive(CallUpdateAnswer.acknowledged);

    ledger.forget(_callId);

    expect(ledger.nextLiveUpdateOrdinal(_callId), 1);
    expect(ledger.begin(_callId, ordinal), isNotNull);
  });

  test('an attempt that outlives its call leaves nothing behind when it ends', () {
    final attempt = ledger.begin(_callId, 1)!;
    ledger.forget(_callId);

    ledger.finish(attempt, CallUpdateAnswer.acknowledged);

    expect(ledger.begin(_callId, 1), isNotNull, reason: 'a new call with the same id starts clean');
  });

  group('an update a handshake shows unanswered while its attempt is open', () {
    const update = UpdatingCallEvent(line: 0, callId: _callId, caller: '1', callee: '2');

    test('is handed back when that attempt ends without an answer', () {
      final attempt = ledger.begin(_callId, 1)!;
      expect(ledger.begin(_callId, 1), isNull);
      ledger.askAgain(_callId, 1, update);

      expect(ledger.finish(attempt, CallUpdateAnswer.notSent), update);
      expect(ledger.begin(_callId, 1), isNotNull, reason: 'and is free to be taken in');
    });

    test('is not handed back once that attempt was answered', () {
      final attempt = ledger.begin(_callId, 1)!;
      ledger.askAgain(_callId, 1, update);

      expect(ledger.finish(attempt, CallUpdateAnswer.acknowledged), isNull);
      expect(ledger.begin(_callId, 1), isNull);
    });

    test('is not kept for an update that was answered already', () {
      ledger.finish(ledger.begin(_callId, 1)!, CallUpdateAnswer.acknowledged);
      ledger.askAgain(_callId, 1, update);

      expect(ledger.begin(_callId, 1), isNull);
    });

    test('is handed back once, and not by an attempt that ended without being asked again', () {
      final first = ledger.begin(_callId, 1)!;
      ledger.askAgain(_callId, 1, update);
      expect(ledger.finish(first, CallUpdateAnswer.refused), update);

      final second = ledger.begin(_callId, 1)!;
      expect(ledger.finish(second, CallUpdateAnswer.notSent), isNull);
    });
  });
}
