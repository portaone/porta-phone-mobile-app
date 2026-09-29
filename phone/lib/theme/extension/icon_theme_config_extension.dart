import 'package:material_ui/material_ui.dart';

import 'package:theme_schema/theme_schema.dart';

import '../extension/extension.dart';

extension IconThemeConfigExtension on IconThemeDataConfig {
  IconThemeData toIconThemeData() {
    return IconThemeData(
      size: size,
      fill: fill,
      weight: weight,
      grade: grade,
      opticalSize: opticalSize,
      color: color?.toColor(),
      opacity: opacity,
      shadows: shadows?.map((s) => s.toShadow()).toList(),
      applyTextScaling: applyTextScaling,
    );
  }
}

extension ShadowConfigExtension on ShadowConfig {
  Shadow toShadow() {
    return Shadow(
      color: color?.toColor() ?? const Color(0xFF000000),
      offset: offset?.toOffset() ?? Offset.zero,
      blurRadius: blurRadius,
    );
  }
}

extension OffsetConfigExtension on OffsetConfig {
  Offset toOffset() => Offset(dx, dy);
}
