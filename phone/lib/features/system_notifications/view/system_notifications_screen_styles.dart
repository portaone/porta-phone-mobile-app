import 'package:material_ui/material_ui.dart';

import 'system_notifications_screen_style.dart';

class SystemNotificationsScreenStyles extends ThemeExtension<SystemNotificationsScreenStyles> {
  const SystemNotificationsScreenStyles({required this.primary});

  final SystemNotificationsScreenStyle? primary;

  @override
  SystemNotificationsScreenStyles copyWith({SystemNotificationsScreenStyle? primary}) {
    return SystemNotificationsScreenStyles(primary: primary ?? this.primary);
  }

  @override
  ThemeExtension<SystemNotificationsScreenStyles> lerp(
    ThemeExtension<SystemNotificationsScreenStyles>? other,
    double t,
  ) {
    if (other is! SystemNotificationsScreenStyles) return this;
    return SystemNotificationsScreenStyles(primary: SystemNotificationsScreenStyle.lerp(primary, other.primary, t));
  }
}
