import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/recents/recents.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

import '../../helpers/helpers.dart';

void main() {
  const filters = [RecentsVisibilityFilter.all, RecentsVisibilityFilter.missed];

  late List<RecentsVisibilityFilter> picked;
  late int confirmations;

  setUp(() {
    picked = [];
    confirmations = 0;
  });

  Widget wrap({RecentsVisibilityFilter selected = RecentsVisibilityFilter.all, List<RecentsVisibilityFilter>? only}) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        appBar: AppBar(
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(RecentsUnifiedHeader.height),
            child: RecentsUnifiedHeader(
              filters: only ?? filters,
              selected: selected,
              onSelected: picked.add,
              actions: RecentsActions(
                canClear: true,
                clearDescription: 'Removed on this device.',
                onClearConfirmed: () => confirmations++,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the filter chooser is named, carries its id and offers the tabs by their ids', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap());

    final chooser = tester.getSemantics(find.bySemanticsIdentifier(recentsFilterPickerId));
    expect(chooser, isSemantics(hasTapAction: true, isButton: true));
    // The name and the filter shown are read together.
    expect(chooser.getSemanticsData().label, startsWith('Show calls'));

    await tapViaSemantics(tester, find.bySemanticsIdentifier(recentsFilterPickerId));
    await tester.pumpAndSettle();
    await tapViaSemantics(tester, find.bySemanticsIdentifier(RecentsVisibilityFilter.missed.tabId));
    await tester.pumpAndSettle();

    expect(picked, [RecentsVisibilityFilter.missed]);
    handle.dispose();
  });

  testWidgets('the actions button is named, carries its id and opens the clear entry', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap());

    expectTapTargetSemantics(
      tester,
      find.bySemanticsIdentifier(recentsActionsId),
      label: 'More actions',
      identifier: recentsActionsId,
      isButton: true,
      pressArea: find.byKey(recentsActionsKey),
    );

    await tapViaSemantics(tester, find.bySemanticsIdentifier(recentsActionsId));
    await tester.pumpAndSettle();
    await tapViaSemantics(tester, find.bySemanticsIdentifier(recentsClearHistoryActionId));
    await tester.pumpAndSettle();
    expect(find.text('Removed on this device.'), findsOneWidget);

    await tapViaSemantics(tester, find.bySemanticsIdentifier(confirmDialogYesButtonId));
    await tester.pumpAndSettle();
    expect(confirmations, 1);
    handle.dispose();
  });

  testWidgets('with one filter there is nothing to choose, and the actions stay', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(only: const [RecentsVisibilityFilter.all]));

    expect(find.bySemanticsIdentifier(recentsFilterPickerId), findsNothing);
    expect(find.bySemanticsIdentifier(recentsActionsId), findsOneWidget);
    handle.dispose();
  });
}
