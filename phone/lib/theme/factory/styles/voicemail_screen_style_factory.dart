import 'package:flutter/material.dart';

import 'package:theme_schema/models/theme_page_config.dart';

import 'package:webtrit_phone/features/voicemail/view/voicemail_screen_style.dart';
import 'package:webtrit_phone/features/voicemail/view/voicemail_screen_styles.dart';

import 'package:webtrit_phone/theme/extension/extension.dart';

import '../theme_style_factory.dart';

class VoicemailScreenStyleFactory implements ThemeStyleFactory<VoicemailScreenStyles> {
  VoicemailScreenStyleFactory(this.colors, this.config, {this.appBarTheme});

  final ColorScheme colors;
  final VoicemailPageConfig config;
  final AppBarTheme? appBarTheme;

  @override
  VoicemailScreenStyles create() {
    final backgroundStyle = config.background?.toStyle();

    return VoicemailScreenStyles(
      primary: VoicemailScreenStyle(
        background: backgroundStyle,
        appBarBlurredSurface: config.appBarBlurredSurface?.toStyle(),
        contentThemeOverride: config.themeOverride.mode.toThemeMode(),
        applyToAppBar: config.themeOverride.applyToAppBar,
        appBarTheme: appBarTheme,
      ),
    );
  }
}
