import 'package:webtrit_phone/l10n/l10n.dart';

/// A period of the inactive-sessions setting in words: the presets by their
/// names, any other number of days as days, null as never.
String sessionAutoTerminatePeriod(AppLocalizations l10n, int? days) {
  return switch (days) {
    null => l10n.sessions_AutoTerminate_never,
    7 => l10n.sessions_AutoTerminate_oneWeek,
    30 => l10n.sessions_AutoTerminate_oneMonth,
    90 => l10n.sessions_AutoTerminate_threeMonths,
    _ => l10n.sessions_AutoTerminate_days(days),
  };
}
