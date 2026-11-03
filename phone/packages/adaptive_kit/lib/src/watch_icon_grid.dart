import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'adaptive_metrics.dart';
import 'screen_shape.dart';
import 'watch_round_button.dart';

/// One cell of a [WatchIconGrid]: a round button and its caption.
class WatchIconGridItem {
  const WatchIconGridItem({
    required this.icon,
    required this.caption,
    required this.onPressed,
    this.semanticLabel,
    this.identifier,
    this.buttonKey,
    this.emphasis = WatchRoundEmphasis.tonal,
  });

  final Widget icon;

  /// The short word under the button, for the eye only.
  final String caption;

  /// Null shows the cell disabled: an action that exists but cannot be
  /// taken right now.
  final VoidCallback? onPressed;

  /// The name assistive technology reads; the caption when absent.
  final String? semanticLabel;

  /// The automation id of the button.
  final String? identifier;

  final Key? buttonKey;
  final WatchRoundEmphasis emphasis;
}

/// A watch screen of round buttons with captions under a short title - the
/// hub of sections, the choice of a way in.
///
/// Three to a row, or as many as there are when fewer. On a round face the
/// grid keeps to a box of two thirds of the face, so its corner cells stay
/// clear of the bezel; on a rectangular one it takes the content's width.
/// The grid is centred, and scrolls when the cells do not fit.
class WatchIconGrid extends StatelessWidget {
  const WatchIconGrid({super.key, this.title, this.header, required this.items})
    : assert(title == null || header == null, 'a title or a header, not both');

  final String? title;

  /// Something of the screen's own in the title's place, such as a call in
  /// progress to go back to.
  final Widget? header;
  final List<WatchIconGridItem> items;

  static const _maxColumns = 3;

  /// The share of a round face the grid's box takes: the corners of a box of
  /// 0.707 touch the bezel, a little less leaves the corner captions room.
  static const _roundBox = 0.66;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final small = context.isSmallWatch;
    final round = context.isRoundScreen;
    final gap = context.adaptiveMetrics.gap;
    final columns = math.max(1, math.min(_maxColumns, items.length));
    final title = this.title;
    final titleText =
        header ??
        (title == null
            ? null
            : Text(
                title,
                style: themeData.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ));

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final EdgeInsets padding;
        if (round) {
          // The box's width only: the grid is centred on the face, and the
          // title goes above it, into the top of the face, where a short
          // line still fits.
          final side = (size.width - size.shortestSide * _roundBox) / 2;
          padding = EdgeInsets.symmetric(horizontal: side);
        } else {
          final list = context.watchListPadding();
          final content = context.watchContentPadding();
          padding = EdgeInsets.fromLTRB(content.left, list.top, content.right, list.bottom);
        }

        // A cell is a share of the width there is, never wider than the
        // button wants; fewer columns get a larger button.
        final available = size.width - padding.horizontal;
        final preferred = (small ? 40.0 : (round ? 50.0 : 44.0)) + (columns < _maxColumns ? 8 : 0);
        final cellWidth = math.min(preferred + 12, (available / columns).floorToDouble());
        final button = math.min(preferred, cellWidth - 6);

        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: math.max(0, size.height - padding.vertical), minWidth: available),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (titleText != null) ...[titleText, SizedBox(height: gap)],
                Wrap(
                  alignment: WrapAlignment.center,
                  runSpacing: gap,
                  children: [for (final item in items) _Cell(width: cellWidth, button: button, item: item)],
                ),
                // On a round face the same room again below, so the grid
                // itself, not the grid and its title, sits in the middle.
                if (round && titleText != null) ...[
                  SizedBox(height: gap),
                  ExcludeSemantics(
                    child: IgnorePointer(child: Visibility.maintain(visible: false, child: titleText)),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.width, required this.button, required this.item});

  final double width;
  final double button;
  final WatchIconGridItem item;

  @override
  Widget build(BuildContext context) {
    return WatchRoundButton(
      icon: item.icon,
      caption: item.caption,
      label: item.semanticLabel,
      identifier: item.identifier,
      buttonKey: item.buttonKey,
      emphasis: item.emphasis,
      size: button,
      width: width,
      onPressed: item.onPressed,
    );
  }
}
