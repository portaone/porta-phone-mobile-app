import 'package:material_ui/material_ui.dart';

import '../theme_style_factory.dart';

class OutlinedButtonThemeFataFactory implements ThemeStyleFactory<OutlinedButtonThemeData> {
  OutlinedButtonThemeFataFactory(this.colors);

  final ColorScheme colors;

  @override
  OutlinedButtonThemeData create() {
    return OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: const StadiumBorder()));
  }
}
