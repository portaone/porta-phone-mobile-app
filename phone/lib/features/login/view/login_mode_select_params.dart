import 'package:material_ui/material_ui.dart';

import 'login_mode_select_screen_style.dart';

/// One way into the app the landing offers: a configured launch button, or
/// the demo build's sign-in to a custom instance.
@immutable
class LoginModeSelectEntry {
  const LoginModeSelectEntry({
    required this.title,
    required this.processing,
    required this.onPressed,
    required this.buttonKey,
    this.semanticsId,
  });

  final String title;

  /// Shows progress in place of the title.
  final bool processing;

  /// Null while any sign-in is in progress.
  final VoidCallback? onPressed;

  final Key buttonKey;

  /// The automation id, for the entries that have a stable one.
  final String? semanticsId;
}

/// Everything the landing shows, built once by the screen.
@immutable
class LoginModeSelectParams {
  const LoginModeSelectParams({
    required this.style,
    required this.buttonStyle,
    required this.greeting,
    required this.entries,
    required this.customCoreEntry,
  });

  final LoginModeSelectScreenStyle? style;

  /// The theme's style for the launch buttons.
  final ButtonStyle? buttonStyle;

  /// The greeting under the logo; null when the config has none.
  final String? greeting;

  /// The configured launch buttons, in order.
  final List<LoginModeSelectEntry> entries;

  /// The sign-in to a custom instance, offered only by a demo build.
  final LoginModeSelectEntry? customCoreEntry;
}
