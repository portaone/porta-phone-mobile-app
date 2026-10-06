import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/theme/theme.dart';

/// The weights the app's type scale asks for.
///
/// A script the theme's typeface does not cover is drawn by the platform, and
/// for most scripts the platform has a regular and a bold face with nothing
/// between. A style asking for 500 gave such text in bold beside Latin text in
/// a medium face - a name in Devanagari in a list of Latin names.
void main() {
  final scale = AppFonts.typography(Typography.material2021());

  Iterable<TextStyle> stylesOf(TextTheme theme) => [
    theme.displayLarge!,
    theme.displayMedium!,
    theme.displaySmall!,
    theme.headlineLarge!,
    theme.headlineMedium!,
    theme.headlineSmall!,
    theme.titleLarge!,
    theme.titleMedium!,
    theme.titleSmall!,
    theme.bodyLarge!,
    theme.bodyMedium!,
    theme.bodySmall!,
    theme.labelLarge!,
    theme.labelMedium!,
    theme.labelSmall!,
  ];

  test('no style of the scale asks for a weight between regular and bold', () {
    for (final theme in [scale.englishLike, scale.dense, scale.tall]) {
      for (final style in stylesOf(theme)) {
        expect(style.fontWeight, anyOf(FontWeight.w400, FontWeight.w700), reason: '${style.debugLabel}');
      }
    }
  });

  test('a medium style becomes regular and keeps the rest of itself', () {
    final before = Typography.material2021().englishLike.titleMedium!;
    final after = scale.englishLike.titleMedium!;

    expect(before.fontWeight, FontWeight.w500, reason: 'the style this is about');
    expect(after, before.copyWith(fontWeight: FontWeight.w400));
  });

  test('the colours of the scale are left alone', () {
    final stock = Typography.material2021();

    expect(scale.black, stock.black);
    expect(scale.white, stock.white);
  });

  testWidgets('the row of a list draws its title at regular weight under the app theme', (tester) async {
    await tester.pumpWidget(
      ThemeProvider(
        settings: const ThemeSettings(),
        lightDynamic: null,
        darkDynamic: null,
        child: Builder(
          builder: (context) => MaterialApp(theme: ThemeProvider.of(context).light(), home: const SizedBox()),
        ),
      ),
    );

    final textTheme = Theme.of(tester.element(find.byType(SizedBox))).textTheme;

    expect(textTheme.titleMedium!.fontWeight, FontWeight.w400);
    expect(textTheme.labelLarge!.fontWeight, FontWeight.w400);
    expect(textTheme.bodyMedium!.fontWeight, FontWeight.w400);
  });
}
