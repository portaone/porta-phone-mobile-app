import 'package:flutter_test/flutter_test.dart';

import 'package:clock/clock.dart';

import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/l10n/app_localizations_en.g.dart';
import 'package:webtrit_phone/models/models.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final noon = DateTime(2026, 9, 21, 12);

  // A moment later today is a clock time; any other moment brings its day,
  // since two days is past midnight by definition. 24-hour, like the
  // timestamps in the conversation list the row is reached from.
  test('the line under Notifications says on, muted, or until when', () {
    withClock(Clock.fixed(noon), () {
      expect(notificationMuteSubtitle(l10n, NotificationMute.none), 'On');
      expect(notificationMuteSubtitle(l10n, const NotificationMute(muted: true)), 'Muted');
      expect(
        notificationMuteSubtitle(l10n, NotificationMute(muted: true, mutedUntil: noon.add(const Duration(hours: 6)))),
        'Muted until 18:00',
      );
      expect(
        notificationMuteSubtitle(l10n, NotificationMute(muted: true, mutedUntil: noon.add(const Duration(days: 2)))),
        'Muted until 23 Sep 12:00',
      );
    });
  });
}
