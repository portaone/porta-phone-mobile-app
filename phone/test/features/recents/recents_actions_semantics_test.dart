import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/recents/recents.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../../helpers/helpers.dart';

void main() {
  late int confirmations;

  setUp(() => confirmations = 0);

  Widget wrap({required bool canClear, double bottomPadding = 0}) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        floatingActionButton: RecentsActionsFab(
          bottomPadding: bottomPadding,
          actions: RecentsActions(
            canClear: canClear,
            clearDescription: 'Removed on every device.',
            onClearConfirmed: () => confirmations++,
          ),
        ),
      ),
    );
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tapViaSemantics(tester, find.bySemanticsIdentifier(recentsActionsId));
    await tester.pumpAndSettle();
  }

  testWidgets('the button is named, carries its id and opens the menu', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(canClear: true));

    expectTapTargetSemantics(
      tester,
      find.bySemanticsIdentifier(recentsActionsId),
      label: 'More actions',
      identifier: recentsActionsId,
      pressArea: find.byKey(recentsActionsKey),
    );

    await openMenu(tester);

    expectTapTargetSemantics(
      tester,
      find.bySemanticsIdentifier(recentsClearHistoryActionId),
      label: 'Clear call history',
      identifier: recentsClearHistoryActionId,
    );
    handle.dispose();
  });

  testWidgets('the button stays clear of what the screen leaves beneath it', (tester) async {
    // The main screen reports its floating tab bar as the page's bottom
    // padding; the screen hands that figure to the button.
    const barHeight = 120.0;
    await tester.pumpWidget(wrap(canClear: true, bottomPadding: barHeight));
    final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;

    expect(tester.getRect(find.byKey(recentsActionsKey)).bottom, lessThanOrEqualTo(screenHeight - barHeight));
  });

  testWidgets('the entry asks before clearing, and the answer yes clears', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(canClear: true));
    await openMenu(tester);

    await tapViaSemantics(tester, find.bySemanticsIdentifier(recentsClearHistoryActionId));
    await tester.pumpAndSettle();

    expect(find.text('Clear call history?'), findsOneWidget);
    expect(find.text('Removed on every device.'), findsOneWidget);
    expect(confirmations, 0, reason: 'nothing is cleared before the answer');

    await tapViaSemantics(tester, find.bySemanticsIdentifier(confirmDialogYesButtonId));
    await tester.pumpAndSettle();

    expect(confirmations, 1);
    handle.dispose();
  });

  testWidgets('declining clears nothing', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(canClear: true));
    await openMenu(tester);
    await tapViaSemantics(tester, find.bySemanticsIdentifier(recentsClearHistoryActionId));
    await tester.pumpAndSettle();

    await tapViaSemantics(tester, find.bySemanticsIdentifier(confirmDialogNoButtonId));
    await tester.pumpAndSettle();

    expect(find.text('Clear call history?'), findsNothing);
    expect(confirmations, 0);
    handle.dispose();
  });

  testWidgets('with nothing to clear the entry is shown but cannot be picked', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(canClear: false));
    await openMenu(tester);

    expect(
      tester.getSemantics(find.bySemanticsIdentifier(recentsClearHistoryActionId)),
      isSemantics(label: 'Clear call history', identifier: recentsClearHistoryActionId, hasEnabledState: true),
    );
    expect(tester.widget<PopupMenuItem<Object?>>(find.byKey(recentsClearHistoryActionKey)).enabled, isFalse);
    handle.dispose();
  });
}
