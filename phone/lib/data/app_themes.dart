import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:equatable/equatable.dart';

import 'package:webtrit_phone/app/assets.gen.dart';
import 'package:webtrit_phone/theme/theme.dart';

/// What the app renders and may do: its theme, its feature config and the
/// pages it embeds.
///
/// Standalone, all three are read from the bundled `assets/themes/` documents
/// by [init]. A host that embeds the app (the theme configurator's realtime
/// preview) has no such bundle - its bundle carries this package's assets under
/// `packages/webtrit_phone/`, where the catalogue paths do not reach - and
/// holds the documents it wants drawn anyway, so it builds one with
/// [AppThemes.new] and hands it to `bootstrap` instead.
class AppThemes {
  const AppThemes({required this.values, required this.appConfig, required this.embeddedResources});

  /// Reads the bundled documents. The default `bootstrap` source.
  static Future<AppThemes> init() async {
    final themeColorSchemeLightConfigJson = await _getJson(Assets.themes.originalColorSchemeLightConfig);
    final themeColorSchemeDarkConfigJson = await _getJson(Assets.themes.originalColorSchemeDarkConfig);

    final themeWidgetLightConfigJson = await _getJson(Assets.themes.originalWidgetLightConfig);
    final themePageLightConfigJson = await _getJson(Assets.themes.originalPageLightConfig);

    final themeWidgetDarkConfigJson = await _getJson(Assets.themes.originalWidgetDarkConfig);
    final themePageDarkConfigJson = await _getJson(Assets.themes.originalPageDarkConfig);

    final appConfigJson = await _getJson(Assets.themes.appConfig);
    final eppEmbeddedConfigJson = await _getJson(Assets.themes.appEmbeddedConfig);

    final themeColorSchemeLightConfig = ColorSchemeConfig.fromJson(themeColorSchemeLightConfigJson);
    final themeColorSchemeDarkConfig = ColorSchemeConfig.fromJson(themeColorSchemeDarkConfigJson);

    final themeWidgetLightConfig = ThemeWidgetConfig.fromJson(themeWidgetLightConfigJson);
    final themePageLightConfig = ThemePageConfig.fromJson(themePageLightConfigJson);

    final themeWidgetDarkConfig = ThemeWidgetConfig.fromJson(themeWidgetDarkConfigJson);
    final themePageDarkConfig = ThemePageConfig.fromJson(themePageDarkConfigJson);

    final appConfig = AppConfig.fromJson(appConfigJson);
    final embeddedResources = (eppEmbeddedConfigJson as List)
        .map<EmbeddedResource>((e) => EmbeddedResource.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);

    final settings = ThemeSettings(
      lightColorSchemeConfig: themeColorSchemeLightConfig,
      darkColorSchemeConfig: themeColorSchemeDarkConfig,
      themeWidgetLightConfig: themeWidgetLightConfig,
      themePageLightConfig: themePageLightConfig,
      themeWidgetDarkConfig: themeWidgetDarkConfig,
      themePageDarkConfig: themePageDarkConfig,
    );

    final themes = [AppTheme(settings: settings)];

    await AppFonts.load({?themeWidgetLightConfig.fonts.family, ?themeWidgetDarkConfig.fonts.family});

    return AppThemes(values: themes, appConfig: appConfig, embeddedResources: embeddedResources);
  }

  static Future<dynamic> _getJson(String path) async {
    return jsonDecode(await rootBundle.loadString(path));
  }

  final List<AppTheme> values;
  final AppConfig appConfig;
  final List<EmbeddedResource> embeddedResources;
}

class AppTheme extends Equatable {
  const AppTheme({required this.settings});

  final ThemeSettings settings;

  @override
  List<Object?> get props => [settings];
}
