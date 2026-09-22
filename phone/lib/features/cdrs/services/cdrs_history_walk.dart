import 'dart:async';

import 'package:clock/clock.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

import 'cdrs_history_windows.dart';

final _logger = Logger('CdrsHistoryWalk');

/// What a walk left behind: what the asking list gained, and whether the
/// archive itself ended.
class CdrsHistoryWalkResult {
  const CdrsHistoryWalkResult({required this.gained, required this.reachedHorizon});

  const CdrsHistoryWalkResult.none() : gained = 0, reachedHorizon = false;

  final int gained;

  /// True only when the walk reached the slice that starts at the horizon. A
  /// walk that ran out of slices any other way - the sanity bound on widths
  /// that defeat the widening - leaves this false and its watermark where it
  /// stands, so the next gesture carries on instead of declaring the archive
  /// over.
  final bool reachedHorizon;
}

/// Owns the walk back through the call archive: the slices to ask for, the
/// pages inside them, the watermark that says how far back the store has been
/// asked, and the rule that only one walk runs at a time.
///
/// It is one object for one store, and that is the point. Three lists read the
/// same archive; when each of them walked on its own they covered the same
/// slices side by side, and a screen opened again re-walked days it had already
/// walked. What belongs to a list is only what the list is FOR - which records
/// it wants and how it shows them - and those arrive as callbacks.
class CdrsHistoryWalk {
  CdrsHistoryWalk(this._localRepository, this._remoteRepository, {HistoryWindows? windows, this.pageSize = 50})
    : windows = windows ?? configuredCdrsHistoryWindows();

  final CdrsLocalRepository _localRepository;
  final CdrsRemoteRepository _remoteRepository;

  /// The slices the remote history is asked for, oldest bound first.
  final HistoryWindows windows;

  /// Records asked for per request, and the size of a page a list wants.
  final int pageSize;

  /// Pages ONE WALK may ask for, across all of its slices. Bounds a backend
  /// that ignores `page` and hands the same full page back forever: per slice
  /// the same budget would let it burn this many requests once for every slice
  /// the horizon allows.
  static const _pagesPerWalkLimit = 40;

  /// How coarsely the backend stamps a record. A resumed slice overlaps the
  /// previous one by this much, so a record sharing its second with the oldest
  /// one taken is asked for again rather than lost; the caller's merge drops
  /// the repeat.
  static const _backendResolution = Duration(seconds: 1);

  Future<void> _tail = Future<void>.value();

