import 'package:freezed_annotation/freezed_annotation.dart';

part 'color_scheme.config.freezed.dart';

part 'color_scheme.config.g.dart';

@freezed
@JsonSerializable(explicitToJson: true)
class ColorSchemeConfig with _$ColorSchemeConfig {
  /// Creates a [ColorSchemeConfig].
  const ColorSchemeConfig({this.seedColor = '#F95A14', this.colorSchemeOverride = const ColorSchemeOverride()});

  /// The seed color used to generate tonal palettes for the theme.
  final String seedColor;

  /// Explicit overrides for the generated color scheme.
  final ColorSchemeOverride colorSchemeOverride;

  factory ColorSchemeConfig.fromJson(Map<String, Object?> json) => _$ColorSchemeConfigFromJson(json);

  Map<String, Object?> toJson() => _$ColorSchemeConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class ColorSchemeOverride with _$ColorSchemeOverride {
  /// Creates a [ColorSchemeOverride].
  ///
  /// A theme names only the roles it wants different. Every role left out is
  /// generated from the seed colour, which is what the seed is for - giving
  /// each one a fixed fallback here would make the seed decide nothing.
  const ColorSchemeOverride({
    this.primary,
    this.onPrimary,
    this.primaryContainer,
    this.onPrimaryContainer,
    this.primaryFixed,
    this.primaryFixedDim,
    this.onPrimaryFixed,
    this.onPrimaryFixedVariant,
    this.secondary,
    this.onSecondary,
    this.secondaryContainer,
    this.onSecondaryContainer,
    this.secondaryFixed,
    this.secondaryFixedDim,
    this.onSecondaryFixed,
    this.onSecondaryFixedVariant,
    this.tertiary,
    this.onTertiary,
    this.tertiaryContainer,
    this.onTertiaryContainer,
    this.tertiaryFixed,
    this.tertiaryFixedDim,
    this.onTertiaryFixed,
    this.onTertiaryFixedVariant,
    this.error,
    this.onError,
    this.errorContainer,
    this.onErrorContainer,
    this.outline,
    this.outlineVariant,
    this.surface,
    this.onSurface,
    this.surfaceDim,
    this.surfaceBright,
    this.surfaceContainerLowest,
    this.surfaceContainerLow,
    this.surfaceContainer,
    this.surfaceContainerHigh,
    this.surfaceContainerHighest,
    this.onSurfaceVariant,
    this.inverseSurface,
    this.onInverseSurface,
    this.inversePrimary,
    this.shadow,
    this.scrim,
    this.surfaceTint,
  });

  final String? primary;

  final String? onPrimary;

  final String? primaryContainer;

  final String? onPrimaryContainer;

  final String? primaryFixed;

  final String? primaryFixedDim;

  final String? onPrimaryFixed;

  final String? onPrimaryFixedVariant;

  final String? secondary;

  final String? onSecondary;

  final String? secondaryContainer;

  final String? onSecondaryContainer;

  final String? secondaryFixed;

  final String? secondaryFixedDim;

  final String? onSecondaryFixed;

  final String? onSecondaryFixedVariant;

  final String? tertiary;

  final String? onTertiary;

  final String? tertiaryContainer;

  final String? onTertiaryContainer;

  final String? tertiaryFixed;

  final String? tertiaryFixedDim;

  final String? onTertiaryFixed;

  final String? onTertiaryFixedVariant;

  final String? error;

  final String? onError;

  final String? errorContainer;

  final String? onErrorContainer;

  final String? outline;

  final String? outlineVariant;

  final String? surface;

  final String? onSurface;

  final String? surfaceDim;

  final String? surfaceBright;

  final String? surfaceContainerLowest;

  final String? surfaceContainerLow;

  final String? surfaceContainer;

  final String? surfaceContainerHigh;

  final String? surfaceContainerHighest;

  final String? onSurfaceVariant;

  final String? inverseSurface;

  final String? onInverseSurface;

  final String? inversePrimary;

  final String? shadow;

  final String? scrim;

  final String? surfaceTint;

  factory ColorSchemeOverride.fromJson(Map<String, Object?> json) => _$ColorSchemeOverrideFromJson(json);

  Map<String, Object?> toJson() => _$ColorSchemeOverrideToJson(this);
}
