import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/l10n/app_localizations.g.dart';
import 'package:webtrit_phone/models/models.dart';

import '../../../helpers/helpers.dart';

const _kHandle = CallkeepHandle.number('+380991234567');

ActiveCall _makeCall({required String callId, required String displayName, DateTime? acceptedTime}) {
  return ActiveCall(
    callId: callId,
    direction: CallDirection.incoming,
    line: 0,
    handle: _kHandle,
    createdTime: DateTime(2024),
    video: false,
    processingStatus: CallProcessingStatus.connected,
    acceptedTime: acceptedTime,
    displayName: displayName,
  );
}

void main() {
  final ringing = _makeCall(callId: 'ringing', displayName: 'Anna Marchenko');
  final onCall = _makeCall(
    callId: 'on-call',
    displayName: 'Boris Klein',
    acceptedTime: DateTime.now().subtract(const Duration(seconds: 65)),
  );

  Widget buildSubject({
    required ValueChanged<String> onCallTap,
    bool mergeSupported = false,
    VoidCallback? onMerge,
    CallListAction? action,
  }) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CallList(
          calls: [ringing, onCall],
          focusedCallId: 'ringing',
          onCallTap: onCallTap,
          action:
              action ??
              (mergeSupported
                  ? CallListAction(
                      label: 'Merge',
                      semanticsLabel: 'Merge the calls into a conference',
                      identifier: callMergeButtonId,
                      icon: Icons.groups_outlined,
                      onPressed: onMerge,
                    )
                  : null),
        ),
      ),
    );
  }

  group('CallList - what a screen reader gets', () {
    testWidgets('every row is one named button, numbered by position', (tester) async {
      final semantics = tester.ensureSemantics();
      final tapped = <String>[];
      await tester.pumpWidget(buildSubject(onCallTap: tapped.add));

      final first = find.bySemanticsIdentifier(callRowId);
      final second = find.bySemanticsIdentifier(numberedId(callRowId, 1));

      // The name is not pinned to the letter: a row reads out what it shows,
      // and what it shows includes a duration that ticks while the test runs.
      expectTapTargetSemantics(tester, first, identifier: callRowId, isButton: true);
      expectTapTargetSemantics(tester, second, identifier: numberedId(callRowId, 1), isButton: true);
      expect(tester.getSemantics(first).getSemanticsData().label, contains('Anna Marchenko'));
      expect(tester.getSemantics(second).getSemanticsData().label, contains('Boris Klein'));

      await tapViaSemantics(tester, second);
      expect(tapped, ['on-call']);

      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });

    testWidgets('no row offers a press without saying what it is', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(buildSubject(onCallTap: (_) {}, mergeSupported: true, onMerge: () {}));

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });

    testWidgets('the header action keeps its own id and name whichever action it is', (tester) async {
      // Merge and Add are the same control in the same place; what tells them
      // apart is the id and the name, not the shape.
      final semantics = tester.ensureSemantics();
      var added = false;
      await tester.pumpWidget(
        buildSubject(
          onCallTap: (_) {},
          action: CallListAction(
            label: 'Add',
            semanticsLabel: 'Add the calls to the conference',
            identifier: callAddToConferenceButtonId,
            icon: Icons.group_add_outlined,
            onPressed: () => added = true,
          ),
        ),
      );

      final add = find.bySemanticsIdentifier(callAddToConferenceButtonId);
      expectTapTargetSemantics(
        tester,
        add,
        label: 'Add the calls to the conference',
        identifier: callAddToConferenceButtonId,
        isButton: true,
      );
      await tapViaSemantics(tester, add);
      expect(added, isTrue);

      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });

    testWidgets('Merge is one named button, and says what it does rather than what it says', (tester) async {
      final semantics = tester.ensureSemantics();
      var merged = false;
      await tester.pumpWidget(buildSubject(onCallTap: (_) {}, mergeSupported: true, onMerge: () => merged = true));

      final merge = find.bySemanticsIdentifier(callMergeButtonId);
      // The visible word is "Merge"; what a screen reader hears says which
      // calls and into what.
      expectTapTargetSemantics(
        tester,
        merge,
        label: 'Merge the calls into a conference',
        identifier: callMergeButtonId,
        isButton: true,
      );

      await tapViaSemantics(tester, merge);
      expect(merged, isTrue);

      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });
  });
}
