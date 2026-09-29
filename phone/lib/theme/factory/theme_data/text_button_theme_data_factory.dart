import 'package:material_ui/material_ui.dart';

import '../theme_style_factory.dart';

class TextButtonThemeDataFactory implements ThemeStyleFactory<TextButtonThemeData> {
  TextButtonThemeDataFactory(this.colors);

  final ColorScheme colors;

  @override
  TextButtonThemeData create() {
    return TextButtonThemeData(style: TextButton.styleFrom(shape: const StadiumBorder()));
  }
}
