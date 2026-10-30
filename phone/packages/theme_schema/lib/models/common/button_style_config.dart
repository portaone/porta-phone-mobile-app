import 'package:freezed_annotation/freezed_annotation.dart';

import 'geometry_config.dart';
import 'text_style_config.dart';

part 'button_style_config.freezed.dart';

part 'button_style_config.g.dart';

/// Represents a configurable button style used for UI theming.
/// Maps to Flutter's [ButtonStyle].
@freezed
@JsonSerializable(explicitToJson: true)
class ButtonStyleConfig with _$ButtonStyleConfig {
  const ButtonStyleConfig({
    /// The style for a button's text descendants.
    this.textStyle,

    /// The button's background fill color in hex format.
    this.backgroundColor,

    /// The color for the button's text/icon descendants in hex format.
    this.foregroundColor,

    /// The highlight color for states (focused, hovered, pressed) in hex format.
    this.overlayColor,

    /// The shadow color in hex format.
    this.shadowColor,

    /// The surface tint color in hex format.
    this.surfaceTintColor,

    /// The elevation of the button.
    this.elevation,

    /// The padding between the button's boundary and its child.
    this.padding,

    /// The minimum size of the button.
    this.minimumSize,

    /// The fixed size of the button.
    this.fixedSize,

    /// The maximum size of the button.
    this.maximumSize,

    /// The icon's color in hex format.
    this.iconColor,

    /// The icon's size.
    this.iconSize,

    /// The color and weight of the button's outline.
    this.side,

    /// The shape of the button (e.g., rounded corners).
    this.shape,

    /// Defines how compact the button's layout will be.
    this.visualDensity,

    /// The duration of animated changes in milliseconds.
    this.animationDuration,

    /// The button's background fill color in hex format while it is switched on.
    this.selectedBackgroundColor,

    /// The color for the text/icon descendants in hex format while the button is switched on.
    this.selectedForegroundColor,

    /// The icon's color in hex format while the button is switched on.
    this.selectedIconColor,

    /// The button's background fill color in hex format when the button is disabled.
    this.disabledBackgroundColor,

    /// The color for the button's text/icon descendants in hex format when the button is disabled.
    this.disabledForegroundColor,

    /// The icon's color in hex format when the button is disabled.
    this.disabledIconColor,

    /// The shadow color in hex format when the button is disabled.
    this.disabledShadowColor,
  });

  /// The style for a button's text descendants.
  final TextStyleConfig? textStyle;

  /// The button's background fill color in hex format.
  final String? backgroundColor;

  /// The color for the button's text/icon descendants in hex format.
  final String? foregroundColor;

  /// The button's background fill color in hex format while it is switched on.
  ///
  /// Only reaches the screen for a control that can be on or off - a mute or a
  /// camera button. Left empty, the switched-on look comes from the palette.
  final String? selectedBackgroundColor;

  /// The color for the text/icon descendants in hex format while the button is switched on.
  final String? selectedForegroundColor;

  /// The icon's color in hex format while the button is switched on.
  final String? selectedIconColor;

  /// The button's background fill color in hex format when the button is disabled.
  final String? disabledBackgroundColor;

  /// The color for the button's text/icon descendants in hex format when the button is disabled.
  final String? disabledForegroundColor;

  /// The icon's color in hex format when the button is disabled.
  final String? disabledIconColor;

  /// The shadow color in hex format when the button is disabled.
  final String? disabledShadowColor;

  /// The highlight color for states (focused, hovered, pressed) in hex format.
  final String? overlayColor;

  /// The shadow color in hex format.
  final String? shadowColor;

  /// The surface tint color in hex format.
  final String? surfaceTintColor;

  /// The elevation of the button.
  final double? elevation;

  /// The padding between the button's boundary and its child.
  final EdgeInsetsConfig? padding;

  /// The minimum size of the button.
  final SizeConfig? minimumSize;

  /// The fixed size of the button.
  final SizeConfig? fixedSize;

  /// The maximum size of the button.
  final SizeConfig? maximumSize;

  /// The icon's color in hex format.
  final String? iconColor;

  /// The icon's size.
  final double? iconSize;

  /// The color and weight of the button's outline.
  final BorderSideConfig? side;

  /// The shape of the button (e.g., rounded corners).
  final ShapeBorderConfig? shape;

  /// Defines how compact the button's layout will be.
  final VisualDensityConfig? visualDensity;

  /// The duration of animated changes in milliseconds.
  final int? animationDuration;

  factory ButtonStyleConfig.fromJson(Map<String, Object?> json) => _$ButtonStyleConfigFromJson(json);

  Map<String, Object?> toJson() => _$ButtonStyleConfigToJson(this);
}
