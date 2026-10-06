import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/theme/theme.dart';

import '../theme_style_factory.dart';

class TextThemeDataFactory implements ThemeStyleFactory<TextTheme> {
  TextThemeDataFactory(this.colors, this.config, this.themeData);

  final ColorScheme colors;
  final FontsConfig config;
  final ThemeData themeData;

  @override
  TextTheme create() => AppFonts.textTheme(config.family, themeData.textTheme);
}
