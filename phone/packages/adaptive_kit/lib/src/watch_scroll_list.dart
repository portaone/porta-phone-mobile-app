import 'package:material_ui/material_ui.dart';

import 'adaptive_metrics.dart';
import 'screen_shape.dart';
import 'watch_edge_button.dart';
import 'watch_fade_mask.dart';
import 'watch_title.dart';

/// A watch screen that is a list - no main action at the bottom unless a
/// [WatchScrollList.builder] is given an [edge]: the [children] scroll with
/// the padding a face needs and fade into its bottom edge, the last of them
/// able to scroll clear of the fade.
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
///
/// [WatchScrollList.builder] is the same list for rows there can be many of -
/// a call history, contacts: the rows are built as they scroll into view,
/// after the title and an optional [header] (a filter), and a [controller]
/// lets the screen load more as the end comes near. With an [edge], the
/// list is a page of one thing with its one action - the calls with a
/// number and the call - and fades out above the edge button instead of
/// into the bottom of the face.
class WatchScrollList extends StatelessWidget {
  const WatchScrollList({
    super.key,
    required this.children,
    this.bottom,
    this.title,
    this.spacing = 0,
    this.opaque = false,
  }) : header = const [],
       itemCount = 0,
       itemBuilder = null,
       controller = null,
       edge = null;

  const WatchScrollList.builder({
    super.key,
    required this.itemCount,
    required IndexedWidgetBuilder this.itemBuilder,
    this.title,
    this.header = const [],
    this.spacing = 0,
    this.controller,
    this.edge,
  }) : children = const [],
       bottom = null,
       opaque = false;

  /// The rows, all built at once.
  final List<Widget> children;

  /// The choices pinned to the bottom of the face.
  final List<Widget>? bottom;

  /// The list's title, on top of it, scrolling away with it.
  final String? title;

  /// The room between two rows.
  final double spacing;

  /// Whether the list paints the page's background.
  final bool opaque;

  /// What sits between the title and the rows of a [WatchScrollList.builder].
  final List<Widget> header;

  /// How many rows [itemBuilder] builds.
  final int itemCount;

  /// Builds the row at an index when it scrolls into view.
  final IndexedWidgetBuilder? itemBuilder;

  /// The list's scroll controller, to follow how far it is scrolled.
  final ScrollController? controller;

  /// Builds the edge button of a [WatchScrollList.builder] over [overlay], the
  /// edge button's size and shape, to merge over the screen's own style.
  final Widget Function(BuildContext context, ButtonStyle overlay)? edge;

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
    final itemBuilder = this.itemBuilder;
    if (itemBuilder != null) return _lazy(context, itemBuilder);
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

  Widget _lazy(BuildContext context, IndexedWidgetBuilder itemBuilder) {
    final title = this.title;
    final gap = context.adaptiveMetrics.gap;
    final lead = [
      if (title != null) ...[WatchTitle(title), SizedBox(height: gap)],
      for (final widget in header) ...[widget, SizedBox(height: gap)],
    ];
    final edge = this.edge;
    final reserved = edge == null ? 0.0 : WatchEdgeButton.reservedHeight(context);
    final list = WatchFadeMask(
      bottomInset: reserved,
      fadeHeight: _fadeHeight,
      child: ListView.builder(
        controller: controller,
        padding: context.watchListPadding(minBottom: reserved + _fadeHeight + gap),
        itemCount: lead.length + itemCount,
        itemBuilder: (context, index) {
          if (index < lead.length) return lead[index];
          final row = index - lead.length;
          final child = itemBuilder(context, row);
          if (row == 0 || spacing == 0) return child;
          return Padding(
            padding: EdgeInsets.only(top: spacing),
            child: child,
          );
        },
      ),
    );
    if (edge == null) return list;
    return Stack(
      children: [
        list,
        Align(
          alignment: Alignment.bottomCenter,
          child: WatchEdgeButton(builder: edge),
        ),
      ],
    );
  }
}
