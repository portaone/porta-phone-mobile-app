import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/settings/features/sessions/view/widgets/widgets.dart';
import 'package:webtrit_phone/models/models.dart';

import 'sessions_auto_terminate_harness.dart';

const _default90 = SessionAutoTerminate(inactivityTimeoutDays: 90, installationMaxDays: 90);

Finder _option(String value) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.identifier == sessionAutoTerminateOptionId(value),
);

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(sessionsAutoTerminateKey));
  await tester.pumpAndSettle();
}

void main() {
  group('the row', () {
    testWidgets('shows the period in force above the sessions', (tester) async {
      await SessionsAutoTerminateHarness(const SessionAutoTerminate(inactivityTimeoutDays: 30, installationMaxDays: 90))
          .pump(tester);

      expect(find.text('End inactive sessions'), findsOneWidget);
      expect(find.text('1 month'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(sessionsAutoTerminateKey)).dy,
        lessThan(tester.getTopLeft(find.text('This device')).dy),
      );
    });

    testWidgets('names a period of another client in days', (tester) async {
      await SessionsAutoTerminateHarness(const SessionAutoTerminate(inactivityTimeoutDays: 45, installationMaxDays: 90))
          .pump(tester);

      expect(find.text('45 days'), findsOneWidget);
    });

    testWidgets('says never where sessions never end', (tester) async {
      await SessionsAutoTerminateHarness(const SessionAutoTerminate()).pump(tester);

      expect(find.text('Never'), findsOneWidget);
    });

    testWidgets('is absent where the core does not end idle sessions', (tester) async {
      await SessionsAutoTerminateHarness(null).pump(tester);

      expect(find.byKey(sessionsAutoTerminateKey), findsNothing);
      expect(find.text('This device'), findsOneWidget);
    });

    testWidgets('only states the period where the user cannot choose', (tester) async {
      await SessionsAutoTerminateHarness(_default90, selectable: false).pump(tester);

      expect(find.text('Inactive sessions end after 90 days'), findsOneWidget);
      expect(find.byKey(sessionsAutoTerminateKey), findsNothing);
    });

    testWidgets('says nothing where the user cannot choose and sessions never end', (tester) async {
      await SessionsAutoTerminateHarness(const SessionAutoTerminate(), selectable: false).pump(tester);

      expect(find.textContaining('Inactive sessions'), findsNothing);
      expect(find.byKey(sessionsAutoTerminateKey), findsNothing);
    });
  });

  group('the sheet', () {
    testWidgets('offers the default, the presets under the limit, other, and the note', (tester) async {
      await SessionsAutoTerminateHarness(_default90).pump(tester);
      await _openSheet(tester);

      expect(find.text('Default (3 months)'), findsOneWidget);
      expect(_option('days7'), findsOneWidget);
      expect(_option('days30'), findsOneWidget);
      expect(_option('days90'), findsNothing);
      expect(_option('other'), findsOneWidget);
      expect(
        find.text(
          'Sessions inactive for longer than 90 days are ended automatically. This limit is set by your administrator.',
        ),
        findsOneWidget,
      );
      expect(tester.widget<ListTile>(find.widgetWithText(ListTile, 'Default (3 months)')).selected, isTrue);
    });

    testWidgets('without an installation limit: never as the default, all presets, no note', (tester) async {
      await SessionsAutoTerminateHarness(const SessionAutoTerminate()).pump(tester);
      await _openSheet(tester);

      expect(find.text('Default (Never)'), findsOneWidget);
      expect(_option('days90'), findsOneWidget);
      expect(find.textContaining('administrator'), findsNothing);
    });

    testWidgets('keeps a period of another client as a selected row of its own', (tester) async {
      await SessionsAutoTerminateHarness(const SessionAutoTerminate(inactivityTimeoutDays: 45, installationMaxDays: 90))
          .pump(tester);
      await _openSheet(tester);

      expect(_option('current'), findsOneWidget);
      expect(tester.widget<ListTile>(find.widgetWithText(ListTile, '45 days').last).selected, isTrue);
    });

    testWidgets('a limit under a week leaves the default and other only', (tester) async {
      await SessionsAutoTerminateHarness(const SessionAutoTerminate(inactivityTimeoutDays: 5, installationMaxDays: 5))
          .pump(tester);
      await _openSheet(tester);

      expect(find.text('Default (5 days)'), findsOneWidget);
      expect(_option('days7'), findsNothing);
      expect(_option('other'), findsOneWidget);
    });

    testWidgets('a preset is saved at once and the sheet closes on the answer', (tester) async {
      final harness = SessionsAutoTerminateHarness(_default90);
      await harness.pump(tester);
      harness.repository.gate = Completer<void>();
      await _openSheet(tester);

      await tester.tap(find.text('1 week'));
      await tester.pump();

      expect(harness.repository.puts, [7]);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Default (3 months)'), findsOneWidget, reason: 'the sheet waits for the core');

      harness.repository.gate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Default (3 months)'), findsNothing);
      expect(find.text('1 week'), findsOneWidget);
    });

    testWidgets('the default is saved as null', (tester) async {
      final harness = SessionsAutoTerminateHarness(
        const SessionAutoTerminate(inactivityTimeoutDays: 7, installationMaxDays: 90),
      );
      await harness.pump(tester);
      await _openSheet(tester);

      await tester.tap(find.text('Default (3 months)'));
      await tester.pumpAndSettle();

      expect(harness.repository.puts, [null]);
      expect(find.text('3 months'), findsOneWidget);
    });

    testWidgets('picking the period in force again asks nothing of the core', (tester) async {
      final harness = SessionsAutoTerminateHarness(_default90);
      await harness.pump(tester);
      await _openSheet(tester);

      await tester.tap(find.text('Default (3 months)'));
      await tester.pumpAndSettle();

      expect(harness.repository.puts, isEmpty);
      expect(find.text('Default (3 months)'), findsNothing);
    });

    testWidgets('other takes a number of days within the limit', (tester) async {
      final harness = SessionsAutoTerminateHarness(_default90);
      await harness.pump(tester);
      await _openSheet(tester);

      await tester.tap(find.text('Other…'));
      await tester.pumpAndSettle();
      // A page of the sheet itself takes the place of the list, not a dialog over it.
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Custom period'), findsOneWidget);
      expect(_option('default'), findsNothing);
      expect(
        find.descendant(of: find.byType(SessionAutoTerminateSheet), matching: find.byType(TextField)),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), '120');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(tester.widget<TextField>(find.byType(TextField)).decoration!.errorText, 'From 1 to 90');
      expect(harness.repository.puts, isEmpty);

      await tester.enterText(find.byType(TextField), '14');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(harness.repository.puts, [14]);
      expect(find.text('14 days'), findsOneWidget);
    });
    testWidgets('back from other returns to the list and saves nothing', (tester) async {
      final harness = SessionsAutoTerminateHarness(_default90);
      await harness.pump(tester);
      await _openSheet(tester);

      await tester.tap(find.text('Other…'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '14');
      await tester.tap(find.bySemanticsIdentifier(sessionsAutoTerminateOtherBackId));
      await tester.pumpAndSettle();

      expect(find.byType(SessionAutoTerminateSheet), findsOneWidget);
      expect(_option('default'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      // The system back on the page does the same rather than closing the sheet.
      await tester.tap(find.text('Other…'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(SessionAutoTerminateSheet), findsOneWidget);
      expect(_option('default'), findsOneWidget);
      expect(harness.repository.puts, isEmpty);
    });
  });

  group('a refused or failed save', () {
    testWidgets('keeps the period and offers to try again', (tester) async {
      final harness = SessionsAutoTerminateHarness(_default90);
      await harness.pump(tester);
      harness.repository.failure = Exception('503 external_api_issue');
      await _openSheet(tester);

      await tester.tap(find.text('1 week'));
      await tester.pumpAndSettle();

      expect(find.text('Could not change when inactive sessions end'), findsOneWidget);
      expect(find.text('3 months'), findsOneWidget);

      harness.repository.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(harness.repository.puts, [7, 7]);
      expect(find.text('1 week'), findsOneWidget);
    });

    testWidgets('a newer choice that is saved takes the old try again away', (tester) async {
      final harness = SessionsAutoTerminateHarness(_default90);
      await harness.pump(tester);
      harness.repository.failure = Exception('503 external_api_issue');
      await _openSheet(tester);
      await tester.tap(find.text('1 week'));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);

      harness.repository.failure = null;
      await _openSheet(tester);
      await tester.tap(find.text('1 month'));
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsNothing);
      expect(harness.repository.puts, [7, 30]);
      expect(find.text('1 month'), findsOneWidget);
    });

    testWidgets('a save leaves an unrelated revoke failure on screen', (tester) async {
      final harness = SessionsAutoTerminateHarness(
        _default90,
        sessions: const [
          ActiveSession(id: 'a', current: true),
          ActiveSession(id: 'b', current: false),
        ],
      );
      harness.repository.revokeFailure = Exception('offline');
      await harness.pump(tester);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      expect(find.text('Could not sign out the session'), findsOneWidget);

      await _openSheet(tester);
      await tester.tap(find.text('1 week'));
      await tester.pumpAndSettle();

      expect(find.text('Could not sign out the session'), findsOneWidget);
      expect(harness.repository.puts, [7]);
    });

    testWidgets('trying again after leaving the screen asks nothing of the core', (tester) async {
      final harness = SessionsAutoTerminateHarness(_default90);
      await harness.pump(tester);
      harness.repository.failure = Exception('503 external_api_issue');
      await _openSheet(tester);
      await tester.tap(find.text('1 week'));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);

      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .pushReplacement(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Elsewhere'))));
      await tester.pumpAndSettle();
      expect(find.text('Elsewhere'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget, reason: 'the snack bar outlives the screen');

      harness.repository.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(harness.repository.puts, [7]);
    });

    testWidgets('a failure is said even when the sheet was dragged away while the core was asked', (tester) async {
      final harness = SessionsAutoTerminateHarness(_default90);
      await harness.pump(tester);
      harness.repository
        ..gate = Completer<void>()
        ..failure = Exception('503 external_api_issue');
      await _openSheet(tester);

      await tester.tap(find.text('1 week'));
      await tester.pump();
      await tester.drag(find.text('Default (3 months)'), const Offset(0, 800));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.text('Default (3 months)'), findsNothing, reason: 'the drag closed the sheet');

      harness.repository.gate!.complete();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text('Could not change when inactive sessions end'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('3 months'), findsOneWidget);
    });

    testWidgets('a lowered limit says so and shows the new one', (tester) async {
      final harness = SessionsAutoTerminateHarness(_default90);
      await harness.pump(tester);
      harness.repository.refusal = SessionAutoTerminateRefusal.exceedsInstallationLimit;
      await _openSheet(tester);
      harness.repository.autoTerminate = const SessionAutoTerminate(inactivityTimeoutDays: 14, installationMaxDays: 14);

      await tester.tap(find.text('1 month'));
      await tester.pumpAndSettle();

      expect(find.text('Your administrator has changed the limit. Choose the period again.'), findsOneWidget);
      expect(find.text('14 days'), findsOneWidget);
    });
  });
}
