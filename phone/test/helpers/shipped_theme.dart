import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/theme/theme.dart';

/// The theme the app ships with, read from `assets/themes/` the way the app
/// reads it at startup.
///
/// A layout test needs it rather than the empty [ThemeSettings]: the logos,
/// font sizes and paddings that make a screen tall come from these documents,
/// and without them a screen fits places the real app does not.
///
/// Like the app at startup, it turns off fetching typefaces at run time, so
/// the brand typeface falls back to the test one instead of a network call.
ThemeSettings shippedThemeSettings() {
  GoogleFonts.config.allowRuntimeFetching = false;
  Map<String, Object?> read(String name) =>
      jsonDecode(File('assets/themes/$name').readAsStringSync()) as Map<String, Object?>;

  return ThemeSettings(
    lightColorSchemeConfig: ColorSchemeConfig.fromJson(read('original.color_scheme.light.config.json')),
    darkColorSchemeConfig: ColorSchemeConfig.fromJson(read('original.color_scheme.dark.config.json')),
    themeWidgetLightConfig: ThemeWidgetConfig.fromJson(read('original.widget.light.config.json')),
    themePageLightConfig: ThemePageConfig.fromJson(read('original.page.light.config.json')),
    themeWidgetDarkConfig: ThemeWidgetConfig.fromJson(read('original.widget.dark.config.json')),
    themePageDarkConfig: ThemePageConfig.fromJson(read('original.page.dark.config.json')),
  );
}

/// [home] in an app themed as the shipped app is, in English: what a layout
/// test pumps to see a screen as a user would.
Widget withShippedTheme(Widget home) {
  return ThemeProvider(
    settings: shippedThemeSettings(),
    lightDynamic: null,
    darkDynamic: null,
    child: Builder(
      builder: (context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeProvider.of(context).light(),
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
}
