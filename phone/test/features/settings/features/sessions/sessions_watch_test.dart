import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../../helpers/helpers.dart';
import '../../../../helpers/screen_presets.dart';
import 'sessions_auto_terminate_harness.dart';

final _sessions = [
  ActiveSession(id: 'watch', current: true, lastActivityAt: DateTime.now()),
  ActiveSession(id: 'pixel', current: false, location: 'Kyiv', lastActivityAt: DateTime.now()),
  ActiveSession(id: 'web', current: false, lastActivityAt: DateTime.now()),
];

const _autoTerminate = SessionAutoTerminate(inactivityTimeoutDays: 30, installationMaxDays: 90);

void main() {
  Finder list() => find.byType(Scrollable).last;

  for (final preset in watchPresets) {
    testWidgets('on $preset the period, this device and the others; Sign out others on the edge', (tester) async {
      preset.apply(tester);
      final harness = SessionsAutoTerminateHarness(_autoTerminate, sessions: _sessions);
      await harness.pump(tester);
      expect(tester.takeException(), isNull);

      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Sign out others'), findsOneWidget);
      expect(find.text('End inactive sessions'), findsOneWidget);
    });
  }

  testWidgets('this device is tinted and takes no tap; another device is signed out after the watch confirm', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    final harness = SessionsAutoTerminateHarness(_autoTerminate, sessions: _sessions);
    await harness.pump(tester);

    await tester.scrollUntilVisible(find.bySemanticsIdentifier(sessionsCurrentTileId), 40, scrollable: list());
    final current = tester.widget<WatchListTile>(find.byWidgetPredicate((w) => w is WatchListTile && w.readOnly));
    expect(current.selected, isTrue);
    expect(current.readOnly, isTrue);
    expect(current.onTap, isNull);

    await tester.scrollUntilVisible(find.bySemanticsIdentifier(numberedId(sessionsTileId, 0)), 40, scrollable: list());
    await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(sessionsTileId, 0)));
    await tester.pumpAndSettle();
    expect(find.byType(WatchConfirm), findsOneWidget);
    await tester.tap(find.byKey(confirmDialogYesButtonKey));
    await tester.pumpAndSettle();

    expect(harness.repository.revoked, ['pixel']);
    handle.dispose();
  });

  testWidgets('Sign out others asks first, then signs every other device out', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    final harness = SessionsAutoTerminateHarness(_autoTerminate, sessions: _sessions);
    await harness.pump(tester);

    await tapViaSemantics(tester, find.bySemanticsIdentifier(sessionsRevokeAllOthersButtonId));
    await tester.pumpAndSettle();
    expect(find.byType(WatchConfirm), findsOneWidget);
    await tester.tap(find.byKey(confirmDialogYesButtonKey));
    await tester.pumpAndSettle();

    expect(harness.repository.revoked, containsAll(['pixel', 'web']));
    handle.dispose();
  });

  testWidgets('the period opens its choice page; a preset is saved and the page goes back', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    final harness = SessionsAutoTerminateHarness(_autoTerminate, sessions: _sessions);
    await harness.pump(tester);

    await tapViaSemantics(tester, find.bySemanticsIdentifier(sessionsAutoTerminateId));
    await tester.pumpAndSettle();
    expect(find.text('Default (3 months)'), findsOneWidget);
    final month = find.widgetWithText(WatchListTile, '1 month');
    expect(tester.widget<WatchListTile>(month).selected, isTrue);

    await tapViaSemantics(
      tester,
      find.bySemanticsIdentifier(settingsOptionId(sessionsAutoTerminateOptionIdPrefix, 'days7')),
    );
    await tester.pumpAndSettle();

    expect(harness.repository.puts, [7]);
    expect(find.text('Sign out others'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('with no period in force nothing is marked, and Default can be chosen', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    const none = SessionAutoTerminate(inactivityTimeoutDays: null, installationMaxDays: 90);
    final harness = SessionsAutoTerminateHarness(none, sessions: _sessions);
    await harness.pump(tester);

    await tapViaSemantics(tester, find.bySemanticsIdentifier(sessionsAutoTerminateId));
    await tester.pumpAndSettle();
    expect(tester.widgetList<WatchListTile>(find.byType(WatchListTile)).where((tile) => tile.selected), isEmpty);

    await tapViaSemantics(
      tester,
      find.bySemanticsIdentifier(settingsOptionId(sessionsAutoTerminateOptionIdPrefix, 'default')),
    );
    await tester.pumpAndSettle();
    expect(harness.repository.puts, [null]);
    handle.dispose();
  });

  testWidgets('where the period cannot be chosen it is stated in a line', (tester) async {
    watchPresets.last.apply(tester);
    final harness = SessionsAutoTerminateHarness(_autoTerminate, sessions: _sessions, selectable: false);
    await harness.pump(tester);

    expect(find.textContaining('30 days'), findsOneWidget);
    expect(find.bySemanticsIdentifier(sessionsAutoTerminateId), findsNothing);
  });

  testWidgets('with no other device there is nothing to sign out: no edge button', (tester) async {
    watchPresets.last.apply(tester);
    final harness = SessionsAutoTerminateHarness(_autoTerminate, sessions: [_sessions.first]);
    await harness.pump(tester);

    expect(find.text('Sign out others'), findsNothing);
  });

  testWidgets('with no session at all the empty page offers Refresh', (tester) async {
    watchPresets.last.apply(tester);
    final harness = SessionsAutoTerminateHarness(_autoTerminate, sessions: const []);
    await harness.pump(tester);

    expect(find.text('Refresh'), findsOneWidget);
  });
}
