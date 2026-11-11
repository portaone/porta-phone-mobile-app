import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_kit/adaptive_kit.dart';

import 'helpers/screen_presets.dart';

void main() {
  Widget wrap(Widget body) => MaterialApp(
    home: Scaffold(body: Center(child: body)),
  );

  CircularProgressIndicator ring(WidgetTester tester) =>
      tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));

  for (final preset in watchPresets) {
    testWidgets('on $preset the ring goes round the button, the time under it', (tester) async {
      preset.apply(tester);
      expect(
        await pumpCollectingOverflows(
          tester,
          wrap(WatchPlayButton(playing: true, label: 'Pause', progress: 0.25, time: '0:12 / 0:42', onPressed: () {})),
        ),
        isEmpty,
      );

      final button = tester.getRect(find.byType(IconButton));
      final around = tester.getRect(find.byType(CircularProgressIndicator));
      expect(around.contains(button.topLeft) && around.contains(button.bottomRight), isTrue);
      expect(around.center.dx, closeTo(button.center.dx, 0.5));
      expect(tester.getRect(find.text('0:12 / 0:42')).top, greaterThan(around.bottom));
      expect(ring(tester).value, 0.25);
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });
  }

  testWidgets('on its way the ring turns without an end; a progress past the end stops at it', (tester) async {
    watchPresets.first.apply(tester);
    await tester.pumpWidget(wrap(WatchPlayButton(playing: false, label: 'Play', loading: true, onPressed: () {})));
    expect(ring(tester).value, isNull);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    await tester.pumpWidget(wrap(WatchPlayButton(playing: true, label: 'Pause', progress: 1.4, onPressed: () {})));
    expect(ring(tester).value, 1);
  });

  testWidgets('one button for a screen reader: what the press does and how far it has got', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    var pressed = 0;
    await tester.pumpWidget(
      wrap(
        WatchPlayButton(
          playing: false,
          label: 'Play',
          time: '0:12 / 0:42',
          value: '12 seconds of 42 seconds',
          identifier: 'play',
          onPressed: () => pressed++,
        ),
      ),
    );

    final node = find.semantics.byLabel('Play').evaluate().single;
    expect(node.identifier, 'play');
    expect(node.value, '12 seconds of 42 seconds');
    expect(node.flagsCollection.isButton, isTrue);
    // Read out, `0:12` is a time of day: the value says it instead.
    expect(find.bySemanticsLabel(RegExp('0:12')), findsNothing);

    await tester.tap(find.byType(IconButton));
    expect(pressed, 1);
    handle.dispose();
  });

  testWidgets('without a press it is drawn disabled', (tester) async {
    watchPresets.first.apply(tester);
    await tester.pumpWidget(wrap(const WatchPlayButton(playing: false, label: 'Play', onPressed: null)));

    expect(tester.widget<IconButton>(find.byType(IconButton)).onPressed, isNull);
  });
}
