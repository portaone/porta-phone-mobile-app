import 'package:material_ui/material_ui.dart';

import 'package:theme_schema/models/theme_page_config.dart';

import 'package:webtrit_phone/features/call_center/view/call_center_screen_style.dart';
import 'package:webtrit_phone/features/call_center/view/call_center_screen_styles.dart';

import 'package:webtrit_phone/theme/extension/extension.dart';

import '../theme_style_factory.dart';

class CallCenterScreenStyleFactory implements ThemeStyleFactory<CallCenterScreenStyles> {
  CallCenterScreenStyleFactory(this.colors, this.config, {this.appBarTheme});

  final ColorScheme colors;
  final CallCenterPageConfig config;
  final AppBarTheme? appBarTheme;

  @override
  CallCenterScreenStyles create() {
    final backgroundStyle = config.background?.toStyle();

    return CallCenterScreenStyles(
      primary: CallCenterScreenStyle(
        background: backgroundStyle,
        appBarBlurredSurface: config.appBarBlurredSurface?.toStyle(),
        contentThemeOverride: config.themeOverride.mode.toThemeMode(),
        applyToAppBar: config.themeOverride.applyToAppBar,
        appBarTheme: appBarTheme,
      ),
    );
  }
}
