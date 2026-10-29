import 'package:freezed_annotation/freezed_annotation.dart';

import 'common/common.dart';
import 'resources/image_source.dart';

part 'theme_widget_config.freezed.dart';

part 'theme_widget_config.g.dart';

@freezed
@JsonSerializable(explicitToJson: true)
class ThemeWidgetConfig with _$ThemeWidgetConfig {
  const ThemeWidgetConfig({
    this.fonts = const FontsConfig(),
    this.button = const ButtonWidgetConfig(),
    this.group = const GroupWidgetConfig(),
    this.bar = const BarWidgetConfig(),
    this.imageAssets = const ImageAssetsConfig(),
    this.input = const InputWidgetConfig(),
    this.text = const TextWidgetConfig(),
    this.dialog = const DialogWidgetConfig(),
    this.statuses = const StatusesWidgetConfig(),
  });

  final FontsConfig fonts;

  final ButtonWidgetConfig button;

  final GroupWidgetConfig? group;

  final BarWidgetConfig bar;

  final ImageAssetsConfig imageAssets;

  final InputWidgetConfig input;

  final TextWidgetConfig text;

  final DialogWidgetConfig dialog;

  final StatusesWidgetConfig statuses;

  factory ThemeWidgetConfig.fromJson(Map<String, Object?> json) => _$ThemeWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$ThemeWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class FontsConfig with _$FontsConfig {
  const FontsConfig({this.fontFamily});

  final String? fontFamily;

  factory FontsConfig.fromJson(Map<String, Object?> json) => _$FontsConfigFromJson(json);

  Map<String, Object?> toJson() => _$FontsConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class ButtonWidgetConfig with _$ButtonWidgetConfig {
  const ButtonWidgetConfig({this.primaryElevatedButton});

  final ButtonStyleConfig? primaryElevatedButton;

  factory ButtonWidgetConfig.fromJson(Map<String, Object?> json) => _$ButtonWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$ButtonWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class GroupWidgetConfig with _$GroupWidgetConfig {
  const GroupWidgetConfig({this.groupTitleListTile = const GroupTitleListTileWidgetConfig()});

  final GroupTitleListTileWidgetConfig groupTitleListTile;

  factory GroupWidgetConfig.fromJson(Map<String, Object?> json) => _$GroupWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$GroupWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class BarWidgetConfig with _$BarWidgetConfig {
  const BarWidgetConfig({
    this.bottomNavigationBar = const BottomNavigationBarWidgetConfig(),
    this.appBarConfig = const AppBarConfig(),
    this.tabBarConfig = const TabBarConfig(),
  });

  final BottomNavigationBarWidgetConfig bottomNavigationBar;

  final AppBarConfig appBarConfig;

  final TabBarConfig tabBarConfig;

  factory BarWidgetConfig.fromJson(Map<String, Object?> json) => _$BarWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$BarWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class BottomNavigationBarWidgetConfig with _$BottomNavigationBarWidgetConfig {
  const BottomNavigationBarWidgetConfig({
    this.backgroundColor,
    this.elevation,
    this.selectedItemColor,
    this.unSelectedItemColor,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
    this.selectedIconTheme,
    this.unselectedIconTheme,
    this.showSelectedLabels,
    this.showUnselectedLabels,
  });

  /// Background color in hex format, drawn as given. A bar that should show
  /// what is behind it says so in the colour's own alpha channel - the widget
  /// used to apply an alpha of its own, which no brand asked for and none
  /// could correct.
  final String? backgroundColor;

  final double? elevation;

  /// Colours the selected item. A caption takes it only while
  /// [selectedLabelStyle] names no colour of its own: Flutter uses a label
  /// style's colour *instead of* this one, which is why a style is the way to
  /// paint captions differently from icons.
  final String? selectedItemColor;

  final String? unSelectedItemColor;

  final TextStyleConfig? selectedLabelStyle;

  final TextStyleConfig? unselectedLabelStyle;

  final IconThemeDataConfig? selectedIconTheme;

  final IconThemeDataConfig? unselectedIconTheme;

  final bool? showSelectedLabels;

  final bool? showUnselectedLabels;

  factory BottomNavigationBarWidgetConfig.fromJson(Map<String, Object?> json) =>
      _$BottomNavigationBarWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$BottomNavigationBarWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class GroupTitleListTileWidgetConfig with _$GroupTitleListTileWidgetConfig {
  const GroupTitleListTileWidgetConfig({
    /// Background color in hex format.
    this.backgroundColor,

    /// Full text style configuration (font, size, color, etc.).
    this.textStyle,
  });

  final String? backgroundColor;

  final TextStyleConfig? textStyle;

  factory GroupTitleListTileWidgetConfig.fromJson(Map<String, Object?> json) =>
      _$GroupTitleListTileWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$GroupTitleListTileWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class ImageAssetsConfig with _$ImageAssetsConfig {
  const ImageAssetsConfig({
    this.defaultPlaceholderImage,
    this.appIcon = const AppIconWidgetConfig(),
    this.leadingAvatarStyle = const LeadingAvatarStyleConfig(),
  });

  final ImageSource? defaultPlaceholderImage;

  final AppIconWidgetConfig appIcon;

  final LeadingAvatarStyleConfig leadingAvatarStyle;

  static const String metadataPrimaryOnboardingLogoUrl = 'primaryOnboardingLogoUrl';

  static const String metadataSecondaryOnboardingLogoUrl = 'secondaryOnboardingLogoUrl';

  factory ImageAssetsConfig.fromJson(Map<String, Object?> json) => _$ImageAssetsConfigFromJson(json);

  Map<String, Object?> toJson() => _$ImageAssetsConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class AppIconWidgetConfig with _$AppIconWidgetConfig {
  const AppIconWidgetConfig({this.color});

  final String? color;

  factory AppIconWidgetConfig.fromJson(Map<String, Object?> json) => _$AppIconWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$AppIconWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class InputWidgetConfig with _$InputWidgetConfig {
  const InputWidgetConfig({this.primary = const TextFormFieldWidgetConfig()});

  final TextFormFieldWidgetConfig primary;

  factory InputWidgetConfig.fromJson(Map<String, Object?> json) => _$InputWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$InputWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class TextFormFieldWidgetConfig with _$TextFormFieldWidgetConfig {
  const TextFormFieldWidgetConfig({this.labelColor, this.border = const InputBorderWidgetConfig()});

  final String? labelColor;

  final InputBorderWidgetConfig border;

  factory TextFormFieldWidgetConfig.fromJson(Map<String, Object?> json) => _$TextFormFieldWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$TextFormFieldWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class InputBorderWidgetConfig with _$InputBorderWidgetConfig {
  const InputBorderWidgetConfig({
    this.disabled = const BorderWidgetConfig(),
    this.focused = const BorderWidgetConfig(),
    this.any = const BorderWidgetConfig(),
  });

  final BorderWidgetConfig disabled;

  final BorderWidgetConfig focused;

  final BorderWidgetConfig any;

  factory InputBorderWidgetConfig.fromJson(Map<String, Object?> json) => _$InputBorderWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$InputBorderWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class BorderWidgetConfig with _$BorderWidgetConfig {
  const BorderWidgetConfig({this.typicalColor, this.errorColor});

  final String? typicalColor;

  final String? errorColor;

  factory BorderWidgetConfig.fromJson(Map<String, Object?> json) => _$BorderWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$BorderWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class TextWidgetConfig with _$TextWidgetConfig {
  const TextWidgetConfig({
    this.selection = const TextSelectionWidgetConfig(),
    this.linkify = const LinkifyWidgetConfig(),
  });

  final TextSelectionWidgetConfig selection;

  final LinkifyWidgetConfig linkify;

  factory TextWidgetConfig.fromJson(Map<String, Object?> json) => _$TextWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$TextWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class TextSelectionWidgetConfig with _$TextSelectionWidgetConfig {
  const TextSelectionWidgetConfig({this.cursorColor, this.selectionColor, this.selectionHandleColor});

  final String? cursorColor;

  final String? selectionColor;

  final String? selectionHandleColor;

  factory TextSelectionWidgetConfig.fromJson(Map<String, Object?> json) => _$TextSelectionWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$TextSelectionWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class LinkifyWidgetConfig with _$LinkifyWidgetConfig {
  const LinkifyWidgetConfig({this.styleColor, this.linkifyStyleColor});

  final String? styleColor;

  final String? linkifyStyleColor;

  factory LinkifyWidgetConfig.fromJson(Map<String, Object?> json) => _$LinkifyWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$LinkifyWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class DialogWidgetConfig with _$DialogWidgetConfig {
  const DialogWidgetConfig({
    this.theme = const DialogThemeConfig(),
    this.confirmDialog = const ConfirmDialogWidgetConfig(),
    this.snackBar = const SnackBarWidgetConfig(),
  });

  /// Baseline appearance applied to every dialog via [ThemeData.dialogTheme].
  ///
  /// Material 3 derives the dialog background from `surfaceContainerHigh`, which
  /// can resolve to an unreadable color in some color schemes; this config lets a
  /// theme pin a predictable surface/text/shape for all dialogs.
  final DialogThemeConfig theme;

  final ConfirmDialogWidgetConfig confirmDialog;

  final SnackBarWidgetConfig snackBar;

  factory DialogWidgetConfig.fromJson(Map<String, Object?> json) => _$DialogWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$DialogWidgetConfigToJson(this);
}

/// Global dialog appearance mapped to [ThemeData.dialogTheme].
///
/// All fields are nullable so existing configs keep working; a null field falls
/// back to a readable color-scheme role (or the Material default) in the bridge.
@freezed
@JsonSerializable(explicitToJson: true)
class DialogThemeConfig with _$DialogThemeConfig {
  const DialogThemeConfig({
    this.backgroundColor,
    this.surfaceTintColor,
    this.shadowColor,
    this.barrierColor,
    this.elevation,
    this.borderRadius,
    this.titleTextStyle,
    this.contentTextStyle,
  });

  final String? backgroundColor;

  final String? surfaceTintColor;

  final String? shadowColor;

  final String? barrierColor;

  final double? elevation;

  final double? borderRadius;

  final TextStyleConfig? titleTextStyle;

  final TextStyleConfig? contentTextStyle;

  factory DialogThemeConfig.fromJson(Map<String, Object?> json) => _$DialogThemeConfigFromJson(json);

  Map<String, Object?> toJson() => _$DialogThemeConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class ConfirmDialogWidgetConfig with _$ConfirmDialogWidgetConfig {
  const ConfirmDialogWidgetConfig({
    this.activeButtonColor1,
    this.activeButtonColor2,
    this.defaultButtonColor,
    this.backgroundColor,
    this.surfaceTintColor,
    this.elevation,
    this.borderRadius,
    this.titleTextStyle,
    this.contentTextStyle,
  });

  final String? activeButtonColor1;

  final String? activeButtonColor2;

  final String? defaultButtonColor;

  /// Confirm-dialog-only overrides layered on top of [DialogThemeConfig];
  /// when null the dialog inherits [ThemeData.dialogTheme].
  final String? backgroundColor;

  final String? surfaceTintColor;

  final double? elevation;

  final double? borderRadius;

  final TextStyleConfig? titleTextStyle;

  final TextStyleConfig? contentTextStyle;

  factory ConfirmDialogWidgetConfig.fromJson(Map<String, Object?> json) => _$ConfirmDialogWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$ConfirmDialogWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class SnackBarWidgetConfig with _$SnackBarWidgetConfig {
  const SnackBarWidgetConfig({
    this.successBackgroundColor = '#75B943',
    this.errorBackgroundColor = '#E74C3C',
    this.infoBackgroundColor = '#494949',
    this.warningBackgroundColor = '#F95A14',
  });

  final String successBackgroundColor;

  final String errorBackgroundColor;

  final String infoBackgroundColor;

  final String warningBackgroundColor;

  factory SnackBarWidgetConfig.fromJson(Map<String, Object?> json) => _$SnackBarWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$SnackBarWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class StatusesWidgetConfig with _$StatusesWidgetConfig {
  const StatusesWidgetConfig({
    this.registrationStatuses = const RegistrationStatusesWidgetConfig(),
    this.callStatuses = const CallStatusesWidgetConfig(),
  });

  final RegistrationStatusesWidgetConfig registrationStatuses;

  final CallStatusesWidgetConfig callStatuses;

  factory StatusesWidgetConfig.fromJson(Map<String, Object?> json) => _$StatusesWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$StatusesWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class RegistrationStatusesWidgetConfig with _$RegistrationStatusesWidgetConfig {
  const RegistrationStatusesWidgetConfig({this.online = '#75B943', this.offline = '#EEF3F6'});

  final String online;

  final String offline;

  factory RegistrationStatusesWidgetConfig.fromJson(Map<String, Object?> json) =>
      _$RegistrationStatusesWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$RegistrationStatusesWidgetConfigToJson(this);
}

@freezed
@JsonSerializable(explicitToJson: true)
class CallStatusesWidgetConfig with _$CallStatusesWidgetConfig {
  const CallStatusesWidgetConfig({
    this.connectivityNone = '#E74C3C',
    this.connectError = '#E74C3C',
    this.appUnregistered = '#494949',
    this.connectIssue = '#E74C3C',
    this.inProgress = '#123752',
    this.ready = '#75B943',
  });

  final String connectivityNone;

  final String connectError;

  final String appUnregistered;

  final String connectIssue;

  final String inProgress;

  final String ready;

  factory CallStatusesWidgetConfig.fromJson(Map<String, Object?> json) => _$CallStatusesWidgetConfigFromJson(json);

  Map<String, Object?> toJson() => _$CallStatusesWidgetConfigToJson(this);
}

/// Defines default property values for descendant [TabBar] widgets.
///
/// This configuration maps to [TabBarThemeData] and is typically used to
/// describe the overall [ThemeData.tabBarTheme]. Properties are null by default,
/// allowing the widget to fall back to parent theme values.
@freezed
@JsonSerializable(explicitToJson: true)
class TabBarConfig with _$TabBarConfig {
  const TabBarConfig({
    this.indicatorColor,
    this.dividerColor,
    this.labelColor,
    this.unselectedLabelColor,
    this.overlayColor,
    this.dividerHeight,
    this.labelPadding,
    this.labelStyle,
    this.unselectedLabelStyle,
    this.indicatorSize,
    this.tabAlignment,
    this.indicatorAnimation,
    this.splashFactory,
    this.indicatorBorder,
  });

  final String? indicatorColor;

  final String? dividerColor;

  final String? labelColor;

  final String? unselectedLabelColor;

  final String? overlayColor;

  final double? dividerHeight;

  final PaddingConfig? labelPadding;

  final TextStyleConfig? labelStyle;

  final TextStyleConfig? unselectedLabelStyle;

  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final TabBarIndicatorSizeConfig? indicatorSize;

  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final TabAlignmentConfig? tabAlignment;

  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final TabIndicatorAnimationConfig? indicatorAnimation;

  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final TabSplashFactoryConfig? splashFactory;

  final BorderConfig? indicatorBorder;

  factory TabBarConfig.fromJson(Map<String, Object?> json) => _$TabBarConfigFromJson(json);

  Map<String, Object?> toJson() => _$TabBarConfigToJson(this);
}

/// Defines default property values for descendant [AppBar] widgets.
///
/// This configuration maps to [AppBarThemeData] and is typically used to
/// describe the overall [ThemeData.appBarTheme]. Properties are null by default,
/// allowing the [AppBar] constructor to provide its own defaults.
@freezed
@JsonSerializable(explicitToJson: true)
class AppBarConfig with _$AppBarConfig {
  const AppBarConfig({
    this.primary = true,
    this.showBackButton = true,
    this.backgroundColor,
    this.foregroundColor,
    this.shadowColor,
    this.surfaceTintColor,
    this.elevation,
    this.scrolledUnderElevation,
    this.titleSpacing,
    this.leadingWidth,
    this.toolbarHeight,
    this.centerTitle,
    this.iconTheme,
    this.actionsIconTheme,
    this.titleTextStyle,
    this.toolbarTextStyle,
    this.systemOverlayStyle,
  });

  final bool primary;
  final bool showBackButton;
  final String? backgroundColor;
  final String? foregroundColor;
  final String? shadowColor;
  final String? surfaceTintColor;
  final double? elevation;
  final double? scrolledUnderElevation;
  final double? titleSpacing;
  final double? leadingWidth;
  final double? toolbarHeight;
  final bool? centerTitle;
  final IconThemeDataConfig? iconTheme;
  final IconThemeDataConfig? actionsIconTheme;
  final TextStyleConfig? titleTextStyle;
  final TextStyleConfig? toolbarTextStyle;
  final OverlayStyleModel? systemOverlayStyle;

  factory AppBarConfig.fromJson(Map<String, Object?> json) => _$AppBarConfigFromJson(json);

  Map<String, Object?> toJson() => _$AppBarConfigToJson(this);
}