  /// Walks until [wanted] records the caller recognises have been added, or the
  /// archive ends.
  ///
  /// Walks queue: the watermark says where a PREVIOUS walk stopped and cannot
  /// say that one is in flight, so two lists mounting in the same frame would
  /// otherwise read it before either moved it and ask for every slice twice.
  ///
  /// [takeWhatIsStored] runs at the front of the queue, after the wait: another
  /// list may have filled the store meanwhile, and what is already there costs
  /// nothing to read. It answers with how many rows the caller gained, and a
  /// walk that is no longer needed never reaches the network.
  ///
  /// [show] is handed each batch the caller recognises and answers with how
  /// many rows it actually gained - a record already listed adds nothing, so it
  /// must not count towards [wanted].
  ///
  /// [cancelled] is consulted after every await; a caller that closed, or whose
  /// store was wiped under it, stops the walk where it stands.
  Future<CdrsHistoryWalkResult> forList({
    required int wanted,
    required bool Function(CdrRecord cdr) matches,
    required FutureOr<int> Function() takeWhatIsStored,
    required int Function(List<CdrRecord> matched) show,
    required bool Function() cancelled,
  }) {
    final run = _tail.then((_) async {
      if (cancelled()) return const CdrsHistoryWalkResult.none();

      var gained = await takeWhatIsStored();
      if (cancelled() || gained >= wanted) return CdrsHistoryWalkResult(gained: gained, reachedHorizon: false);

      final result = windows.horizon == Duration.zero
          ? await _unboundedPage(matches: matches, show: show, cancelled: cancelled)
          : await _walk(wanted: wanted - gained, matches: matches, show: show, cancelled: cancelled);
      return CdrsHistoryWalkResult(gained: gained + result.gained, reachedHorizon: result.reachedHorizon);
    });
    // A walk that throws is the caller's to report, not a reason for the next
    // list to wait forever.
    _tail = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<CdrsHistoryWalkResult> _walk({
    required int wanted,
    required bool Function(CdrRecord cdr) matches,
    required int Function(List<CdrRecord> matched) show,
    required bool Function() cancelled,
  }) async {
    // Whatever walked before - the other tab, this screen last time, the cycle
    // that filled an empty store - covered those days for everyone.
    final resumeAt =
        await _localRepository.getHistoryWalkedTo() ?? await _localRepository.getFirstRecordTime() ?? clock.now();
    if (cancelled()) return const CdrsHistoryWalkResult.none();

    var gained = 0;
    var pagesAsked = 0;
    var reachedHorizon = false;

    for (final window in windows.backFrom(resumeAt)) {
      var page = 1;
      var takenFromWindow = 0;
      DateTime? oldestTaken;

      while (true) {
        final result = await _remoteRepository.getHistory(
          timeFrom: window.timeFrom,
          timeTo: window.timeTo,
          page: page,
          limit: pageSize,
        );
        if (cancelled()) return CdrsHistoryWalkResult(gained: gained, reachedHorizon: false);
        pagesAsked++;
        await _localRepository.upsertCdrs(result.records, silent: true);
        if (cancelled()) return CdrsHistoryWalkResult(gained: gained, reachedHorizon: false);

        takenFromWindow += result.records.length;
        for (final cdr in result.records) {
          if (oldestTaken == null || cdr.connectTime.isBefore(oldestTaken)) oldestTaken = cdr.connectTime;
        }

        final matched = result.records.where(matches).toList();
        if (matched.isNotEmpty) gained += show(matched);
        _logger.fine('Walked $window page $page: ${result.records.length} records, ${matched.length} wanted');

        if (gained >= wanted) {
          // Enough for the user to go on with. Resume from the oldest record
          // taken rather than from the slice's far edge, so whatever is left of
          // this slice is still walked next time - overlapping by one backend
          // tick so a record stamped with the same second is not left behind.
          final resume = oldestTaken?.add(_backendResolution) ?? window.timeFrom;
          await _localRepository.markHistoryWalkedTo(resume.isBefore(window.timeTo) ? resume : window.timeTo);
          return CdrsHistoryWalkResult(gained: gained, reachedHorizon: false);
        }

        // An empty page ends a slice whatever a total said: a count can include
        // rows the endpoint never serializes, and asking for page after page of
        // nothing is the one way this loop could fail to end.
        if (result.records.isEmpty || !result.hasMoreAfter(takenFromWindow)) break;
        if (pagesAsked >= _pagesPerWalkLimit) {
          _logger.warning('Gave up after $pagesAsked pages; the backend may be ignoring the page number');
          return CdrsHistoryWalkResult(gained: gained, reachedHorizon: false);
        }
        page++;
      }

      // The slice moves the watermark whatever it held. A walk that advanced by
      // the records instead would stand still on an empty answer, which is the
      // whole reason older history was unreachable.
      await _localRepository.markHistoryWalkedTo(window.timeFrom);
      if (cancelled()) return CdrsHistoryWalkResult(gained: gained, reachedHorizon: false);
      reachedHorizon = window.endsAtHorizon;
    }

    return CdrsHistoryWalkResult(
      gained: gained,
      reachedHorizon: reachedHorizon || !resumeAt.isAfter(clock.now().subtract(windows.horizon)),
    );
  }

  /// One page of history with no lower bound, for a deployment that switched
  /// the walk off. The backend decides how far back it looks; what this side
  /// owns is where the next page starts, and that is the oldest record the LAST
  /// PAGE returned - not the oldest record a list shows, which a filtered list
  /// would never move past a page of records it does not match.
  Future<CdrsHistoryWalkResult> _unboundedPage({
    required bool Function(CdrRecord cdr) matches,
    required int Function(List<CdrRecord> matched) show,
    required bool Function() cancelled,
  }) async {
    final timeTo = await _localRepository.getHistoryWalkedTo();
    if (cancelled()) return const CdrsHistoryWalkResult.none();

    final result = await _remoteRepository.getHistory(timeTo: timeTo, limit: pageSize);
    if (cancelled()) return const CdrsHistoryWalkResult.none();
    await _localRepository.upsertCdrs(result.records, silent: true);
    if (cancelled()) return const CdrsHistoryWalkResult.none();

    if (result.records.isEmpty) return const CdrsHistoryWalkResult(gained: 0, reachedHorizon: true);

    final matched = result.records.where(matches).toList();
    final gained = matched.isEmpty ? 0 : show(matched);
    final oldest = result.records.map((cdr) => cdr.connectTime).reduce((a, b) => a.isBefore(b) ? a : b);
    await _localRepository.markHistoryWalkedTo(oldest);
    return CdrsHistoryWalkResult(gained: gained, reachedHorizon: false);
  }
}
