import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/settings/features/about/widgets/widgets.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('a value carries its identifier without the caption above it', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      wrap(const InfoTile(label: 'App session identifier', value: 'abc-123', valueIdentifier: 'sessionValue')),
    );

    final data = tester.getSemantics(find.bySemanticsIdentifier('sessionValue')).getSemanticsData();
    expect(data.label, 'abc-123');
    // The copy goes with the value, not with the caption above it.
    expect(data.customSemanticsActionIds, isNotEmpty);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });

  testWidgets('the Core address is readable by its identifier', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      wrap(CoreInfoTile(coreUrl: Uri.parse('https://core.example.com'), coreVersion: null, progress: false)),
    );

    final data = tester.getSemantics(find.bySemanticsIdentifier(aboutCoreUrlId)).getSemanticsData();
    expect(data.label, 'https://core.example.com');
    expect(data.customSemanticsActionIds, isNotEmpty);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });
}
