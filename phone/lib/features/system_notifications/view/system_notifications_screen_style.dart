import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/blurred_surface.dart';

class SystemNotificationsScreenStyle extends BaseScreenStyle with Diagnosticable {
  const SystemNotificationsScreenStyle({
    super.background,
    super.appBarBlurredSurface,
    super.appBarTheme,
    this.contentThemeOverride,
    this.applyToAppBar,
  });

  final ThemeMode? contentThemeOverride;
  final bool? applyToAppBar;

  SystemNotificationsScreenStyle copyWith({
    BackgroundStyle? background,
    BlurredSurfaceStyle? appBarBlurredSurface,
    AppBarTheme? appBarTheme,
    ThemeMode? contentThemeOverride,
    bool? applyToAppBar,
  }) {
    return SystemNotificationsScreenStyle(
      background: background ?? this.background,
      appBarBlurredSurface: appBarBlurredSurface ?? this.appBarBlurredSurface,
      appBarTheme: appBarTheme ?? this.appBarTheme,
      contentThemeOverride: contentThemeOverride ?? this.contentThemeOverride,
      applyToAppBar: applyToAppBar ?? this.applyToAppBar,
    );
  }

  static SystemNotificationsScreenStyle merge(SystemNotificationsScreenStyle? a, SystemNotificationsScreenStyle? b) {
    if (a == null) return b ?? const SystemNotificationsScreenStyle();
    if (b == null) return a;

    return SystemNotificationsScreenStyle(
      background: b.background ?? a.background,
      appBarBlurredSurface: BlurredSurfaceStyle.merge(a.appBarBlurredSurface, b.appBarBlurredSurface),
      appBarTheme: b.appBarTheme ?? a.appBarTheme,
      contentThemeOverride: b.contentThemeOverride ?? a.contentThemeOverride,
      applyToAppBar: b.applyToAppBar ?? a.applyToAppBar,
    );
  }

  static SystemNotificationsScreenStyle lerp(
    SystemNotificationsScreenStyle? a,
    SystemNotificationsScreenStyle? b,
    double t,
  ) {
    return SystemNotificationsScreenStyle(
      background: BaseScreenStyle.lerp(a?.background, b?.background, t),
      appBarBlurredSurface: BlurredSurfaceStyle.lerp(a?.appBarBlurredSurface, b?.appBarBlurredSurface, t),
      appBarTheme: AppBarTheme.lerp(a?.appBarTheme, b?.appBarTheme, t),
      contentThemeOverride: t < 0.5 ? a?.contentThemeOverride : b?.contentThemeOverride,
      applyToAppBar: t < 0.5 ? a?.applyToAppBar : b?.applyToAppBar,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<BackgroundStyle?>('background', background))
      ..add(EnumProperty<ThemeMode?>('contentThemeOverride', contentThemeOverride))
      ..add(DiagnosticsProperty<bool?>('applyToAppBar', applyToAppBar));
  }
}
