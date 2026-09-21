import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/models/models.dart';

CdrRecord _record(String callId) => CdrRecord(
  callId: callId,
  direction: CallDirection.incoming,
  status: CdrStatus.accepted,
  callee: '1000',
  calleeNumber: '1000',
  caller: '2000',
  callerNumber: '2000',
  connectTime: DateTime.utc(2026, 9, 21, 10),
  disconnectTime: DateTime.utc(2026, 9, 21, 10, 1),
  disconnectReason: 'normal',
  duration: const Duration(seconds: 60),
);

CdrHistoryPage _page(int records, {int? itemsTotal}) =>
    CdrHistoryPage(records: [for (var i = 0; i < records; i++) _record('$i')], itemsTotal: itemsTotal);

void main() {
  group('CdrHistoryPage.hasMoreAfter', () {
    test('a reported total answers it outright', () {
      expect(_page(50, itemsTotal: 137).hasMoreAfter(50), isTrue);
      expect(_page(37, itemsTotal: 137).hasMoreAfter(137), isFalse);
    });

    test('a total smaller than what was taken ends the range rather than going negative', () {
      // The archive can lose a record between two pages of the same walk.
      expect(_page(10, itemsTotal: 5).hasMoreAfter(10), isFalse);
    });

    test('without a total, any records say "ask again" and only an empty page ends it', () {
      // A backend may serve fewer per page than it was asked for, so a page
      // shorter than the request is not evidence that it was the last.
      expect(_page(50).hasMoreAfter(50), isTrue);
      expect(_page(20).hasMoreAfter(20), isTrue);
      expect(_page(0).hasMoreAfter(0), isFalse);
    });

    test('an empty page from a range that reports records still ends where the total says', () {
      expect(const CdrHistoryPage.empty().hasMoreAfter(0), isFalse);
      expect(const CdrHistoryPage(records: [], itemsTotal: 12).hasMoreAfter(0), isTrue);
    });
  });
}
