import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/services/services.dart';

const _day = Duration(days: 1);
final _now = DateTime.utc(2026, 9, 21, 12);

HistoryWindows _windows({
  Duration firstWidth = const Duration(days: 7),
  Duration maxWidth = const Duration(days: 90),
  Duration horizon = const Duration(days: 365),
}) => HistoryWindows(firstWidth: firstWidth, maxWidth: maxWidth, horizon: horizon);

List<HistoryWindow> _walk(HistoryWindows windows, DateTime cursor, {int take = 1000}) =>
    withClock(Clock.fixed(_now), () => windows.backFrom(cursor).take(take).toList());

void main() {
  group('HistoryWindows.backFrom', () {
    test('widens each slice up to the ceiling', () {
      final walk = _walk(_windows(), _now, take: 6);

      expect(walk.map((window) => window.width), [
        const Duration(days: 7),
        const Duration(days: 14),
        const Duration(days: 28),
        const Duration(days: 56),
        const Duration(days: 90),
        const Duration(days: 90),
      ]);
    });

    test('slices are contiguous and walk backwards from the cursor', () {
      final walk = _walk(_windows(), _now, take: 4);

      expect(walk.first.timeTo, _now);
      for (var i = 1; i < walk.length; i++) {
        expect(walk[i].timeTo, walk[i - 1].timeFrom, reason: 'slice $i must start where slice ${i - 1} ended');
        expect(walk[i].timeFrom.isBefore(walk[i].timeTo), isTrue);
      }
    });

    test('the walk advances even when a slice covers a silent stretch', () {
      // Nothing here consults records: the sequence is the same whatever the
      // server answers, which is what makes an empty range advance the cursor.
      final walk = _walk(_windows(), _now, take: 3);

      expect(walk.last.timeFrom, _now.subtract(const Duration(days: 49)));
    });

    test('stops at the horizon, with the last slice clamped to it', () {
      final walk = _walk(_windows(horizon: const Duration(days: 30)), _now);

      expect(walk.last.timeFrom, _now.subtract(const Duration(days: 30)));
      expect(walk.fold(Duration.zero, (sum, window) => sum + window.width), const Duration(days: 30));
    });

    test('a cursor already past the horizon yields nothing', () {
      final walk = _walk(_windows(horizon: const Duration(days: 30)), _now.subtract(const Duration(days: 31)));

      expect(walk, isEmpty);
    });

    test('a zero horizon switches the walk off', () {
      // The way back to the behaviour that predates the walk, without a build.
      final walk = _walk(_windows(horizon: Duration.zero), _now);

      expect(walk, isEmpty);
    });

    test('a first slice wider than the ceiling is clamped from the start', () {
      final walk = _walk(_windows(firstWidth: const Duration(days: 120), maxWidth: const Duration(days: 30)), _now);

      expect(walk.first.width, const Duration(days: 30));
      // Only the last slice is narrower, and only because the horizon cut it.
      expect(walk.take(walk.length - 1).map((window) => window.width).toSet(), {const Duration(days: 30)});
      expect(walk.last.width, lessThanOrEqualTo(const Duration(days: 30)));
    });

    test('a non-positive width yields nothing instead of looping forever', () {
      expect(_walk(_windows(firstWidth: Duration.zero), _now), isEmpty);
      expect(_walk(_windows(firstWidth: -_day), _now), isEmpty);
    });

    test('the shipped widths cross a whole year in seven slices', () {
      // The reason the walk needs no cap of its own: crossing the horizon is
      // seven requests, so there is no "spent the budget, found nothing" state
      // to explain to anyone.
      final walk = _walk(_windows(), _now);

      expect(walk, hasLength(7));
      expect(walk.last.timeFrom, _now.subtract(const Duration(days: 365)));
    });

    test('widths that defeat the widening are stopped by the sanity bound', () {
      // An hour at a time against a year would be 8760 slices.
      final walk = _walk(_windows(firstWidth: const Duration(hours: 1), maxWidth: const Duration(hours: 1)), _now);

      expect(walk, hasLength(64));
      expect(walk.last.timeFrom.isAfter(_now.subtract(const Duration(days: 365))), isTrue);
    });

    test('only the slice that starts at the horizon says so', () {
      final walk = _walk(_windows(horizon: const Duration(days: 30)), _now);

      expect(walk.take(walk.length - 1).any((window) => window.endsAtHorizon), isFalse);
      expect(walk.last.endsAtHorizon, isTrue);
    });

    test('a walk cut short by the sanity bound never claims the horizon', () {
      // The caller has to be able to tell "the archive ends here" from "the
      // widths could not get there", or a misconfiguration would hide a year.
      final walk = _walk(_windows(firstWidth: const Duration(hours: 1), maxWidth: const Duration(hours: 1)), _now);

      expect(walk, hasLength(64));
      expect(walk.any((window) => window.endsAtHorizon), isFalse);
    });

    test('the sequence is lazy, so a caller pays only for what it takes', () {
      // A horizon of a century would be tens of thousands of slices if the
      // sequence were built eagerly.
      final walk = _walk(_windows(horizon: const Duration(days: 365 * 100)), _now, take: 2);

      expect(walk, hasLength(2));
    });

    test('the horizon is measured from now, not from the cursor', () {
      final walk = _walk(_windows(horizon: const Duration(days: 10)), _now.subtract(const Duration(days: 5)));

      expect(walk.single.timeTo, _now.subtract(const Duration(days: 5)));
      expect(walk.single.timeFrom, _now.subtract(const Duration(days: 10)));
    });
  });
}
