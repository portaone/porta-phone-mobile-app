import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_kit/adaptive_kit.dart';

import 'helpers/screen_presets.dart';

void main() {
  Widget wrap(Widget body) => MaterialApp(home: Scaffold(body: body));

  group('WatchPillButton', () {
    for (final preset in watchPresets) {
      testWidgets('on $preset it is one button by its name, its label set smaller to fit half a row', (tester) async {
        final handle = tester.ensureSemantics();
        preset.apply(tester);
        var taps = 0;
        expect(
          await pumpCollectingOverflows(
            tester,
            wrap(
              Center(
                child: SizedBox(
                  width: 90,
                  child: WatchPillButton(
                    icon: Icons.cloud_outlined,
                    label: 'A long book name',
                    semanticsLabel: 'Source: A long book name',
                    identifier: 'pill',
                    onPressed: () => taps++,
                  ),
                ),
              ),
            ),
          ),
          isEmpty,
        );

        expect(
          tester.getSemantics(find.bySemanticsIdentifier('pill')).getSemanticsData().label,
          'Source: A long book name',
        );
        expect(find.byType(FittedBox), findsOneWidget);
        final small = tester.view.physicalSize.shortestSide / tester.view.devicePixelRatio < 200;
        expect(find.byIcon(Icons.cloud_outlined), small ? findsNothing : findsOneWidget);
        await tester.tap(find.byType(WatchPillButton));
        expect(taps, 1);
        handle.dispose();
      });
    }
  });

  group('WatchListNote', () {
    testWidgets('is a centred line read out when it appears', (tester) async {
      final handle = tester.ensureSemantics();
      watchPresets.first.apply(tester);
      await tester.pumpWidget(wrap(const WatchListNote('No calls')));

      expect(tester.widget<Text>(find.text('No calls')).textAlign, TextAlign.center);
      expect(tester.getSemantics(find.text('No calls')).flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });
  });

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

  group('WatchScrollList.builder', () {
    for (final preset in watchPresets) {
      testWidgets('on $preset the title, the header, then rows built only as they come into view', (tester) async {
        preset.apply(tester);
        final built = <int>{};
        final controller = ScrollController();
        addTearDown(controller.dispose);

        expect(
          await pumpCollectingOverflows(
            tester,
            wrap(
              WatchScrollList.builder(
                title: 'Recents',
                header: const [SizedBox(key: Key('chip'), height: 40)],
                spacing: 4,
                controller: controller,
                itemCount: 500,
                itemBuilder: (context, index) {
                  built.add(index);
                  return SizedBox(key: Key('row $index'), height: 48);
                },
              ),
            ),
          ),
          isEmpty,
        );

        final title = tester.getRect(find.widgetWithText(WatchTitle, 'Recents'));
        final chip = tester.getRect(find.byKey(const Key('chip')));
        final first = tester.getRect(find.byKey(const Key('row 0')));
        final second = tester.getRect(find.byKey(const Key('row 1')));
        expect(title.bottom, lessThanOrEqualTo(chip.top));
        expect(chip.bottom, lessThanOrEqualTo(first.top));
        expect(second.top - first.bottom, 4);
        expect(built.length, lessThan(30), reason: 'every row was built up front');

        // The end of a lazy list is an estimate until it has been reached.
        for (var i = 0; i < 5; i++) {
          controller.jumpTo(controller.position.maxScrollExtent);
          await tester.pump();
        }
        expect(find.byKey(const Key('row 499')), findsOneWidget);
      });

      testWidgets('on $preset with an edge the button sits on the bottom and the last row scrolls clear of it', (
        tester,
      ) async {
        preset.apply(tester);
        var pressed = 0;
        final controller = ScrollController();
        addTearDown(controller.dispose);

        expect(
          await pumpCollectingOverflows(
            tester,
            wrap(
              WatchScrollList.builder(
                title: 'Jane Smith',
                controller: controller,
                itemCount: 40,
                itemBuilder: (context, index) => SizedBox(key: Key('row $index'), height: 24),
                edge: (context, overlay) => TextButton(
                  key: const Key('edge'),
                  style: overlay,
                  onPressed: () => pressed++,
                  child: const Text('Call'),
                ),
              ),
            ),
          ),
          isEmpty,
        );

        final face = tester.getRect(find.byType(WatchScrollList));
        final edge = tester.getRect(find.byKey(const Key('edge')));
        expect(edge.bottom, lessThanOrEqualTo(face.bottom));
        expect(edge.top, greaterThan(face.center.dy));
        await tester.tap(find.byKey(const Key('edge')));
        expect(pressed, 1);

        for (var i = 0; i < 5; i++) {
          controller.jumpTo(controller.position.maxScrollExtent);
          await tester.pump();
        }
        final last = tester.getRect(find.byKey(const Key('row 39')));
        expect(last.bottom, lessThanOrEqualTo(edge.top));
      });
    }
  });

  group('WatchSeparator', () {
    for (final preset in watchPresets) {
      testWidgets('on $preset it is a short bar in the middle, not read out', (tester) async {
        final handle = tester.ensureSemantics();
        preset.apply(tester);
        expect(await pumpCollectingOverflows(tester, wrap(const Column(children: [WatchSeparator()]))), isEmpty);

        final bar = tester.getRect(find.descendant(of: find.byType(WatchSeparator), matching: find.byType(Container)));
        final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
        expect(bar.width, WatchSeparator.width);
        expect(bar.height, WatchSeparator.thickness);
        expect(bar.center.dx, moreOrLessEquals(width / 2, epsilon: 0.5));
        expect(tester.getSemantics(find.byType(WatchSeparator)).label, isEmpty);
        handle.dispose();
      });
    }
  });

  group('WatchListTile', () {
    testWidgets('is one button named by its title and subtitle, not by what sits beside them', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(
        tester,
        wrap(
          WatchListTile(
            title: 'Jane Smith',
            subtitle: 'Missed, 12:02',
            leading: const CircleAvatar(child: Text('JS')),
            subtitleIcon: const Icon(Icons.call_missed, key: Key('direction'), semanticLabel: 'missed'),
            trailing: const Icon(Icons.chevron_right, semanticLabel: 'more'),
            identifier: 'row',
            onTap: () => taps++,
          ),
        ),
      );

      final row = find.bySemanticsIdentifier('row');
      expect(tester.getSemantics(row).getSemanticsData().label, 'Jane Smith, Missed, 12:02');
      expect(find.bySemanticsLabel(RegExp('JS|missed|more')), findsNothing);
      // The mark sits before the subtitle, on its line.
      final mark = tester.getRect(find.byKey(const Key('direction')));
      final subtitle = tester.getRect(find.text('Missed, 12:02'));
      expect(mark.right, lessThanOrEqualTo(subtitle.left));
      expect((mark.center.dy - subtitle.center.dy).abs(), lessThan(2));
      await tester.tap(find.text('Jane Smith'));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('a name of its own replaces the title and subtitle for assistive technology', (tester) async {
      final handle = tester.ensureSemantics();
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(
        tester,
        wrap(
          WatchListTile(
            title: 'Jane Smith',
            subtitle: '12:02',
            semanticsLabel: 'Jane Smith, Missed, 12:02',
            identifier: 'row',
            onTap: () {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsIdentifier('row')).getSemanticsData().label,
        'Jane Smith, Missed, 12:02',
      );
      handle.dispose();
    });
  });
}
