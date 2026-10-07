import 'package:webtrit_phone/l10n/l10n.dart';

/// [duration] in the words a screen reader should say: "10 seconds",
/// "1 minute 5 seconds".
///
/// The player draws a length as `0:10`, which a screen reader reads out as a
/// time of day. Whole seconds, cut off the way the drawn form cuts them, so
/// what is heard is what is seen.
String spokenDuration(AppLocalizations l10n, Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  if (minutes == 0) return l10n.common_SemanticsValue_durationSeconds(seconds);
  if (seconds == 0) return l10n.common_SemanticsValue_durationMinutes(minutes);
  return l10n.common_SemanticsValue_durationMinutesSeconds(
    l10n.common_SemanticsValue_durationMinutes(minutes),
    l10n.common_SemanticsValue_durationSeconds(seconds),
  );
}
