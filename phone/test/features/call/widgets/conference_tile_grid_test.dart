import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/features/call/widgets/conference_tile_grid.dart';

/// The grid of the conference full screen: the column count that shows the most of the pictures,
/// the wide tiles to the landscape pictures, and a layout held a while before the next.
void main() {
  const area = Size(344, 620);
  const landscape = 16 / 9;
  const portrait = 3 / 4;

  ConferenceGridLayout choose(List<double?> aspects, {Size size = area}) =>
      chooseConferenceGridLayout(area: size, aspects: aspects, gap: 8, minRowHeight: 160);

  group('chooseConferenceGridLayout', () {
    test('two landscape pictures on an upright phone go one over the other', () {
      expect(choose([landscape, landscape]), ConferenceGridLayout.inOrder(2, columns: 1));
    });

    test('two landscape pictures on a phone turned sideways go side by side', () {
      expect(choose([landscape, landscape], size: const Size(780, 280)), ConferenceGridLayout.inOrder(2, columns: 2));
    });

    test('four phone cameras make two by two', () {
      expect(choose([portrait, portrait, portrait, portrait]), ConferenceGridLayout.inOrder(4, columns: 2));
    });

    test('a picture not known yet counts as an upright phone camera', () {
      expect(choose([null, null, null, null]), choose([portrait, portrait, portrait, portrait]));
    });

    test('one landscape and two phone cameras: two columns, the wide last row to the landscape one', () {
      final layout = choose([portrait, landscape, portrait]);

      expect(layout.columns, 2);
      expect(layout.rows, [2, 1]);
      expect(layout.order, [0, 2, 1], reason: 'the landscape picture (tile 1) takes the last row');
    });

    test('equal pictures keep their order, the leftover last', () {
      expect(choose([portrait, portrait, portrait]).order, [0, 1, 2]);
    });

    test('the visible part is the smaller proportion over the larger', () {
      expect(conferenceVisibleFraction(1, 1), 1);
      expect(conferenceVisibleFraction(0.5, 1), 0.5);
      expect(conferenceVisibleFraction(2, 1), 0.5);
    });
  });

  group('ConferenceGridHold', () {
    final one = ConferenceGridLayout.inOrder(2, columns: 1);
    final two = ConferenceGridLayout.inOrder(2, columns: 2);
    final start = DateTime(2026);
    const frame = (2, area);

    test('the first layout shows at once', () {
      final hold = ConferenceGridHold();

      expect(hold.next(one, frame, start), (layout: one, retryIn: null));
    });

    test('a new layout within the hold waits for its end, then shows', () {
      final hold = ConferenceGridHold()..next(one, frame, start);

      expect(hold.next(two, frame, start.add(const Duration(seconds: 1))), (
        layout: one,
        retryIn: const Duration(seconds: 2),
      ));
      expect(hold.next(two, frame, start.add(const Duration(seconds: 3))), (layout: two, retryIn: null));
      expect(hold.next(one, frame, start.add(const Duration(seconds: 4))), (
        layout: two,
        retryIn: const Duration(seconds: 2),
      ), reason: 'the hold starts again from the last change');
    });

    test('the same layout again is no change and starts no hold', () {
      final hold = ConferenceGridHold()..next(one, frame, start);

      expect(hold.next(one, frame, start.add(const Duration(seconds: 10))), (layout: one, retryIn: null));
      expect(hold.next(two, frame, start.add(const Duration(seconds: 11))), (layout: two, retryIn: null));
    });

    test('another tile count or place shows at once', () {
      final hold = ConferenceGridHold()..next(one, frame, start);
      final three = ConferenceGridLayout.inOrder(3, columns: 2);

      expect(hold.next(three, (3, area), start.add(const Duration(seconds: 1))), (layout: three, retryIn: null));
      expect(hold.next(two, (2, const Size(780, 280)), start.add(const Duration(seconds: 2))), (
        layout: two,
        retryIn: null,
      ));
    });
  });

  group('ConferenceTileGrid', () {
    Widget grid(List<double?> aspects) => MaterialApp(
      home: Center(
        child: SizedBox(
          width: 360,
          height: 620,
          child: ConferenceTileGrid(
            gap: 8,
            minRowHeight: 160,
            tiles: [
              for (var i = 0; i < aspects.length; i++) ColoredBox(key: ValueKey(i), color: const Color(0xFF000000)),
            ],
            aspects: aspects,
          ),
        ),
      ),
    );

    Rect tile(WidgetTester tester, int index) => tester.getRect(find.byKey(ValueKey(index)));

    testWidgets('lays the tiles out as chosen: the wide last row to the landscape picture', (tester) async {
      await tester.pumpWidget(grid([portrait, landscape, portrait]));

      expect(tile(tester, 0).top, tile(tester, 2).top, reason: 'the two phone cameras share the first row');
      expect(tile(tester, 1).top, greaterThan(tile(tester, 0).bottom));
      expect(tile(tester, 1).width, closeTo(344, 0.01));
    });

    testWidgets('a picture changing its shape moves the tiles no sooner than the hold allows', (tester) async {
      await tester.pumpWidget(grid([portrait, portrait, portrait, portrait]));
      expect(tile(tester, 1).top, tile(tester, 0).top, reason: 'four phone cameras: two by two');

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(grid([landscape, landscape, landscape, landscape]));
      expect(tile(tester, 1).top, tile(tester, 0).top, reason: 'within the hold the tiles stay');

      await tester.pump(const Duration(seconds: 1));
      expect(tile(tester, 1).top, tile(tester, 0).top);

      await tester.pump(const Duration(seconds: 1));
      expect(tile(tester, 1).top, greaterThan(tile(tester, 0).bottom), reason: 'past the hold: one column');
    });
  });
}
