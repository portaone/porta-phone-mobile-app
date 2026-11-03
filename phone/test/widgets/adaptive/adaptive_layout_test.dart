import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/screen_presets.dart';

void main() {
  Widget wrap({bool withWatch = true, bool withLarge = true}) {
    return MaterialApp(
      home: AdaptiveLayout(
        handset: (_) => const Text('handset', key: Key('handset')),
        watch: withWatch ? (_) => const Text('watch', key: Key('watch')) : null,
        large: withLarge ? (_) => const Text('large', key: Key('large')) : null,
      ),
    );
  }

  for (final (preset, expected) in [
    (watchPresets.first, 'watch'),
    (handsetPresets.first, 'handset'),
    (largePresets.first, 'large'),
  ]) {
    testWidgets('$preset gets the $expected arrangement only', (tester) async {
      preset.apply(tester);

      await tester.pumpWidget(wrap());

      for (final name in ['watch', 'handset', 'large']) {
        expect(find.byKey(Key(name)), name == expected ? findsOneWidget : findsNothing, reason: name);
      }
    });
  }

  testWidgets('a watch without its own arrangement gets the handset one', (tester) async {
    watchPresets.first.apply(tester);

    await tester.pumpWidget(wrap(withWatch: false));

    expect(find.byKey(const Key('handset')), findsOneWidget);
  });

  testWidgets('a tablet without its own arrangement gets the handset one', (tester) async {
    largePresets.first.apply(tester);

    await tester.pumpWidget(wrap(withLarge: false));

    expect(find.byKey(const Key('handset')), findsOneWidget);
  });

  testWidgets('resizing the window across a boundary swaps the arrangement', (tester) async {
    handsetPresets.first.apply(tester);

    await tester.pumpWidget(wrap());
    expect(find.byKey(const Key('handset')), findsOneWidget);

    watchPresets.first.apply(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('watch')), findsOneWidget);
    expect(find.byKey(const Key('handset')), findsNothing);
  });
}
