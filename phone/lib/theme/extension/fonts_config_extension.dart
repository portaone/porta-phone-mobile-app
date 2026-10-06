import 'package:theme_schema/models/models.dart';

extension FontsConfigFamily on FontsConfig {
  /// The typeface the theme names, or null when it names none.
  ///
  /// Trimmed, because the build that bundles the typeface trims the name
  /// before naming the files after it: a stray space here would otherwise
  /// make the app look for a family nobody bundled.
  String? get family {
    final name = fontFamily?.trim();
    return name == null || name.isEmpty ? null : name;
  }
}
