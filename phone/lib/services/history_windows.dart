import 'package:clock/clock.dart';

/// One bounded slice of a history, named for the request it becomes.
class HistoryWindow {
  const HistoryWindow({required this.timeFrom, required this.timeTo, this.endsAtHorizon = false});

  final DateTime timeFrom;
  final DateTime timeTo;

  /// Whether this is the last slice there is: its start is the horizon.
  ///
  /// A walk that runs out of slices without seeing this one was cut short by
  /// the sanity bound, not by the archive, and must not tell anyone the history
  /// ended there.
  final bool endsAtHorizon;

  Duration get width => timeTo.difference(timeFrom);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryWindow &&
          other.timeFrom.isAtSameMomentAs(timeFrom) &&
          other.timeTo.isAtSameMomentAs(timeTo) &&
          other.endsAtHorizon == endsAtHorizon;

  @override
  int get hashCode => Object.hash(timeFrom.microsecondsSinceEpoch, timeTo.microsecondsSinceEpoch, endsAtHorizon);

  @override
  String toString() => 'HistoryWindow(${timeFrom.toIso8601String()} .. ${timeTo.toIso8601String()})';
}

/// The slices to ask a remote history for when walking back through it.
///
/// A history endpoint that answers a request without a range is free to answer
/// about a recent slice of it rather than about everything it holds, so reaching
/// older records means naming the range. Asking for one unbounded range instead
/// is not an option: the archive behind such an endpoint can be enormous, and
/// that is exactly why the default exists.
///
/// The slices widen as they go: the recent past is usually where the records
/// are, while a long-silent stretch is cheapest to cross in few, wide steps.
/// Doubling from [firstWidth] up to [maxWidth] crosses a year in a handful of
/// requests where a fixed week would need dozens.
///
/// The sequence is lazy and ends at the horizon, and it deliberately has no cap
/// of its own beyond that: at the shipped widths a whole year is seven slices,
/// so crossing the entire horizon costs seven requests. Stopping a walk earlier
/// would buy nothing and leave the caller holding a list it cannot grow. The
/// one bound is [_sanityLimit], which exists for widths that would defeat the
/// widening - an hour at a time against a horizon of a year - and is out of
/// reach of the shipped ones.
class HistoryWindows {
  const HistoryWindows({
    required this.firstWidth,
    required this.maxWidth,
    required this.horizon,
    this.overlap = const Duration(seconds: 1),
  });

  /// Slices one walk may produce, whatever it was configured with. Ten times
  /// what the shipped widths need for a year, so reaching it means the widths
  /// and the horizon disagree rather than that the history is long.
  static const _sanityLimit = 64;

  /// Width of the slice next to the cursor.
  final Duration firstWidth;

  /// Ceiling the width doubles up to.
  final Duration maxWidth;

  /// How far each slice reaches back past where the previous one began. The
  /// backend behind this app stamps a record to the second, so one second is
  /// the smallest overlap that can cover a boundary.
  final Duration overlap;

  /// How far back the walk may reach, measured from now. [Duration.zero] means
  /// "do not walk at all" and yields nothing - the caller then asks the single
  /// question it asked before there was a walk.
  final Duration horizon;

  /// Slices going back from [cursor], newest first, overlapping by [overlap],
  /// ending at the horizon.
  ///
  /// Each slice ends a tick AFTER the previous one began. A backend is free to
  /// read both bounds as exclusive, and then a record stamped exactly on a
  /// boundary would belong to neither slice and be lost without a trace, while
  /// the walk moved past it; a record returned twice only has to be recognised,
  /// which the caller does by its id.
  ///
  /// The walk still advances by the SLICE and never by what the server
  /// returned - a range that comes back empty, or that returns the same
  /// boundary record again, moves the cursor just as far as a full one.
  Iterable<HistoryWindow> backFrom(DateTime cursor) sync* {
    final floor = clock.now().subtract(horizon);

    var width = firstWidth < maxWidth ? firstWidth : maxWidth;
    if (width <= Duration.zero) return;

    var timeTo = cursor;
    var produced = 0;
    while (timeTo.isAfter(floor) && produced < _sanityLimit) {
      var timeFrom = timeTo.subtract(width);
      if (!timeFrom.isAfter(floor)) timeFrom = floor;

      yield HistoryWindow(
        timeFrom: timeFrom,
        timeTo: produced == 0 ? timeTo : timeTo.add(overlap),
        endsAtHorizon: timeFrom.isAtSameMomentAs(floor),
      );

      timeTo = timeFrom;
      produced++;
      final doubled = width * 2;
      width = doubled < maxWidth ? doubled : maxWidth;
    }
  }
}
