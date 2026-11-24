// The grid of the conference full screen (conference_full_screen.dart): how many columns its tiles
// take and which tile goes where, chosen by the proportions of the pictures they show.
//
// chooseConferenceGridLayout is the rule, a pure function: every column count from one to the
// number of tiles, the leftover tiles sharing the last row across; for each, the part of every
// picture seen when it covers its tile, summed; the layout with the most wins, its widest tiles
// given to the most landscape pictures. ConferenceGridHold keeps a layout on screen for a while
// before the next, so tiles do not jump while pictures change their shape. ConferenceTileGrid
// lays the tiles out by both. The tiles themselves, their pictures and menus are the full
// screen's.
import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:clock/clock.dart';
import 'package:collection/collection.dart';

/// The proportions (width / height) taken for a picture whose size is not known yet - before its
/// first frame - and for a tile with no picture at all: a phone camera held upright, 3:4.
const double conferenceDefaultAspect = 3 / 4;

/// Where the tiles of the full screen go: [columns] in each full row, the leftover tiles sharing
/// the last row across, and [order] - the tile (by its index in the list given) in each place,
/// row by row.
@immutable
class ConferenceGridLayout {
  const ConferenceGridLayout({required this.columns, required this.order});

  /// The identity layout of [count] tiles in [columns].
  factory ConferenceGridLayout.inOrder(int count, {required int columns}) =>
      ConferenceGridLayout(columns: columns, order: List.unmodifiable(List<int>.generate(count, (index) => index)));

  final int columns;
  final List<int> order;

  int get count => order.length;

  /// The sizes of the rows, top to bottom: full rows of [columns], the leftover last.
  List<int> get rows => [for (var start = 0; start < count; start += columns) math.min(columns, count - start)];

  @override
  bool operator ==(Object other) =>
      other is ConferenceGridLayout && other.columns == columns && const ListEquality<int>().equals(other.order, order);

  @override
  int get hashCode => Object.hash(columns, Object.hashAll(order));

  @override
  String toString() => 'ConferenceGridLayout(columns: $columns, order: $order)';
}

/// The height of a row of [rowCount] in [height], none lower than [minRowHeight] - past that the
/// grid scrolls.
double conferenceGridRowHeight({
  required double height,
  required int rowCount,
  required double gap,
  required double minRowHeight,
}) {
  final fitted = (height - gap * (rowCount - 1)) / rowCount;
  return fitted < minRowHeight ? minRowHeight : fitted;
}

/// The part of a picture of [picture] proportions seen when it covers a tile of [tile]
/// proportions, the rest cut at the edges: 1 for the same proportions.
double conferenceVisibleFraction(double tile, double picture) => math.min(tile, picture) / math.max(tile, picture);

/// The layout of tiles showing pictures of [aspects] (width / height; `null` for not known, taken
/// as [conferenceDefaultAspect]) in [area]: the column count, from one to the number of tiles,
/// under which the most of the pictures is seen, each covering its tile; the widest tiles to the
/// most landscape pictures, the narrowest to the most portrait. Rows share the height, none lower
/// than [minRowHeight]. Equal pictures keep their order; of equal sums, the fewer columns.
ConferenceGridLayout chooseConferenceGridLayout({
  required Size area,
  required List<double?> aspects,
  required double gap,
  required double minRowHeight,
}) {
  final count = aspects.length;
  if (count == 0) return ConferenceGridLayout.inOrder(0, columns: 1);
  if (area.width <= 0 || area.height <= 0) return ConferenceGridLayout.inOrder(count, columns: math.min(2, count));
  final pictures = [for (final aspect in aspects) aspect ?? conferenceDefaultAspect];
  // Narrowest first, stable: equal pictures keep their order, so equal tiles fill row by row.
  final byPicture = List<int>.generate(count, (index) => index)
    ..sort((a, b) => _stable(pictures[a].compareTo(pictures[b]), a, b));

  ConferenceGridLayout? best;
  var bestSeen = -1.0;
  for (var columns = 1; columns <= count; columns++) {
    final probe = ConferenceGridLayout.inOrder(count, columns: columns);
    final rows = probe.rows;
    final rowHeight = conferenceGridRowHeight(
      height: area.height,
      rowCount: rows.length,
      gap: gap,
      minRowHeight: minRowHeight,
    );
    final slots = [
      for (final across in rows)
        for (var i = 0; i < across; i++) (area.width - gap * (across - 1)) / across / rowHeight,
    ];
    final bySlot = List<int>.generate(count, (index) => index)
      ..sort((a, b) => _stable(slots[a].compareTo(slots[b]), a, b));
    final order = List<int>.filled(count, 0);
    var seen = 0.0;
    for (var i = 0; i < count; i++) {
      order[bySlot[i]] = byPicture[i];
      seen += conferenceVisibleFraction(slots[bySlot[i]], pictures[byPicture[i]]);
    }
    // A hair over: a tie by rounding keeps the fewer columns.
    if (seen > bestSeen + 1e-9) {
      bestSeen = seen;
      best = ConferenceGridLayout(columns: columns, order: List.unmodifiable(order));
    }
  }
  return best!;
}

