import 'package:material_ui/material_ui.dart';

import 'package:theme_schema/theme_schema.dart';

import '../styles/styles.dart';

import 'theme_json_serializable.dart';
import 'box_fit_config_extension.dart';

extension PageBackgroundConfigExtension on PageBackground {
  BackgroundStyle toStyle() {
    return switch (this) {
      final PageBackgroundSolid s => SolidBackgroundStyle(color: s.color.toColor()),
      final PageBackgroundGradient g => GradientBackgroundStyle(
        gradient: LinearGradient(
          colors: g.colors.map((c) => c.toColor()).toList(),
          stops: g.stops.length == g.colors.length ? g.stops : null,
          begin: Alignment(g.beginX, g.beginY),
          end: Alignment(g.endX, g.endY),
        ),
      ),
      final PageBackgroundImage i => ImageBackgroundStyle(
        imageUrl: i.imageUrl,
        opacity: i.opacity,
        fit: i.fit.boxFit ?? BoxFit.cover,
      ),
    };
  }
}
