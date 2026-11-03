import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';

import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class _NoHistory implements AutocompleteHistoryRepository {
  @override
  List<String> getHistory(String key) => const [];

  @override
  Future<void> addToHistory(String key, String value, {int maxItems = 8}) async {}
}

class _RecordedHistory implements AutocompleteHistoryRepository {
  final saved = <String>[];

  @override
  List<String> getHistory(String key) => saved;

  @override
  Future<void> addToHistory(String key, String value, {int maxItems = 8}) async => saved.add(value);
}

void main() {
  Widget field(String value) {
    return MaterialApp(
      home: Scaffold(
        body: Provider<AutocompleteHistoryRepository>.value(
          value: _NoHistory(),
          child: HistoryAutocompleteField(storageKey: 'recent', labelText: 'Address', initialValue: value),
        ),
      ),
    );
  }

  testWidgets('typing survives the screen catching up with an older value', (tester) async {
    await tester.pumpWidget(field('http://192.168.0.9'));

    // The screen feeds this field from state it updates on every keystroke, so
    // it is always a frame behind what the field already holds. Rewinding the
    // field to that older value used to garble the address, which is how a
    // typed "...0.2:4000" came out as "...0.2:4000000" on a real phone.
    await tester.enterText(find.byType(TextFormField), 'http://192.168.0.2:4000');
    await tester.pumpWidget(field('http://192.168.0.99'));
    await tester.pump();

    expect(find.text('http://192.168.0.2:4000'), findsOneWidget);
  });

  testWidgets('a field that replaces another under one controller still saves', (tester) async {
    final history = _RecordedHistory();
    final controller = HistoryAutocompleteController();
    Widget host(Key key) => MaterialApp(
      home: Scaffold(
        body: Provider<AutocompleteHistoryRepository>.value(
          value: history,
          child: HistoryAutocompleteField(
            key: key,
            storageKey: 'recent',
            labelText: 'Address',
            controller: controller,
            initialValue: 'https://core.example.com',
          ),
        ),
      ),
    );

    // A screen that switches arrangement mounts the new field before it
    // disposes the old one; the old one must not take the controller along.
    await tester.pumpWidget(host(const ValueKey('phone')));
    await tester.pumpWidget(host(const ValueKey('watch')));
    controller.saveToHistory();

    expect(history.saved, ['https://core.example.com']);
  });

  testWidgets('without suggestions no list drops down, typing as usual', (tester) async {
    final history = _RecordedHistory()..saved.add('https://core.example.com');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Provider<AutocompleteHistoryRepository>.value(
            value: history,
            child: const HistoryAutocompleteField(storageKey: 'recent', labelText: 'Address', suggestHistory: false),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'core');
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('a value set from outside still lands while the field is idle', (tester) async {
    await tester.pumpWidget(field('http://first.example'));
    expect(find.text('http://first.example'), findsOneWidget);

    // Nobody is in the field, so this is a genuine external change - a preset
    // or restored state - and it has to replace what is shown.
    await tester.pumpWidget(field('http://second.example'));
    await tester.pump();

    expect(find.text('http://second.example'), findsOneWidget);
    expect(find.text('http://first.example'), findsNothing);
  });
}
