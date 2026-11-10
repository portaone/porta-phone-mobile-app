import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_kit/adaptive_kit.dart';

import 'helpers/screen_presets.dart';

void main() {
  Widget wrap(Widget body) => MaterialApp(home: Scaffold(body: body));

  WatchStatePage failed({VoidCallback? onPressed, String message = 'Failed'}) => WatchStatePage(
    title: 'Contacts',
    // A label of its own, so the test sees whether the page keeps it unread.
    icon: const Icon(Icons.error_outline, key: Key('icon'), semanticLabel: 'Error icon'),
    message: message,
    hint: 'Offline',
    action: WatchAction(
      label: 'Try again',
      onPressed: onPressed,
      identifier: 'retry-id',
      buttonKey: const Key('retry'),
    ),
  );

  group('WatchStatePage', () {
    for (final preset in watchPresets) {
      // The test font draws every glyph as a square, so the strings are short:
      // they fit on one line here as the real ones do in the app's font.
      testWidgets('on $preset the title stays on top, the state takes the middle, the action is the edge button', (
        tester,
      ) async {
        preset.apply(tester);
        expect(await pumpCollectingOverflows(tester, wrap(failed(onPressed: () {}))), isEmpty);

        final title = tester.getRect(find.widgetWithText(WatchTitle, 'Contacts'));
        final icon = tester.getRect(find.byKey(const Key('icon')));
        final message = tester.getRect(find.text('Failed'));
        final hint = tester.getRect(find.text('Offline'));
        final edge = tester.getRect(find.byType(WatchEdgeButton));
        expect(title.bottom, lessThanOrEqualTo(icon.top));
        expect(icon.bottom, lessThanOrEqualTo(message.top));
        expect(message.bottom, lessThanOrEqualTo(hint.top));
        expect(hint.bottom, lessThanOrEqualTo(edge.top));
        expect(
          message.center.dx,
          moreOrLessEquals(tester.view.physicalSize.width / tester.view.devicePixelRatio / 2, epsilon: 1),
        );
        expect(
          find.descendant(of: find.byType(WatchEdgeButton), matching: find.byKey(const Key('retry'))),
          findsOneWidget,
        );
      });

      testWidgets('on $preset a footer sits under the state, the state first, and can be used', (tester) async {
        preset.apply(tester);
        var taps = 0;
        final chip = TextButton(key: const Key('chip'), onPressed: () => taps++, child: const Text('Cloud'));
        expect(
          await pumpCollectingOverflows(
            tester,
            wrap(
              WatchStatePage(
                title: 'Contacts',
                footer: [chip],
                icon: const Icon(Icons.error_outline, key: Key('icon')),
                message: 'Failed',
              ),
            ),
          ),
          isEmpty,
        );

        final title = tester.getRect(find.widgetWithText(WatchTitle, 'Contacts'));
        final footer = tester.getRect(find.byKey(const Key('chip')));
        expect(title.bottom, lessThanOrEqualTo(tester.getRect(find.byKey(const Key('icon'))).top));
        expect(tester.getRect(find.text('Failed')).bottom, lessThanOrEqualTo(footer.top));
        await tester.tap(find.byKey(const Key('chip')));
        expect(taps, 1);

        await pumpCollectingOverflows(
          tester,
          wrap(WatchStatePage.loading(title: 'Contacts', footer: [chip], progressLabel: 'Loading')),
        );
        expect(
          tester.getRect(find.byType(CircularProgressIndicator)).bottom,
          lessThanOrEqualTo(tester.getRect(find.byKey(const Key('chip'))).top),
        );
      });

      testWidgets('on $preset the loading state is a spinner with its hint and no action', (tester) async {
        preset.apply(tester);
        expect(
          await pumpCollectingOverflows(
            tester,
            wrap(const WatchStatePage.loading(title: 'Chats', hint: 'Connecting...', progressLabel: 'Loading')),
          ),
          isEmpty,
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Connecting...'), findsOneWidget);
        expect(find.byType(WatchEdgeButton), findsNothing);
      });
    }

    testWidgets('a message too long for the face scrolls instead of overflowing', (tester) async {
      watchPresets.first.apply(tester);
      final long = List.filled(12, 'The address book could not be read').join(' ');

      expect(await pumpCollectingOverflows(tester, wrap(failed(onPressed: () {}, message: long))), isEmpty);
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
      expect(find.byKey(const Key('retry')), findsOneWidget);
    });

    testWidgets('without an action, a long message on a round face keeps off the narrow bottom', (tester) async {
      watchPresets.first.apply(tester);
      final long = List.filled(12, 'The address book could not be read').join(' ');
      await pumpCollectingOverflows(tester, wrap(WatchStatePage(title: 'Contacts', message: long)));

      final face = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final viewport = tester.getRect(find.byType(Scrollable));
      expect(viewport.bottom, lessThanOrEqualTo(face * 0.8 + 0.5));
    });

    testWidgets('without an action the face has no edge button', (tester) async {
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(tester, wrap(const WatchStatePage(title: 'Voicemail', message: 'No voicemails')));

      expect(find.byType(WatchEdgeButton), findsNothing);
      expect(find.text('No voicemails'), findsOneWidget);
    });

    testWidgets('the message and its hint read as one node, the icon is not read, the action keeps its id', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var pressed = 0;
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(tester, wrap(failed(onPressed: () => pressed++)));

      expect(find.bySemanticsLabel('Failed\nOffline'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Error icon')), findsNothing, reason: 'the icon is decoration');
      expect(find.bySemanticsIdentifier('retry-id'), findsOneWidget);
      await tester.tap(find.byKey(const Key('retry')));
      expect(pressed, 1);
      handle.dispose();
    });
    testWidgets('the spinner is read by the label the app gives it, and the state is a live region', (tester) async {
      final handle = tester.ensureSemantics();
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(
        tester,
        wrap(const WatchStatePage.loading(title: 'Chats', progressLabel: 'Loading')),
      );

      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      final live = find.byWidgetPredicate((w) => w is Semantics && (w.properties.liveRegion ?? false));
      expect(live, findsOneWidget);

      await pumpCollectingOverflows(tester, wrap(failed(onPressed: () {})));
      expect(live, findsOneWidget);
      handle.dispose();
    });
  });
}
