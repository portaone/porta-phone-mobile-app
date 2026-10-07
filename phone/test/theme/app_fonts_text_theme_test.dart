import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/theme/theme.dart';

/// The typeface of the theme against the weight of each of its styles.
///
/// The styles used to be bound to one face each, chosen before they had a
/// weight, so all of them got the regular face: a style drawn at 500 or 600
/// kept the regular outlines, and only the letters the typeface lacks - drawn
/// by the platform at the weight asked - came out heavier than the rest.
void main() {
  final colors = ColorScheme.fromSeed(seedColor: const Color(0xFF1F618F));

  TextTheme themeFor(String? family, {required bool bundled, bool mayFetch = true}) =>
      AppFonts.textTheme(family, ThemeData.light().textTheme, isLoaded: (_) => bundled, mayFetch: () => mayFetch);

  Future<TextTheme> drawnWith(WidgetTester tester, TextTheme textTheme) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.from(colorScheme: colors, textTheme: textTheme, useMaterial3: true),
        home: const SizedBox(),
      ),
    );
    return Theme.of(tester.element(find.byType(SizedBox))).textTheme;
  }

  testWidgets('a bundled typeface is named by every style, whatever its weight', (tester) async {
    final drawn = await drawnWith(tester, themeFor('Brand Sans', bundled: true));

    for (final style in [drawn.bodyMedium!, drawn.titleMedium!, drawn.labelLarge!, drawn.headlineSmall!]) {
      expect(style.fontFamily, 'Brand Sans');
    }
    expect(drawn.bodyMedium!.fontWeight, FontWeight.w400);
    expect(drawn.titleMedium!.fontWeight, FontWeight.w500, reason: 'the weight stays the style\'s own');
  });

  testWidgets('a heavier copy of a style stays in the same family', (tester) async {
    final drawn = await drawnWith(tester, themeFor('Brand Sans', bundled: true));

    final heavier = drawn.titleMedium!.copyWith(fontWeight: FontWeight.w700);

    expect(heavier.fontFamily, 'Brand Sans', reason: 'the face for 700 is the engine\'s to pick');
  });

  test('a style naming a typeface the build lacks falls back to the bundled one', () {
    final theme = themeFor('Brand Sans', bundled: true);

    expect(theme.bodyMedium!.fontFamilyFallback, ['Brand Sans']);
  });

  test('a theme that names no typeface keeps the platform one', () {
    final base = ThemeData.light().textTheme;

    expect(themeFor(null, bundled: false), base);
  });

  test('a typeface that is neither bundled nor known leaves the theme usable', () {
    final base = ThemeData.light().textTheme;

    expect(themeFor('No Such Typeface', bundled: false), base);
  });

  test('a typeface the build lacks is not asked for where nothing can fetch it', () {
    // Asked for anyway, each style failed on its own a moment later with
    // "allowRuntimeFetching is false but font ... was not found". On
    // google_fonts 8.1 nobody was listening, so every start of such a build
    // was reported as a crash.
    final theme = themeFor('Montserrat', bundled: false, mayFetch: false);

    expect(theme, ThemeData.light().textTheme, reason: 'the platform typeface, with no font load started');
  });

  test('a name written with a stray space still finds the bundled typeface', () {
    // The build trims the name before it names the files after it.
    const fonts = FontsConfig(fontFamily: ' Brand Sans ');

    expect(fonts.family, 'Brand Sans');
    expect(const FontsConfig(fontFamily: '  ').family, isNull);
  });
}
