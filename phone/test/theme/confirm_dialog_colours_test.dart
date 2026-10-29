import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/theme/models/models.dart';

/// The confirm dialog of the stock theme takes the colours the theme gives it.
///
/// Its block was once shipped under a key the app does not read, so every one
/// of its colours was dropped without a word and the dialog fell back to bare
/// Material defaults: the yes of an ordinary question took the accent, and
/// nothing tied the yes of a dangerous one to the red the rest of the app uses
/// for the same actions.
void main() {
  Map<String, dynamic> objectAt(String path) => jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  for (final appearance in ['light', 'dark']) {
    test('$appearance: the dialog block is read', () {
      final dialog = ThemeWidgetConfig.fromJson(objectAt('assets/themes/original.widget.$appearance.config.json'))
          .dialog
          .confirmDialog;

      expect(dialog.activeButtonColor1, isNotNull);
      expect(dialog.activeButtonColor2, isNotNull);
      expect(dialog.defaultButtonColor, isNotNull);
    });

    test('$appearance: a dangerous yes is the red of the scheme', () {
      // The button that signs other sessions out and each device's own
      // sign-out are drawn in the scheme's error colour; the yes that confirms
      // them must be the same red.
      final dialog = ThemeWidgetConfig.fromJson(objectAt('assets/themes/original.widget.$appearance.config.json'))
          .dialog
          .confirmDialog;
      final scheme = ColorSchemeConfig.fromJson(objectAt('assets/themes/original.color_scheme.$appearance.config.json'))
          .colorSchemeOverride;

      expect(dialog.activeButtonColor2?.toUpperCase(), scheme.error?.toUpperCase());
    });
  }
}