int _stable(int byValue, int a, int b) => byValue != 0 ? byValue : a.compareTo(b);

/// Keeps a layout on screen for at least [hold] before the next one, so tiles do not jump while
/// pictures change their proportions one after another. A change of what is laid out - the
/// number of tiles, the size of the place - takes effect at once: the layout held would not fit.
class ConferenceGridHold {
  ConferenceGridHold({this.hold = const Duration(seconds: 3)});

  final Duration hold;

  ConferenceGridLayout? _shown;
  Object? _frame;
  DateTime? _since;

  /// The layout to show at [now] when [wanted] is the best one for [frame] (what is laid out:
  /// the tile count and the place), and how long until [wanted] may be shown when it is held back.
  ({ConferenceGridLayout layout, Duration? retryIn}) next(ConferenceGridLayout wanted, Object frame, DateTime now) {
    final shown = _shown;
    final since = _since;
    if (shown == wanted && frame == _frame) return (layout: wanted, retryIn: null);
    if (shown == null || since == null || frame != _frame || !now.isBefore(since.add(hold))) {
      _shown = wanted;
      _frame = frame;
      _since = now;
      return (layout: wanted, retryIn: null);
    }
    return (layout: shown, retryIn: since.add(hold).difference(now));
  }
}

/// [tiles] in the layout their pictures' proportions ([aspects], one per tile; `null` for not
/// known) are seen best in, held a while between layouts (ConferenceGridHold). The rows share all
/// the height there is; past what fits they keep [minRowHeight] and scroll.
class ConferenceTileGrid extends StatefulWidget {
  const ConferenceTileGrid({
    super.key,
    required this.tiles,
    required this.aspects,
    required this.gap,
    required this.minRowHeight,
    this.hold = const Duration(seconds: 3),
  }) : assert(tiles.length == aspects.length, 'one aspect per tile');

  final List<Widget> tiles;
  final List<double?> aspects;
  final double gap;
  final double minRowHeight;
  final Duration hold;

  @override
  State<ConferenceTileGrid> createState() => _ConferenceTileGridState();
}

class _ConferenceTileGridState extends State<ConferenceTileGrid> {
  late final _hold = ConferenceGridHold(hold: widget.hold);
  Timer? _retry;

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  /// Asks again once a held layout may be shown.
  void _retryIn(Duration? wait) {
    _retry?.cancel();
    _retry = wait == null ? null : Timer(wait, () => mounted ? setState(() {}) : null);
  }

  @override
  Widget build(BuildContext context) {
    final gap = widget.gap;
    final tiles = widget.tiles;
    if (tiles.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final area = Size(constraints.maxWidth - gap * 2, constraints.maxHeight);
        final wanted = chooseConferenceGridLayout(
          area: area,
          aspects: widget.aspects,
          gap: gap,
          minRowHeight: widget.minRowHeight,
        );
        final next = _hold.next(wanted, (tiles.length, area), clock.now());
        _retryIn(next.retryIn);
        final layout = next.layout;
        final rows = <Widget>[];
        var start = 0;
        for (final across in layout.rows) {
          rows.add(
            Row(
              spacing: gap,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (var i = start; i < start + across; i++) Expanded(child: tiles[layout.order[i]])],
            ),
          );
          start += across;
        }
        final fitted = (constraints.maxHeight - gap * (rows.length - 1)) / rows.length;
        final rowHeight = conferenceGridRowHeight(
          height: constraints.maxHeight,
          rowCount: rows.length,
          gap: gap,
          minRowHeight: widget.minRowHeight,
        );
        return ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: gap),
          physics: fitted < widget.minRowHeight ? null : const NeverScrollableScrollPhysics(),
          itemCount: rows.length,
          separatorBuilder: (_, _) => SizedBox(height: gap),
          itemBuilder: (context, index) => SizedBox(height: rowHeight, child: rows[index]),
        );
      },
    );
  }
}
