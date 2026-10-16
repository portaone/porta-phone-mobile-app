import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/settings/features/sessions/view/widgets/widgets.dart';
import 'package:webtrit_phone/models/models.dart';

import '../../../../helpers/helpers.dart';
import 'sessions_auto_terminate_harness.dart';

const _default90 = SessionAutoTerminate(inactivityTimeoutDays: 90, installationMaxDays: 90);

void main() {
  group('when idle sessions end', () {
    testWidgets('the row is named by what it sets and what it is set to, and opens the sheet', (tester) async {
      await SessionsAutoTerminateHarness(_default90).pump(tester);
      final handle = tester.ensureSemantics();

      final finder = find.bySemanticsIdentifier(sessionsAutoTerminateId);
      expectTapTargetSemantics(
        tester,
        finder,
        label: 'End inactive sessions\n3 months',
        identifier: sessionsAutoTerminateId,
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await tapViaSemantics(tester, finder);
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier(sessionsAutoTerminateSheetId), findsOneWidget);

      handle.dispose();
    });

    testWidgets('each choice of the sheet is a named control that saves through semantics', (tester) async {
      final harness = SessionsAutoTerminateHarness(_default90);
      await harness.pump(tester);
      final handle = tester.ensureSemantics();
      await tapViaSemantics(tester, find.bySemanticsIdentifier(sessionsAutoTerminateId));
      await tester.pumpAndSettle();

      for (final (value, label) in [
        ('default', 'Default (3 months)'),
        ('days7', '1 week'),
        ('days30', '1 month'),
        ('other', 'Other…'),
      ]) {
        final id = sessionAutoTerminateOptionId(value);
        expectTapTargetSemantics(tester, find.bySemanticsIdentifier(id), label: label, identifier: id);
      }
      expect(
        tester.getSemantics(find.bySemanticsIdentifier(sessionAutoTerminateOptionId('default'))),
        isSemantics(isSelected: true),
      );
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await tapViaSemantics(tester, find.bySemanticsIdentifier(sessionAutoTerminateOptionId('days7')));
      await tester.pumpAndSettle();
      expect(harness.repository.puts, [7]);

      handle.dispose();
    });

    testWidgets('the page of other: its back arrow, field and save button are named nodes', (tester) async {
      final harness = SessionsAutoTerminateHarness(_default90);
      await harness.pump(tester);
      final handle = tester.ensureSemantics();
      await tapViaSemantics(tester, find.bySemanticsIdentifier(sessionsAutoTerminateId));
      await tester.pumpAndSettle();
      await tapViaSemantics(tester, find.bySemanticsIdentifier(sessionAutoTerminateOptionId('other')));
      await tester.pumpAndSettle();

      final back = find.bySemanticsIdentifier(sessionsAutoTerminateOtherBackId);
      expectTapTargetSemantics(tester, back, tooltip: 'Back', identifier: sessionsAutoTerminateOtherBackId);
      expect(
        tester.getSemantics(find.bySemanticsIdentifier(sessionsAutoTerminateOtherInputId)),
        isSemantics(identifier: sessionsAutoTerminateOtherInputId, isTextField: true),
      );
      await tester.enterText(find.bySemanticsIdentifier(sessionsAutoTerminateOtherInputId), '14');

      final save = find.bySemanticsIdentifier(sessionsAutoTerminateOtherSaveId);
      expectTapTargetSemantics(tester, save, label: 'Save', identifier: sessionsAutoTerminateOtherSaveId);
      await tapViaSemantics(tester, save);
      await tester.pumpAndSettle();
      expect(harness.repository.puts, [14]);

      handle.dispose();
    });

    testWidgets('where the user cannot choose, the period is a line with an id and no action', (tester) async {
      await SessionsAutoTerminateHarness(_default90, selectable: false).pump(tester);
      final handle = tester.ensureSemantics();

      final finder = find.bySemanticsIdentifier(sessionsAutoTerminateInfoId);
      expect(
        tester.getSemantics(finder),
        isSemantics(label: 'Inactive sessions end after 90 days', hasTapAction: false),
      );

      handle.dispose();
    });
  });
}
