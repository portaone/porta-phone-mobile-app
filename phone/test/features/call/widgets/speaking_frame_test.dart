import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/features/call/call.dart';

/// The border that marks who speaks: the theme's accent, its own id, and nothing under it is
/// covered for a tap.
void main() {
  const accent = Color(0xFF5CACE3);

  testWidgets('a border of the theme\'s accent with an id of its own, through which taps go', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: const ColorScheme.light(primary: accent)),
        home: Center(
          child: SizedBox(
            width: 120,
            height: 80,
            child: Stack(
              children: [
                Positioned.fill(child: GestureDetector(onTap: () => taps++)),
                const Positioned.fill(child: SpeakingFrame(identifier: 'speaking', radius: 12)),
              ],
            ),
          ),
        ),
      ),
    );

    final frame = find.bySemanticsIdentifier('speaking');
    expect(frame, findsOneWidget);
    expect(tester.getSize(frame), const Size(120, 80));
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(SpeakingFrame), matching: find.byType(DecoratedBox)),
    );
    final border = (box.decoration as BoxDecoration).border! as Border;
    expect(border.top.color, accent);
    expect(border.top.width, 3);

    await tester.tap(find.byType(SpeakingFrame), warnIfMissed: false);
    expect(taps, 1);

    semantics.dispose();
  });
}
