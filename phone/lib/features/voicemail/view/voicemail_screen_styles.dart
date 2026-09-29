import 'package:flutter/material.dart';

import 'voicemail_screen_style.dart';

class VoicemailScreenStyles extends ThemeExtension<VoicemailScreenStyles> {
  const VoicemailScreenStyles({required this.primary});

  final VoicemailScreenStyle? primary;

  @override
  VoicemailScreenStyles copyWith({VoicemailScreenStyle? primary}) {
    return VoicemailScreenStyles(primary: primary ?? this.primary);
  }

  @override
  ThemeExtension<VoicemailScreenStyles> lerp(ThemeExtension<VoicemailScreenStyles>? other, double t) {
    if (other is! VoicemailScreenStyles) return this;
    return VoicemailScreenStyles(primary: VoicemailScreenStyle.lerp(primary, other.primary, t));
  }
}
