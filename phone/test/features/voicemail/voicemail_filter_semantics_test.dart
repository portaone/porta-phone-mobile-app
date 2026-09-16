import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/voicemail/widgets/voicemail_filter_row.dart';
import 'package:webtrit_phone/l10n/app_localizations.g.dart';
import 'package:webtrit_phone/models/models.dart';

import '../../helpers/helpers.dart';

// The control that picks which messages are shown. Its visible label is the
// filter that is on, so what a reader needs is the one thing the screen does
// not say: that this word is a control, and what it controls.
void main() {
  Widget wrap({
    required VoicemailFilter selected,
    List<VoicemailFilter> filters = VoicemailFilter.values,
    ValueChanged<VoicemailFilter>? onSelected,
  }) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: VoicemailFilterPicker(filters: filters, selected: selected, onSelected: onSelected ?? (_) {}),
      ),
    );
  }

  testWidgets('the picker is named, identified and activated through semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(selected: VoicemailFilter.all));

    expectTapTargetSemantics(
      tester,
      find.byKey(voicemailFilterPickerKey),
      label: 'Filter, currently All',
      identifier: voicemailFilterPickerId,
      isButton: true,
    );

    await tapViaSemantics(tester, find.byKey(voicemailFilterPickerKey));
    await tester.pumpAndSettle();

    expect(find.text('Trash'), findsOneWidget);

    handle.dispose();
  });

  testWidgets('the name says which filter is on, not just that there is one', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(selected: VoicemailFilter.trash));

    // Without the current value in the name, a reader announces "Filter" over
    // a list whose contents it cannot otherwise explain.
    expectTapTargetSemantics(
      tester,
      find.byKey(voicemailFilterPickerKey),
      label: 'Filter, currently Trash',
      identifier: voicemailFilterPickerId,
      isButton: true,
    );

    handle.dispose();
  });

  testWidgets('only the filters this mailbox offers are in the menu', (tester) async {
    await tester.pumpWidget(
      wrap(selected: VoicemailFilter.all, filters: const [VoicemailFilter.all, VoicemailFilter.unheard]),
    );

    await tester.tap(find.byKey(voicemailFilterPickerKey));
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsNothing);
    expect(find.text('Trash'), findsNothing);
    expect(find.text('New'), findsOneWidget);
  });

  testWidgets('picking a filter reports it', (tester) async {
    VoicemailFilter? picked;
    await tester.pumpWidget(wrap(selected: VoicemailFilter.all, onSelected: (filter) => picked = filter));

    await tester.tap(find.byKey(voicemailFilterPickerKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();

    expect(picked, VoicemailFilter.saved);
  });

  testWidgets('the whole control meets the labelled-tap-target guideline', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(selected: VoicemailFilter.saved));

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });
}
