import 'package:intl/intl.dart';

import 'package:webtrit_phone/l10n/l10n.dart';

/// Formats a byte count into a short human-readable size in the language of
/// [l10n]: its units ("KB", "Ko", "КБ") and its decimal separator ("2.0",
/// "2,0").
String formatBytes(int bytes, AppLocalizations l10n) {
  final number = NumberFormat('0.0', l10n.localeName);
  if (bytes < 1024) return l10n.cacheManagement_Label_sizeBytes('$bytes');

  final units = [
    l10n.cacheManagement_Label_sizeKilobytes,
    l10n.cacheManagement_Label_sizeMegabytes,
    l10n.cacheManagement_Label_sizeGigabytes,
  ];
  var value = bytes.toDouble();
  var unit = -1;
  do {
    value /= 1024;
    unit++;
    // Sizes just below a boundary would round to a nonsensical '1024.0 KB';
    // roll them over to the next unit instead.
  } while (unit < units.length - 1 && double.parse(value.toStringAsFixed(1)) >= 1024);

  return units[unit](number.format(value));
}
