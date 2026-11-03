import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_kit/adaptive_kit.dart';

void main() {
  const menuKey = Key('menu');
  const contentKey = Key('content');
  const openKey = Key('open');

  Widget face({required bool menuFirst, bool canGoBack = true}) => Scaffold(
    body: WatchDrillIn(
      menuFirst: menuFirst,
      canGoBack: canGoBack,
      menu: (context, open) => TextButton(
        key: openKey,
        onPressed: open,
        child: const Text('menu', key: menuKey),
      ),
      content: const Text('content', key: contentKey),
    ),
  );

  Widget drillIn({required bool menuFirst, bool canGoBack = true}) => MaterialApp(
    home: face(menuFirst: menuFirst, canGoBack: canGoBack),
  );

  // A page under the drill-in, so leaving it shows on the navigator.
  Widget pushed(Widget page) => MaterialApp(
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page)),
        child: const Text('push'),
      ),
    ),
  );

  Future<void> goBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  testWidgets('back from the content returns to the menu', (tester) async {
    await tester.pumpWidget(drillIn(menuFirst: true));
    await tester.tap(find.byKey(openKey));
    await tester.pump();
    expect(find.byKey(contentKey), findsOneWidget);

    await goBack(tester);

    expect(find.byKey(menuKey), findsOneWidget);
  });

  testWidgets('starts over when the menu grows past one entry or shrinks to one', (tester) async {
    await tester.pumpWidget(drillIn(menuFirst: false));
    expect(find.byKey(contentKey), findsOneWidget);

    await tester.pumpWidget(drillIn(menuFirst: true));
    expect(find.byKey(menuKey), findsOneWidget);

    await tester.pumpWidget(drillIn(menuFirst: false));
    expect(find.byKey(contentKey), findsOneWidget);
  });

  testWidgets('while it cannot go back it keeps the content and does not leave', (tester) async {
    await tester.pumpWidget(pushed(face(menuFirst: true, canGoBack: false)));
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(openKey));
    await tester.pump();

    await goBack(tester);

    expect(find.byKey(contentKey), findsOneWidget);
  });

  testWidgets('a single entry while it cannot go back does not leave', (tester) async {
    await tester.pumpWidget(pushed(face(menuFirst: false, canGoBack: false)));
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();

    await goBack(tester);

    expect(find.byKey(contentKey), findsOneWidget);
  });

  group('keeping the content', () {
    Widget keeping({Object? openOn}) => MaterialApp(
      home: Scaffold(
        body: WatchDrillIn(
          menuFirst: true,
          keepContent: true,
          openOn: openOn,
          menu: (context, open) => TextButton(
            key: openKey,
            onPressed: open,
            child: const Text('menu', key: menuKey),
          ),
          content: const _Counter(key: contentKey),
        ),
      ),
    );

    testWidgets('the content keeps its state across a trip to the menu', (tester) async {
      await tester.pumpWidget(keeping());
      await tester.tap(find.byKey(openKey));
      await tester.pump();
      await tester.tap(find.byKey(contentKey));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      await goBack(tester);
      expect(find.byKey(menuKey), findsOneWidget);
      expect(find.text('1'), findsNothing, reason: 'hidden under the menu');

      await tester.tap(find.byKey(openKey));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('a change of openOn opens the content', (tester) async {
      await tester.pumpWidget(keeping(openOn: 'a'));
      expect(find.byKey(menuKey), findsOneWidget);

      await tester.pumpWidget(keeping(openOn: 'b'));
      expect(find.text('0'), findsOneWidget);
      expect(find.byKey(menuKey), findsNothing);
    });

    testWidgets('the content knows going back belongs to the drill-in', (tester) async {
      late bool owned;
      await tester.pumpWidget(
        MaterialApp(
          home: WatchDrillIn(
            menuFirst: false,
            menu: (context, open) => const SizedBox(),
            content: Builder(
              builder: (context) {
                owned = WatchDrillIn.ownsBack(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(owned, isTrue);
    });
  });
}

class _Counter extends StatefulWidget {
  const _Counter({super.key});

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  var _count = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(onTap: () => setState(() => _count++), child: Text('$_count'));
}
