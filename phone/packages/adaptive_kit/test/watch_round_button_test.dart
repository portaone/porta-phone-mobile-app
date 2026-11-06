import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_kit/adaptive_kit.dart';

import 'helpers/screen_presets.dart';

void main() {
  for (final preset in watchPresets) {
    for (final emphasis in WatchRoundEmphasis.values) {
      testWidgets('on $preset the icon of a $emphasis button sits in its middle', (tester) async {
        preset.apply(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: WatchRoundButton(
                  size: 36,
                  emphasis: emphasis,
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );

        final button = tester.getCenter(find.byType(IconButton));
        final icon = tester.getCenter(find.byType(Icon));
        expect(icon.dx, closeTo(button.dx, 0.5));
        expect(icon.dy, closeTo(button.dy, 0.5));
        // A glyph squeezed into less than its size draws from the box's corner,
        // past its middle: the box reads centred while the icon is not.
        expect(tester.getSize(find.byType(Icon)), const Size.square(24));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
