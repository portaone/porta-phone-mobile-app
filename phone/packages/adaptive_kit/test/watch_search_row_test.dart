import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_kit/adaptive_kit.dart';

import 'helpers/screen_presets.dart';

void main() {
  late List<String> changes;

  setUp(() => changes = []);

  Widget row({bool chooser = true, String query = ''}) => MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: WatchSearchRow(
          initialQuery: query,
          onChanged: changes.add,
          chooser: chooser
              ? ({required round}) => round
                    ? WatchRoundButton(
                        identifier: 'list',
                        label: 'Book',
                        icon: const Icon(Icons.book),
                        size: WatchPill.height,
                        width: WatchPill.height,
                        onPressed: () {},
                      )
                    : WatchPillButton(identifier: 'list', label: 'Book', semanticsLabel: 'Book', onPressed: () {})
              : null,
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
    testWidgets('on $preset with no query: a round search and the chooser as a pill, in one row', (tester) async {
      preset.apply(tester);
      expect(await pumpCollectingOverflows(tester, row()), isEmpty);

      final search = tester.getRect(find.bySemanticsIdentifier('search'));
      final list = tester.getRect(find.bySemanticsIdentifier('list'));
      expect((search.center.dy - list.center.dy).abs(), lessThan(1));
      expect(search.width, closeTo(WatchPill.height, 1));
      expect(list.width, greaterThan(search.width));
    });

    testWidgets('on $preset with a query: the query as a pill with its cross, the chooser round', (tester) async {
      preset.apply(tester);
      expect(await pumpCollectingOverflows(tester, row(query: 'smi')), isEmpty);

      expect(find.text('smi'), findsWidgets);
      expect(find.bySemanticsIdentifier('clear'), findsOneWidget);
      expect(tester.getRect(find.bySemanticsIdentifier('list')).width, closeTo(WatchPill.height, 1));
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

  testWidgets('with nothing to choose the search takes the row as a pill', (tester) async {
    watchPresets.first.apply(tester);
    await tester.pumpWidget(row(chooser: false));

    expect(find.bySemanticsIdentifier('list'), findsNothing);
    expect(find.text('Search'), findsOneWidget);
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
