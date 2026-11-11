import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/notifications/notifications.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../../helpers/screen_presets.dart';

void main() {
  for (final preset in watchPresets) {
    testWidgets('on $preset the error\'s title and its fields as rows; no share, no log console', (tester) async {
      preset.apply(tester);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ErrorDetailsScreen(
            title: 'Request failed',
            fields: [ErrorFieldModel('Status code', '503'), ErrorFieldModel('Request id', 'F6x2-91aa-07')],
          ),
        ),
      );

      expect(find.text('Request failed'), findsOneWidget);
      expect(find.text('Status code'), findsOneWidget);
      expect(find.text('503'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsNothing);
      expect(find.text('Log records console', skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
