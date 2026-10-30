import 'package:freezed_annotation/freezed_annotation.dart';

part 'icon_theme_data_config.freezed.dart';

part 'icon_theme_data_config.g.dart';

@freezed
@JsonSerializable(explicitToJson: true)
class IconThemeDataConfig with _$IconThemeDataConfig {
  const IconThemeDataConfig({
    this.size,
    this.fill,
    this.weight,
    this.grade,
    this.opticalSize,
    this.color,
    this.opacity,
    this.shadows,
    this.applyTextScaling,
  });

  /// The default size for icons.
  final double? size;

  /// The default fill for icons (0.0 to 1.0).
  /// Useful for variable fonts (e.g. Material Symbols).
  final double? fill;

  /// The default weight for icons (e.g. 400.0).
  /// Useful for variable fonts.
  final double? weight;

  /// The default grade for icons.
  /// Useful for variable fonts.
  final double? grade;

  /// The default optical size for icons.
  /// Useful for variable fonts.
  final double? opticalSize;

  /// The default color for icons (hex string).
  final String? color;

  /// An opacity to apply to both explicit and default icon colors.
  final double? opacity;

  /// A list of shadows to apply to the icons.
  final List<ShadowConfig>? shadows;

  /// Whether to apply text scaling to the icons.
  final bool? applyTextScaling;

  factory IconThemeDataConfig.fromJson(Map<String, Object?> json) => _$IconThemeDataConfigFromJson(json);

  Map<String, Object?> toJson() => _$IconThemeDataConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class ShadowConfig with _$ShadowConfig {
  const ShadowConfig({this.color, this.offset, this.blurRadius = 0.0});

  /// Color of the shadow (hex string).
  final String? color;

  /// The displacement of the shadow.
  final OffsetConfig? offset;

  /// The blur radius of the shadow.
  final double blurRadius;

  factory ShadowConfig.fromJson(Map<String, Object?> json) => _$ShadowConfigFromJson(json);

  Map<String, Object?> toJson() => _$ShadowConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class OffsetConfig with _$OffsetConfig {
  const OffsetConfig({this.dx = 0.0, this.dy = 0.0});

  final double dx;

  final double dy;

  factory OffsetConfig.fromJson(Map<String, Object?> json) => _$OffsetConfigFromJson(json);

  Map<String, Object?> toJson() => _$OffsetConfigToJson(this);
}
