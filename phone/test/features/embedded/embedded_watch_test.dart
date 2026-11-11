import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/embedded/embedded.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/screen_presets.dart';

void main() {
  Widget app(Widget home) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  for (final preset in watchPresets) {
    testWidgets('on $preset a page on the network opens on the phone, under its configured name', (tester) async {
      preset.apply(tester);
      expect(
        await pumpCollectingOverflows(
          tester,
          app(
            EmbeddedScreenPage(
              data: EmbeddedData(
                id: 'terms',
                uri: Uri.parse('https://example.test/terms'),
                titleL10n: 'settings_ListViewTileTitle_termsConditions',
                reconnectStrategy: ReconnectStrategy.softReload,
              ),
            ),
          ),
        ),
        isEmpty,
      );

      final page = tester.widget<WatchOpenOnPhonePage>(find.byType(WatchOpenOnPhonePage));
      expect(page.uri, Uri.parse('https://example.test/terms'));
      expect(find.text('Terms and conditions'), findsOneWidget);
    });
  }

  testWidgets('a page built into the app says to open it in the app on the phone; no button', (tester) async {
    watchPresets.first.apply(tester);
    await tester.pumpWidget(app(EmbeddedWatchPage(title: 'Billing', uri: Uri.parse('asset://assets/billing.html'))));

    expect(find.byType(WatchOpenOnPhonePage), findsNothing);
    expect(find.text('Open it in the app on your phone'), findsOneWidget);
    expect(find.byType(WatchEdgeButton), findsNothing);
  });

  testWidgets('a page with no name is called by its host', (tester) async {
    watchPresets.first.apply(tester);
    await tester.pumpWidget(app(EmbeddedWatchPage(title: null, uri: Uri.parse('https://billing.example.test/me'))));

    expect(find.text('billing.example.test'), findsOneWidget);
  });

  testWidgets('a page built into the app with no name is not called by its folder', (tester) async {
    watchPresets.first.apply(tester);
    await tester.pumpWidget(app(EmbeddedWatchPage(title: null, uri: Uri.parse('asset://assets/billing.html'))));

    expect(find.text('Open it in the app on your phone'), findsOneWidget);
    expect(find.text('assets'), findsNothing);
  });

  testWidgets('a page of no scheme the app loads says to open it on the phone rather than failing', (tester) async {
    watchPresets.first.apply(tester);
    await tester.pumpWidget(app(EmbeddedWatchPage(title: 'Billing', uri: Uri.parse('ftp://example.test/billing'))));

    expect(tester.takeException(), isNull);
    expect(find.text('Open it in the app on your phone'), findsOneWidget);
  });

  testWidgets('a section at the root sent to the phone offers sending again, having nowhere to go back to', (
    tester,
  ) async {
    watchPresets.first.apply(tester);
    var sent = 0;
    await tester.pumpWidget(
      app(
        WatchOpenOnPhonePage(
          title: 'Billing',
          uri: Uri.parse('https://billing.example.test/me'),
          opener: (_) async {
            sent++;
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.text('Open on phone'));
    await tester.pump();
    expect(find.text('Check your phone'), findsOneWidget);

    await tester.pump(WatchOpenOnPhonePage.sentFor);
    await tester.pumpAndSettle();
    expect(find.text('Open on phone'), findsOneWidget);

    await tester.tap(find.text('Open on phone'));
    await tester.pump();
    expect(sent, 2);
    await tester.pump(WatchOpenOnPhonePage.sentFor);
    await tester.pumpAndSettle();
  });
}
