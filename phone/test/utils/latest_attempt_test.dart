import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/utils/latest_attempt.dart';

void main() {
  group('LatestAttempt', () {
    test('an attempt is the latest until another begins', () {
      final attempts = LatestAttempt();

      final first = attempts.begin();
      expect(attempts.latest, first);
      expect(attempts.isLatest(first), isTrue);

      final second = attempts.begin();
      expect(attempts.isLatest(first), isFalse);
      expect(attempts.isLatest(second), isTrue);
    });

    test('numbers no attempt before the first begins', () {
      final attempts = LatestAttempt();

      expect(attempts.latest, 0);
      expect(attempts.isLatest(1), isFalse);
    });
  });
}
