import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'semantic_action.dart';

import 'adaptive_metrics.dart';
import 'screen_shape.dart';
import 'watch_edge_button.dart';
import 'watch_fade_mask.dart';
import 'watch_stadium_fields.dart';
import 'watch_title.dart';

/// The main action of a [WatchActionLayout], when it is a plain button: a
/// label and what it does. A button that shows more than a label - a
/// spinner while a form is sent - is built with
/// [WatchActionLayout.primary] instead.
@immutable
class WatchAction {
  const WatchAction({required this.label, required this.onPressed, this.style, this.identifier, this.buttonKey});

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// The screen's own button style; the edge button's size and shape go
  /// over it.
  final ButtonStyle? style;

  /// The automation id of the button.
  final String? identifier;

  final Key? buttonKey;

  /// The edge button of this action: its button over [overlay], the edge
  /// button's size and shape, merged over [style].
  Widget buildButton(ButtonStyle overlay) {
    final button = OutlinedButton(
      key: buttonKey,
      onPressed: onPressed,
      style: overlay.merge(style),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    return identifier == null ? button : SemanticAction(identifier: identifier, child: button);
  }
}

/// A watch screen with one main action: its [content] scrolls in a short
/// column, an optional [secondary] action at the column's end, and the main
/// action is the edge button along the bottom of the face, the column fading
/// out above it.
///
/// An optional [title] opens the column, in place of the icon or the app bar
/// a phone screen has. The main action is an [action], or a button [primary]
/// builds.
///
/// Text written for a phone - descriptions, explanations - takes the small
/// body size here, so a field or a toggle stays in view; outlined text fields
/// take the pill shape.
class WatchActionLayout extends StatelessWidget {
  const WatchActionLayout({super.key, this.title, required this.content, this.action, this.primary, this.secondary})
    : assert((action == null) != (primary == null), 'one main action: an action or a primary builder');

  final String? title;
  final List<Widget> content;
  final Widget? secondary;

  final WatchAction? action;

  /// Builds the main button over [overlay], the edge button's size and
  /// shape, to merge over the screen's own style.
  final Widget Function(ButtonStyle overlay)? primary;

  static const _fadeHeight = 22.0;

  /// A form's first line is often a field whose label floats above its
  /// border. Started where a list starts, that label meets the bezel of a
  /// round face, narrower than the field up there, or the rounded corners of
  /// a rectangular one; the column starts lower, where the face is as wide
  /// as the field.
  static const _roundTop = 0.19;
  static const _rectTop = 20.0;

  EdgeInsets _padding(BuildContext context, double reserved) {
    final padding = context.watchListPadding(minBottom: reserved + _fadeHeight);
    final top = context.isRoundScreen ? MediaQuery.sizeOf(context).height * _roundTop : _rectTop;
    return padding.copyWith(top: math.max(padding.top, top));
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final metrics = context.adaptiveMetrics;
    final reserved = WatchEdgeButton.reservedHeight(context);
    final secondary = this.secondary;
    final title = this.title;
    final action = this.action;
    final primary = this.primary;

    // A Material, not a coloured box: list tiles and ink below paint on the
    // nearest Material, and a plain colour would hide them.
    return Material(
      color: themeData.scaffoldBackgroundColor,
      child: Stack(
        children: [
          WatchFadeMask(
            bottomInset: reserved,
            fadeHeight: _fadeHeight,
            child: WatchStadiumFields(
              child: Theme(
                data: themeData.copyWith(
                  textTheme: themeData.textTheme.copyWith(
                    bodyLarge: themeData.textTheme.bodySmall,
                    bodyMedium: themeData.textTheme.bodySmall,
                  ),
                ),
                // The theme's body styles reach widgets that read them (a
                // field, a description); a plain Text reads the default
                // text style, set once here.
                child: DefaultTextStyle.merge(
                  style: themeData.textTheme.bodySmall,
                  child: ListView(
                    padding: _padding(context, reserved),
                    children: [
                      if (title != null) ...[WatchTitle(title), SizedBox(height: metrics.gap)],
                      ...content,
                      if (secondary != null) ...[SizedBox(height: metrics.gap), secondary],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: WatchEdgeButton(builder: (context, overlay) => action?.buildButton(overlay) ?? primary!(overlay)),
          ),
        ],
      ),
    );
  }
}
