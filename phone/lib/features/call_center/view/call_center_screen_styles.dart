import 'package:flutter/material.dart';

import 'call_center_screen_style.dart';

class CallCenterScreenStyles extends ThemeExtension<CallCenterScreenStyles> {
  const CallCenterScreenStyles({required this.primary});

  final CallCenterScreenStyle? primary;

  @override
  CallCenterScreenStyles copyWith({CallCenterScreenStyle? primary}) {
    return CallCenterScreenStyles(primary: primary ?? this.primary);
  }

  @override
  ThemeExtension<CallCenterScreenStyles> lerp(ThemeExtension<CallCenterScreenStyles>? other, double t) {
    if (other is! CallCenterScreenStyles) return this;
    return CallCenterScreenStyles(primary: CallCenterScreenStyle.lerp(primary, other.primary, t));
  }
}
