import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_kit/adaptive_kit.dart';

import 'helpers/screen_presets.dart';

void main() {
  late List<String> changes;

  setUp(() => changes = []);

  Widget row({String query = ''}) => MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: WatchSearchRow(
          initialQuery: query,
          onChanged: changes.add,
          searchLabel: 'Search',
          clearLabel: 'Clear',
          fieldKey: const Key('field'),
          searchIdentifier: 'search',
          clearIdentifier: 'clear',
        ),
      ),
    ),
  );

  bool focused(WidgetTester tester) => tester.widget<TextField>(find.byKey(const Key('field'))).focusNode!.hasFocus;

  for (final preset in watchPresets) {
    testWidgets('on $preset the search takes the row: its name, or the query with its cross', (tester) async {
      preset.apply(tester);
      expect(await pumpCollectingOverflows(tester, row()), isEmpty);
      expect(find.text('Search'), findsOneWidget);
      expect(find.bySemanticsIdentifier('clear'), findsNothing);

      // A field of its own: the query a row starts with is read once.
      await tester.pumpWidget(const SizedBox());
      expect(await pumpCollectingOverflows(tester, row(query: 'smi')), isEmpty);
      expect(find.text('smi'), findsWidgets);
      expect(find.bySemanticsIdentifier('clear'), findsOneWidget);
    });
  }

  testWidgets('the search button opens the keyboard field; typing narrows, the cross clears', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    await tester.pumpWidget(row());

    await tester.tap(find.bySemanticsIdentifier('search'));
    await tester.pump();
    expect(focused(tester), isTrue);

    await tester.enterText(find.byKey(const Key('field')), 'ja');
    await tester.pump();
    expect(changes.last, 'ja');
    expect(find.bySemanticsIdentifier('clear'), findsOneWidget);

    await tester.tap(find.bySemanticsIdentifier('clear'));
    await tester.pump();
    expect(changes.last, '');
    expect(find.bySemanticsIdentifier('clear'), findsNothing);
    handle.dispose();
  });

  testWidgets('a route over the row takes the focus with it: closing it brings no keyboard back', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    await tester.pumpWidget(row());
    await tester.tap(find.bySemanticsIdentifier('search'));
    await tester.pump();
    expect(focused(tester), isTrue);

    final context = tester.element(find.byType(WatchSearchRow));
    unawaited(showDialog<void>(context: context, builder: (_) => const Text('over')));
    await tester.pumpAndSettle();
    Navigator.of(context).pop();
    await tester.pumpAndSettle();

    expect(focused(tester), isFalse);
    handle.dispose();
  });
}
