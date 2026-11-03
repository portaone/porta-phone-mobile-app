import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_kit/adaptive_kit.dart';

import 'helpers/screen_presets.dart';

void main() {
  Widget wrap(Widget body) => MaterialApp(home: Scaffold(body: body));

  group('WatchActionLayout', () {
    var pressed = 0;

    Widget layout({VoidCallback? onPressed}) => WatchActionLayout(
      title: 'Data collection',
      content: const [Text('With your permission', key: Key('body'))],
      action: WatchAction(
        label: 'Continue',
        onPressed: onPressed,
        identifier: 'continue-id',
        buttonKey: const Key('continue'),
      ),
    );

    for (final preset in watchPresets) {
      testWidgets('on $preset the title opens the column and the action is the edge button', (tester) async {
        preset.apply(tester);
        expect(await pumpCollectingOverflows(tester, wrap(layout(onPressed: () {}))), isEmpty);

        expect(find.widgetWithText(WatchTitle, 'Data collection'), findsOneWidget);
        final title = tester.getRect(find.byType(WatchTitle));
        expect(title.bottom, lessThan(tester.getRect(find.byKey(const Key('body'))).top));
        expect(
          find.descendant(of: find.byType(WatchEdgeButton), matching: find.byKey(const Key('continue'))),
          findsOneWidget,
        );
      });
    }

    testWidgets('the action carries its id, and a null callback disables it', (tester) async {
      final handle = tester.ensureSemantics();
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(tester, wrap(layout(onPressed: () => pressed++)));

      expect(find.bySemanticsIdentifier('continue-id'), findsOneWidget);
      await tester.tap(find.byKey(const Key('continue')));
      expect(pressed, 1);

      await pumpCollectingOverflows(tester, wrap(layout()));
      expect(tester.widget<OutlinedButton>(find.byKey(const Key('continue'))).onPressed, isNull);
      handle.dispose();
    });

    testWidgets('plain text in the column takes the small body size', (tester) async {
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(tester, wrap(layout(onPressed: () {})));

      final context = tester.element(find.byKey(const Key('body')));
      final small = Theme.of(context).textTheme.bodySmall!.fontSize;
      expect(DefaultTextStyle.of(context).style.fontSize, small);
    });

    testWidgets('a primary builder still builds the main button', (tester) async {
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(
        tester,
        wrap(
          WatchActionLayout(
            content: const [],
            primary: (overlay) =>
                OutlinedButton(key: const Key('built'), style: overlay, onPressed: () {}, child: const Text('Go')),
          ),
        ),
      );
      expect(find.byKey(const Key('built')), findsOneWidget);
    });
  });

  group('WatchLink', () {
    testWidgets('is a button with its label, at the tap floor, underlined', (tester) async {
      var pressed = 0;
      final handle = tester.ensureSemantics();
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(
        tester,
        wrap(
          Center(
            child: WatchLink(label: 'Read the terms', onPressed: () => pressed++),
          ),
        ),
      );

      final link = find.byType(TextButton);
      expect(tester.getSize(link).height, greaterThanOrEqualTo(WatchPill.height));
      expect(find.bySemanticsLabel('Read the terms'), findsOneWidget);
      final style = tester.widget<TextButton>(link).style!.textStyle!.resolve({});
      expect(style!.decoration, TextDecoration.underline);

      await tester.tap(link);
      expect(pressed, 1);
      handle.dispose();
    });
  });
}
