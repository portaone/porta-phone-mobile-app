import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

import '../view/keypad_screen_styles.dart';
import 'actionpad_style.dart';
import 'actionpad_styles.dart';

/// The call along the bottom of a watch face - the keypad's, a call page's, a
/// contact's: an icon button in the brand's call style, the one look for
/// starting a call. Built by a `WatchEdgeButton`'s builder over its
/// [overlay].
///
/// The style comes the way the keypad takes it: the keypad screen's actionpad,
/// else the theme's actionpad styles; [actionpadStyle] stands in for both
/// where a screen carries its own.
class WatchCallEdgeButton extends StatelessWidget {
  const WatchCallEdgeButton({
    super.key,
    required this.overlay,
    required this.label,
    required this.onPressed,
    this.icon = Icons.call,
    this.identifier,
    this.buttonKey,
    this.actionpadStyle,
  });

  final ButtonStyle overlay;

  /// What a screen reader says: what the tap does.
  final String? label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// The call's icon, or what stands for it - a transfer while one is chosen.
  final IconData icon;

  final String? identifier;
  final Key? buttonKey;
  final ActionpadStyle? actionpadStyle;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final actionpad =
        actionpadStyle ??
        themeData.extension<KeypadScreenStyles>()?.primary?.actionpadStyle ??
        themeData.extension<ActionpadStyles>()?.primary;
    return SemanticAction(
      label: label,
      identifier: identifier,
      child: TextButton(
        key: buttonKey,
        onPressed: onPressed,
        style: overlay.merge(actionpad?.primary?.style),
        child: Icon(icon),
      ),
    );
  }
}
