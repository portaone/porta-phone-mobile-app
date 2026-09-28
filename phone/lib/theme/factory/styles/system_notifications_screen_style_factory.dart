import 'package:flutter/material.dart';

import 'package:theme_schema/models/theme_page_config.dart';

import 'package:webtrit_phone/features/system_notifications/view/system_notifications_screen_style.dart';
import 'package:webtrit_phone/features/system_notifications/view/system_notifications_screen_styles.dart';

import 'package:webtrit_phone/theme/extension/extension.dart';

import '../theme_style_factory.dart';

class SystemNotificationsScreenStyleFactory implements ThemeStyleFactory<SystemNotificationsScreenStyles> {
  SystemNotificationsScreenStyleFactory(this.colors, this.config, {this.appBarTheme});

  final ColorScheme colors;
  final SystemNotificationsPageConfig config;
  final AppBarTheme? appBarTheme;

  @override
  SystemNotificationsScreenStyles create() {
    final backgroundStyle = config.background?.toStyle();

    return SystemNotificationsScreenStyles(
      primary: SystemNotificationsScreenStyle(
        background: backgroundStyle,
        appBarBlurredSurface: config.appBarBlurredSurface?.toStyle(),
        contentThemeOverride: config.themeOverride.mode.toThemeMode(),
        applyToAppBar: config.themeOverride.applyToAppBar,
        appBarTheme: appBarTheme,
      ),
    );
  }
}
