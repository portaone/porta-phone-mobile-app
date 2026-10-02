import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';

import 'contacts_tab_harness.dart';

void main() {
  late ContactsTabHarness harness;

  final anna = buildListContact(id: 1, name: 'Anna');

  setUp(() => harness = ContactsTabHarness());

  group('the phone shares only a selection of contacts', () {
    testWidgets('the list ends with a notice and the way to change the selection', (tester) async {
      await harness.pumpLocal(tester, contacts: [anna], selectionOnly: true);

      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('Only the contacts you selected are shown'), findsOneWidget);
      expect(find.byKey(contactsLocalChangeSelectionKey), findsOneWidget);
    });

    testWidgets('an empty selection is named instead of reading as an empty phone book', (tester) async {
      await harness.pumpLocal(tester, contacts: const [], selectionOnly: true);

      expect(find.textContaining('none is selected yet'), findsOneWidget);
      expect(find.text('No contacts'), findsNothing);
      expect(find.byKey(contactsLocalChangeSelectionKey), findsOneWidget);
    });

    testWidgets('an empty selection can still be reread by hand', (tester) async {
      var refreshes = 0;
      await harness.pumpLocal(
        tester,
        contacts: const [],
        selectionOnly: true,
        refresh: () async {
          refreshes++;
        },
      );

      await tester.tap(find.text('Refresh'));
      await tester.pump();

      expect(refreshes, 1);
    });

    testWidgets('search results carry no notice', (tester) async {
      await harness.pumpLocal(tester, contacts: [anna], selectionOnly: true, searching: true);

      expect(find.byKey(contactsLocalChangeSelectionKey), findsNothing);
    });

    testWidgets('a search that finds nothing is about the query, not the selection', (tester) async {
      await harness.pumpLocal(tester, contacts: const [], selectionOnly: true, searching: true);

      expect(find.text('No contacts found'), findsOneWidget);
      expect(find.byKey(contactsLocalChangeSelectionKey), findsNothing);
    });
  });

  testWidgets('the whole address book carries no notice', (tester) async {
    await harness.pumpLocal(tester, contacts: [anna]);

    expect(find.text('Anna'), findsOneWidget);
    expect(find.byKey(contactsLocalChangeSelectionKey), findsNothing);
  });
}
