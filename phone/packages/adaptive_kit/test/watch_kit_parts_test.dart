import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_kit/adaptive_kit.dart';

import 'helpers/screen_presets.dart';

void main() {
  Widget wrap(Widget body) => MaterialApp(home: Scaffold(body: body));

  group('WatchSpinner', () {
    testWidgets('is the one spinner size, named by the label it is given', (tester) async {
      final handle = tester.ensureSemantics();
      watchPresets.first.apply(tester);
      await tester.pumpWidget(wrap(const Center(child: WatchSpinner(label: 'Loading'))));

      expect(tester.getSize(find.byType(WatchSpinner)), const Size.square(WatchSpinner.size));
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      handle.dispose();
    });
  });

  group('WatchRoundButton', () {
    testWidgets('is one button named by its label, the caption for the eye', (tester) async {
      final handle = tester.ensureSemantics();
      var pressed = 0;
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(
        tester,
        wrap(
          Center(
            child: WatchRoundButton(
              icon: const Icon(Icons.mic),
              caption: 'Mute',
              label: 'Mute microphone',
              identifier: 'mute',
              onPressed: () => pressed++,
            ),
          ),
        ),
      );

      expect(find.bySemanticsIdentifier('mute'), findsOneWidget);
      expect(find.bySemanticsLabel('Mute microphone'), findsOneWidget);
      expect(find.bySemanticsLabel('Mute'), findsNothing);
      await tester.tap(find.bySemanticsIdentifier('mute'));
      expect(pressed, 1);
      handle.dispose();
    });

    testWidgets('over the call it is light, solid when on, and the screen\'s style wins', (tester) async {
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(
        tester,
        wrap(
          Row(
            children: [
              WatchRoundButton(
                key: const Key('off'),
                icon: const Icon(Icons.mic),
                tone: WatchRoundTone.onDark,
                onPressed: () {},
              ),
              WatchRoundButton(
                key: const Key('on'),
                icon: const Icon(Icons.mic_off),
                tone: WatchRoundTone.onDark,
                emphasis: WatchRoundEmphasis.filled,
                onPressed: () {},
              ),
              WatchRoundButton(
                key: const Key('red'),
                icon: const Icon(Icons.call_end),
                tone: WatchRoundTone.onDark,
                style: IconButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      Color? background(String key) => tester
          .widget<IconButton>(find.descendant(of: find.byKey(Key(key)), matching: find.byType(IconButton)))
          .style
          ?.backgroundColor
          ?.resolve(const {});
      final light = Theme.of(tester.element(find.byKey(const Key('off')))).colorScheme.surface;
      expect(background('off'), light.withValues(alpha: 0.28));
      expect(background('on'), light);
      expect(background('red'), Colors.red);
    });

    testWidgets('a long caption is cut to its column', (tester) async {
      watchPresets.first.apply(tester);
      expect(
        await pumpCollectingOverflows(
          tester,
          wrap(
            Center(
              child: WatchRoundButton(
                icon: const Icon(Icons.mic),
                caption: 'A caption far too long for any button',
                onPressed: () {},
              ),
            ),
          ),
        ),
        isEmpty,
      );
      expect(
        tester.getSize(find.byType(WatchRoundButton)).width,
        WatchRoundButton.defaultSize(tester.element(find.byType(WatchRoundButton))) + 8,
      );
    });
  });

  group('WatchEdgeLayout', () {
    for (final preset in watchPresets) {
      testWidgets('on $preset the body ends above the edge button, the backdrop fills the face', (tester) async {
        preset.apply(tester);
        await pumpCollectingOverflows(
          tester,
          wrap(
            WatchEdgeLayout(
              backdrop: const ColoredBox(key: Key('backdrop'), color: Colors.black),
              body: const SizedBox.expand(key: Key('body')),
              edge: (context, overlay) =>
                  ElevatedButton(key: const Key('edge'), style: overlay, onPressed: () {}, child: const Text('Call')),
            ),
          ),
        );

        expect(tester.getSize(find.byKey(const Key('backdrop'))), preset.size);
        final body = tester.getRect(find.byKey(const Key('body')));
        final edge = tester.getRect(find.byKey(const Key('edge')));
        expect(body.bottom, lessThanOrEqualTo(edge.top + 0.01));
        expect(edge.bottom, closeTo(preset.size.height, 6));
      });
    }
  });

  group('WatchKeyGrid', () {
    const dialKeys = [
      WatchKey('1'),
      WatchKey('2'),
      WatchKey('3'),
      WatchKey('4'),
      WatchKey('5'),
      WatchKey('6'),
      WatchKey('7'),
      WatchKey('8'),
      WatchKey('9'),
      WatchKey('*'),
      WatchKey('0', alternate: '+'),
      WatchKey('#'),
    ];

    testWidgets('twelve keys; a held 0 enters +, or 0 with alternates off', (tester) async {
      final handle = tester.ensureSemantics();
      final typed = <String>[];
      watchPresets.first.apply(tester);
      Widget grid({bool alternates = true}) => wrap(
        WatchKeyGrid(keys: dialKeys, onPressed: typed.add, alternates: alternates, identifier: (text) => 'key-$text'),
      );

      await pumpCollectingOverflows(tester, grid());
      for (final key in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#']) {
        expect(find.bySemanticsIdentifier('key-$key'), findsOneWidget);
      }
      await tester.tap(find.text('5'));
      await tester.longPress(find.text('0'));
      expect(typed, ['5', '+']);

      typed.clear();
      await pumpCollectingOverflows(tester, grid(alternates: false));
      await tester.longPress(find.text('0'));
      expect(typed, ['0'], reason: 'without alternates a held key enters itself, as a tone');
      handle.dispose();
    });

    testWidgets('without a callback the keys are disabled', (tester) async {
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(tester, wrap(const WatchKeyGrid(keys: dialKeys, onPressed: null)));
      expect(tester.getSemantics(find.text('5')), matchesSemantics(label: '5', isButton: true, hasEnabledState: true));
    });
  });

  group('WatchScrollList as a page', () {
    testWidgets('a title, a gap between rows, and its own background', (tester) async {
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(
        tester,
        wrap(
          const WatchScrollList(
            opaque: true,
            title: 'Audio',
            spacing: 6,
            children: [
              SizedBox(key: Key('a'), height: 30),
              SizedBox(key: Key('b'), height: 30),
            ],
          ),
        ),
      );

      expect(find.widgetWithText(WatchTitle, 'Audio'), findsOneWidget);
      final a = tester.getRect(find.byKey(const Key('a')));
      final b = tester.getRect(find.byKey(const Key('b')));
      expect(b.top - a.bottom, 6);
      expect(find.ancestor(of: find.byType(ListView), matching: find.byType(Material)), findsWidgets);
    });
  });
}
