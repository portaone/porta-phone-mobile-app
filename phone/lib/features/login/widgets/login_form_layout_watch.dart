import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

/// A sign-in form on a watch face: the content scrolls in a short column,
/// the secondary action at its end, and the primary action is the edge button
/// along the bottom of the face, with the column fading out above it.
class LoginFormLayoutWatch extends StatelessWidget {
  const LoginFormLayoutWatch({
    super.key,
    required this.content,
    required this.primary,
    required this.buttonStyle,
    this.secondary,
  });

  /// The form's descriptions and fields, with the gaps between them.
  final List<Widget> content;

  /// A second action under the content, such as Resend.
  final Widget? secondary;

  /// Builds the main button with [style]: [buttonStyle] with the edge
  /// button's style laid over it.
  final Widget Function(ButtonStyle? style) primary;

  /// The theme's style of the main button.
  final ButtonStyle? buttonStyle;

  @override
  Widget build(BuildContext context) {
    return WatchActionLayout(
      content: content,
      secondary: secondary,
      primary: (overlay) => primary(overlay.merge(buttonStyle)),
    );
  }
}
