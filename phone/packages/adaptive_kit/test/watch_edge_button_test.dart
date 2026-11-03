import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';

import 'package:adaptive_kit/adaptive_kit.dart';

import 'helpers/screen_presets.dart';

void main() {
  group('WatchEdgeButtonBorder', () {
    // A 54-high button on a 192 face, 3 from the bezel: radius 93.
    const border = WatchEdgeButtonBorder(faceRadius: 93);
    const rect = Rect.fromLTWH(0, 0, 160, 54);
    final path = border.getOuterPath(rect);

    test('the middle of the button is inside', () {
      expect(path.contains(rect.center), isTrue);
      expect(path.contains(Offset(rect.center.dx, rect.bottom - 1)), isTrue);
    });

    test('the bottom corners are cut away along the face', () {
      expect(path.contains(rect.bottomLeft + const Offset(2, -2)), isFalse);
      expect(path.contains(rect.bottomRight + const Offset(-2, -2)), isFalse);
    });

    test('a border is drawn inside the outline, parallel to the bezel', () {
      const bordered = WatchEdgeButtonBorder(faceRadius: 93, side: BorderSide(width: 4));
      final inner = bordered.getInnerPath(rect);
      // Inside the outer outline by the border's width all round, the bottom
      // middle included: the circle shrank around the same centre.
      expect(inner.contains(Offset(rect.center.dx, rect.bottom - 2)), isFalse);
      expect(inner.contains(Offset(rect.center.dx, rect.bottom - 6)), isTrue);
      expect(inner.contains(Offset(rect.left + 30, rect.top + 2)), isFalse);
      expect(inner.contains(Offset(rect.left + 30, rect.top + 6)), isTrue);
    });

    test('the top corners are rounded', () {
      expect(path.contains(rect.topLeft + const Offset(1, 1)), isFalse);
      expect(path.contains(Offset(rect.center.dx, rect.top + 1)), isTrue);
    });
  });

  group('WatchEdgeButton', () {
    Widget wrap({ScreenShape? reported}) {
      final app = MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: WatchEdgeButton(
              builder: (context, overlay) => ElevatedButton(
                key: const Key('edge'),
                style: overlay,
                onPressed: () {},
                child: const Text('Sign in'),
              ),
            ),
          ),
        ),
      );
      return reported == null ? app : Provider<ScreenShape>.value(value: reported, child: app);
    }

    ShapeBorder? shapeOf(WidgetTester tester) =>
        tester.widget<ElevatedButton>(find.byKey(const Key('edge'))).style?.shape?.resolve({});

    testWidgets('the platform\'s answer wins over the window\'s proportions', (tester) async {
      // A square watch: square like a round face, but the platform says it is
      // not round.
      watchPresets.first.apply(tester);
      await tester.pumpWidget(wrap(reported: const ScreenShape(isRound: false)));
      expect(shapeOf(tester), isA<StadiumBorder>());

      // A round face whose window is not square - a flat-tyre display.
      tester.view.physicalSize = const Size(360, 325);
      await tester.pumpWidget(wrap(reported: const ScreenShape(isRound: true)));
      expect(shapeOf(tester), isA<WatchEdgeButtonBorder>());
    });

    for (final preset in watchPresets) {
      testWidgets('on $preset it rests on the bottom edge and spans the face', (tester) async {
        preset.apply(tester);
        await tester.pumpWidget(wrap());

        final button = tester.getRect(find.byKey(const Key('edge')));
        final reserved = WatchEdgeButton.reservedHeight(tester.element(find.byKey(const Key('edge'))));
        expect(button.bottom, lessThan(preset.size.height), reason: 'a gap keeps it off the bezel');
        expect(preset.size.height - button.top, closeTo(reserved, 0.01));
        expect(button.height, greaterThanOrEqualTo(kMinInteractiveDimension));
        expect(button.width, greaterThan(preset.size.width * 0.7));
      });
    }

    testWidgets('a round face gets the bezel-following outline, a rectangular one a capsule', (tester) async {
      watchPresets.first.apply(tester);
      await tester.pumpWidget(wrap());
      expect(
        tester.widget<ElevatedButton>(find.byKey(const Key('edge'))).style?.shape?.resolve({}),
        isA<WatchEdgeButtonBorder>(),
      );

      watchPresets.firstWhere((preset) => preset.size.width != preset.size.height).apply(tester);
      await tester.pumpWidget(wrap());
      expect(
        tester.widget<ElevatedButton>(find.byKey(const Key('edge'))).style?.shape?.resolve({}),
        isA<StadiumBorder>(),
      );
    });
  });
}
