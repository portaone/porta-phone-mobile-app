import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/voicemail/utils/utils.dart';
import 'package:webtrit_phone/l10n/app_localizations_en.g.dart';
import 'package:webtrit_phone/l10n/app_localizations_uk.g.dart';

// What a screen reader is given instead of the drawn `m:ss`.
void main() {
  group('English', () {
    final l10n = AppLocalizationsEn();

    test('seconds alone below a minute', () {
      expect(spokenDuration(l10n, Duration.zero), '0 seconds');
      expect(spokenDuration(l10n, const Duration(seconds: 1)), '1 second');
      expect(spokenDuration(l10n, const Duration(seconds: 10)), '10 seconds');
    });

    test('cuts a part of a second off, as the drawn form does', () {
      expect(spokenDuration(l10n, const Duration(milliseconds: 10783)), '10 seconds');
    });

    test('minutes alone on a whole minute, both otherwise', () {
      expect(spokenDuration(l10n, const Duration(minutes: 1)), '1 minute');
      expect(spokenDuration(l10n, const Duration(minutes: 2, seconds: 5)), '2 minutes 5 seconds');
      expect(spokenDuration(l10n, const Duration(minutes: 75, seconds: 1)), '75 minutes 1 second');
    });

    test('a position is said of a length', () {
      expect(l10n.voicemail_SemanticsValue_playbackPosition('5 seconds', '10 seconds'), '5 seconds of 10 seconds');
    });
  });

  group('Ukrainian', () {
    final l10n = AppLocalizationsUk();

    test('takes the form its number asks for', () {
      expect(spokenDuration(l10n, const Duration(seconds: 1)), '1 секунда');
      expect(spokenDuration(l10n, const Duration(seconds: 3)), '3 секунди');
      expect(spokenDuration(l10n, const Duration(seconds: 5)), '5 секунд');
      expect(spokenDuration(l10n, const Duration(seconds: 21)), '21 секунда');
      expect(spokenDuration(l10n, const Duration(minutes: 2, seconds: 11)), '2 хвилини 11 секунд');
    });
  });
}
