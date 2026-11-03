import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'login_core_url_assign_screen_style.dart';

/// Everything the custom-core screen shows, built once by the screen.
@immutable
class LoginCoreUrlAssignParams {
  const LoginCoreUrlAssignParams({
    required this.style,
    required this.logoStyle,
    required this.buttonStyle,
    required this.historyController,
    required this.initialValue,
    required this.errorText,
    required this.processing,
    required this.onChanged,
    required this.onSubmit,
  });

  /// The screen's own style: bar, status bar and theme override.
  final LoginCoreUrlAssignScreenStyle? style;

  /// The logo, still borrowed from the switch screen's style.
  final ThemeImageStyle? logoStyle;

  /// The theme's style of Proceed.
  final ButtonStyle? buttonStyle;

  /// Owned by the screen's state, so the typed URL and its history outlive
  /// a rebuild of the layout.
  final HistoryAutocompleteController historyController;

  /// The URL the field opens with: the one used last.
  final String initialValue;

  /// Why the URL cannot be used, under the field; none while it can.
  final String? errorText;

  /// A check of the URL is running: the field and Proceed wait.
  final bool processing;

  final ValueChanged<String> onChanged;

  /// Null while the URL is not valid or a check is running.
  final VoidCallback? onSubmit;
}

/// The status bar style of the screen: its own, or, for themes saved before
/// the screen had one, the historic dark icons over the light login page.
SystemUiOverlayStyle loginCoreUrlAssignOverlayStyle(LoginCoreUrlAssignScreenStyle? style) =>
    style?.systemUiOverlayStyle ?? SystemUiOverlayStyle.dark;
