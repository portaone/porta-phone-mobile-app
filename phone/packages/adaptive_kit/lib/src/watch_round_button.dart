import 'package:material_ui/material_ui.dart';

import 'semantic_action.dart';

import 'screen_shape.dart';

/// How a [WatchRoundButton] stands out from the ones beside it.
enum WatchRoundEmphasis {
  /// The usual choice, or a switch that is on: a filled button.
  filled,

  /// Any choice: a tonal button.
  tonal,

  /// A choice of another kind, such as settings: an outlined button.
  outlined,
}

/// What a [WatchRoundButton] is drawn over.
enum WatchRoundTone {
  /// A light page: the theme's own button colours.
  onLight,

  /// The call's background or picture: light, translucent buttons, the
  /// switched-on one solid.
  onDark,
}

/// A watch control: a round button and a short caption under it - the hub's
/// sections, the ways in, a call's controls.
///
/// The button is one node for assistive technology, named by [label] (the
/// caption when absent); the caption is for the eye and is cut to [width]
/// rather than pushing a row past the face.
class WatchRoundButton extends StatelessWidget {
  const WatchRoundButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.caption,
    this.label,
    this.identifier,
    this.buttonKey,
    this.emphasis = WatchRoundEmphasis.tonal,
    this.tone = WatchRoundTone.onLight,
    this.size,
    this.width,
    this.style,
  });

  final Widget icon;

  /// Null shows the button disabled.
  final VoidCallback? onPressed;

  /// The word under the button; none for a choice the screen already names.
  final String? caption;

  /// The name assistive technology reads; the caption when absent.
  final String? label;
  final String? identifier;
  final Key? buttonKey;
  final WatchRoundEmphasis emphasis;
  final WatchRoundTone tone;

  /// The button's side; by default the face's.
  final double? size;

  /// The column the button and its caption keep to; by default a little
  /// wider than the button.
  final double? width;

  /// A style of the screen's own, such as a hangup's colours. It wins where
  /// it says something.
  final ButtonStyle? style;

  /// The button's side on this face when nothing else decides it.
  static double defaultSize(BuildContext context) => context.isSmallWatch ? 40.0 : 46.0;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final side = size ?? defaultSize(context);
    final onDark = tone == WatchRoundTone.onDark;
    final light = themeData.colorScheme.surface;

    return SizedBox(
      width: width ?? side + 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          SemanticAction(
            label: label ?? caption,
            identifier: identifier,
            child: onDark ? _onDark(context, side, light) : _onLight(side),
          ),
          if (caption case final caption?)
            // The button carries the name; the caption is for the eye only.
            ExcludeSemantics(
              child: Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: themeData.textTheme.labelSmall?.copyWith(
                  color: onDark ? light : null,
                  fontSize: context.isSmallWatch ? 8 : 9,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _onLight(double side) {
    final constraints = BoxConstraints.tightFor(width: side, height: side);
    return switch (emphasis) {
      WatchRoundEmphasis.filled => IconButton.filled(
        key: buttonKey,
        constraints: constraints,
        style: style,
        onPressed: onPressed,
        icon: icon,
      ),
      WatchRoundEmphasis.tonal => IconButton.filledTonal(
        key: buttonKey,
        constraints: constraints,
        style: style,
        onPressed: onPressed,
        icon: icon,
      ),
      WatchRoundEmphasis.outlined => IconButton.outlined(
        key: buttonKey,
        constraints: constraints,
        style: style,
        onPressed: onPressed,
        icon: icon,
      ),
    };
  }

  Widget _onDark(BuildContext context, double side, Color light) {
    final on = emphasis == WatchRoundEmphasis.filled;
    final base = IconButton.styleFrom(
      backgroundColor: on ? light : light.withValues(alpha: 0.28),
      foregroundColor: on ? Theme.of(context).colorScheme.primary : light,
      disabledBackgroundColor: light.withValues(alpha: 0.12),
      disabledForegroundColor: light.withValues(alpha: 0.4),
      fixedSize: Size.square(side),
      minimumSize: Size.square(side),
      iconSize: side * 0.46,
    );
    return IconButton(
      key: buttonKey,
      // merge keeps the receiver's values, so the screen's style goes first.
      style: style?.merge(base) ?? base,
      onPressed: onPressed,
      icon: icon,
    );
  }
}
