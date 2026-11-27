import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_kit/adaptive_kit.dart';

import 'helpers/screen_presets.dart';

void main() {
  const field = Key('field');

  Widget page({required List<String> changes, String initialQuery = ''}) => MaterialApp(
    home: Scaffold(
      body: WatchPageSearch(
        initialQuery: initialQuery,
        onChanged: changes.add,
        fieldKey: field,
        // Two shapes of the page, as a list that the query empties turns into
        // a page of another kind; the search on the edge of both.
        builder: (context, search) => WatchScrollList.builder(
          title: 'Contacts',
          itemCount: search.query == 'Annx' ? 0 : 2,
          itemBuilder: (context, index) => WatchListTile(title: 'Ann $index'),
          edge: (context, overlay) => WatchSearchEdgeButton(
            overlay: overlay,
            search: search,
            label: 'Search contacts',
            identifier: 'search-id',
          ),
        ),
      ),
    ),
  );

  testWidgets('the edge opens the keyboard and shows the query; the field outlives the page changing shape', (
    tester,
  ) async {
    watchPresets.first.apply(tester);
    final changes = <String>[];
    await tester.pumpWidget(page(changes: changes));

    final edge = find.byType(WatchEdgeButton);
    expect(find.descendant(of: edge, matching: find.text('Search contacts')), findsOneWidget);
    await tester.tap(find.descendant(of: edge, matching: find.byType(OutlinedButton)));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    final editable = tester.state(find.byType(EditableText));

    tester.testTextInput.enterText('Ann');
    await tester.pump();
    expect(changes, ['Ann']);
    expect(find.descendant(of: edge, matching: find.text('Ann')), findsOneWidget);

    tester.testTextInput.enterText('Annx');
    await tester.pump();
    expect(find.byType(WatchListTile), findsNothing);
    expect(tester.state(find.byType(EditableText)), same(editable));
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('a screen reader hears the search by its name, and the query after it', (tester) async {
    watchPresets.first.apply(tester);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(page(changes: [], initialQuery: 'Ann'));

    final edge = find.bySemanticsIdentifier('search-id');
    expect(tester.getSemantics(edge).getSemanticsData().label, 'Search contacts: Ann');
    handle.dispose();
  });
}
