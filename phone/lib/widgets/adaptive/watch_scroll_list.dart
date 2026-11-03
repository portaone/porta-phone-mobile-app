import 'package:material_ui/material_ui.dart';

import 'adaptive_metrics.dart';
import 'screen_shape.dart';
import 'watch_fade_mask.dart';
import 'watch_title.dart';

/// A watch screen that is only a list - no main action at the bottom: the
/// [children] scroll with the padding a face needs and fade into its bottom
/// edge, the last of them able to scroll clear of the fade.
///
/// The counterpart of `WatchActionLayout`, for a menu or a list of choices.
///
/// With [bottom], the list is split: [children] are centred in the room
/// left above, and [bottom] - the choices - sit on the bottom of the face,
/// where a thumb reaches and where the edge button sits on other screens.
/// When the two do not fit together, the whole scrolls as one column.
///
/// As a page of its own - a list opened over another screen - it takes an
/// optional [title], a [spacing] between the [children], and [opaque] paints
/// the page's background.
class WatchScrollList extends StatelessWidget {
  const WatchScrollList({
    super.key,
    required this.children,
    this.bottom,
    this.title,
    this.spacing = 0,
    this.opaque = false,
  });

  final List<Widget> children;
  final List<Widget>? bottom;
  final String? title;
  final double spacing;
  final bool opaque;

  static const _fadeHeight = 26.0;

  @override
  Widget build(BuildContext context) {
    final list = _list(context);
    if (!opaque) return list;
    return Material(color: Theme.of(context).scaffoldBackgroundColor, child: list);
  }

  List<Widget> _spaced(BuildContext context) {
    final title = this.title;
    return [
      if (title != null) ...[WatchTitle(title), SizedBox(height: context.adaptiveMetrics.gap)],
      for (final (index, child) in children.indexed) ...[
        if (index > 0 && spacing > 0) SizedBox(height: spacing),
        child,
      ],
    ];
  }

  Widget _list(BuildContext context) {
    final children = _spaced(context);
    final bottom = this.bottom;
    if (bottom != null) {
      // Pinned to the bottom there is nothing to fade into, and a fade
      // would dim the last choice at rest.
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: context.watchListPadding(),
            sliver: SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: children),
                    ),
                  ),
                  ...bottom,
                ],
              ),
            ),
          ),
        ],
      );
    }
    return WatchFadeMask(
      fadeHeight: _fadeHeight,
      child: ListView(
        padding: context.watchListPadding(minBottom: _fadeHeight + context.adaptiveMetrics.gap),
        children: children,
      ),
    );
  }
}
