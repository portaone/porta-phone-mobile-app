import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/models/caller_id_settings.dart';

void main() {
  // A country is picked for one dial code: carried over to another code it
  // would show that other code as a country which does not have it.
  group('PrefixMatcher.copyWith', () {
    final canada = PrefixMatcher('+1', '100', country: 'CA');

    test('keeps the country while the dial code stays', () {
      expect(canada.copyWith(number: '200'), PrefixMatcher('+1', '200', country: 'CA'));
      expect(canada.copyWith(prefix: '+1'), canada);
    });

    test('drops the country with a new dial code', () {
      expect(canada.copyWith(prefix: '+44'), PrefixMatcher('+44', '100'));
    });

    test('takes the country that comes with a new dial code', () {
      expect(canada.copyWith(prefix: '+44', country: 'GB'), PrefixMatcher('+44', '100', country: 'GB'));
    });
  });
}
