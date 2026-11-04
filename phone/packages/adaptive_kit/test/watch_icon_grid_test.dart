import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_kit/adaptive_kit.dart';

import 'helpers/screen_presets.dart';

void main() {
  Widget grid(int count, {String? title = 'PortaPhone'}) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: WatchIconGrid(
        title: title,
        items: [
          for (var i = 0; i < count; i++)
            WatchIconGridItem(
              icon: const Icon(Icons.history),
              caption: 'Voicemail',
              buttonKey: ValueKey(i),
              emphasis: i == 0 ? WatchRoundEmphasis.filled : WatchRoundEmphasis.tonal,
              onPressed: () {},
            ),
        ],
      ),
    ),
  );

  // The drawn button, not its tap target, which is never under 48.
  Finder drawn(int i) => find.descendant(of: find.byKey(ValueKey(i)), matching: find.byType(Material)).first;

  for (final preset in watchPresets) {
    final round = preset.size.width == preset.size.height;

    for (final count in [2, 3, 6]) {
      testWidgets('on $preset $count cells fit the face without scrolling', (tester) async {
        preset.apply(tester);
        expect(await pumpCollectingOverflows(tester, grid(count)), isEmpty);

        final face = Offset.zero & preset.size;
        final centre = face.center;
        final radius = preset.size.shortestSide / 2;
        for (var i = 0; i < count; i++) {
          final button = tester.getRect(drawn(i));
          // The button and its caption below it, as one cell.
          final cell = Rect.fromLTRB(button.left, button.top, button.right, button.bottom + 14);
          expect(face.contains(cell.topLeft) && face.contains(cell.bottomRight), isTrue, reason: 'cell $i');
          expect(button.height, greaterThanOrEqualTo(36), reason: 'cell $i is a fingertip target');
          if (round) {
            for (final corner in [cell.topLeft, cell.topRight, cell.bottomLeft, cell.bottomRight]) {
              expect((corner - centre).distance, lessThan(radius), reason: 'cell $i corner $corner');
            }
          }
        }
      });
    }

    testWidgets('on $preset two cells are larger than three to a row', (tester) async {
      preset.apply(tester);
      await pumpCollectingOverflows(tester, grid(2));
      final two = tester.getSize(drawn(0)).width;
      await pumpCollectingOverflows(tester, grid(6));
      final six = tester.getSize(drawn(0)).width;
      expect(two, greaterThan(six));
    });
  }

  testWidgets('a cell is one button, named by its caption', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    await pumpCollectingOverflows(tester, grid(2, title: null));

    expect(find.bySemanticsLabel('Voicemail'), findsNWidgets(2));
    handle.dispose();
  });
}
