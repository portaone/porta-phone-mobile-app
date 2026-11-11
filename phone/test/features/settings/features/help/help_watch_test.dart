import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/settings/features/help/help.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../../helpers/screen_presets.dart';

void main() {
  for (final preset in watchPresets) {
    testWidgets('on $preset Help is the open-on-phone page for the brand\'s help page in the app\'s language', (
      tester,
    ) async {
      preset.apply(tester);
      expect(
        await pumpCollectingOverflows(
          tester,
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HelpScreen(initialUri: Uri.parse('https://help.example.test/watch'), userAgent: 'agent'),
          ),
        ),
        isEmpty,
      );

      final page = tester.widget<WatchOpenOnPhonePage>(find.byType(WatchOpenOnPhonePage));
      expect(page.uri, Uri.parse('https://help.example.test/watch?localeName=en'));
      expect(find.text('Help'), findsOneWidget);
      expect(find.text('Open on phone'), findsOneWidget);
    });
  }
}
