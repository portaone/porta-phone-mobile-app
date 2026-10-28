import 'package:clock/clock.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

import 'cdrs_history_windows.dart';

final _logger = Logger('CdrsSyncWorker');

const _postCallRefreshDelay = Duration(seconds: 1);

/// Owns the CDR worker and its polling registration.
///
/// Scheduled refreshes and call-ended invalidations use the same polling task,
/// so they share one lifecycle, single-flight boundary, and backoff policy.
final class CdrsSync extends PollingWorkerOwner<CdrsSyncWorker> {
  CdrsSync({
    required super.worker,
    required super.pollingService,
    required super.interval,
    this.postCallRefreshDelay = _postCallRefreshDelay,
  });

  /// How long after a call ends the refresh is requested; the shell supplies
  /// the configured value, tests and direct construction keep the default.
  final Duration postCallRefreshDelay;

  /// Requests one refresh after the backend has had time to publish the CDR.
  ///
  /// Repeated call-ended events use the task's trailing-edge debounce instead
  /// of cancelling and recreating the polling schedule.
  void requestPostCallRefresh() {
    invalidatePollingTask(after: postCallRefreshDelay);
  }
}

/// Synchronizes remote call history with the local CDR store.
///
/// One [refresh] is a finite domain sync cycle. [PollingService] owns
/// scheduling, connectivity, lifecycle, single-flight, and backoff. Feature
/// consumers request additional work through [CdrsSync].
class CdrsSyncWorker implements PollingWorker {
  CdrsSyncWorker(this.localRepo, this.remoteRepo, {this.pageSize = 50, HistoryWindows? historyWindows})
    : historyWindows = historyWindows ?? configuredCdrsHistoryWindows(),
      assert(pageSize > 0, 'pageSize must be greater than zero');

  /// How far either side of the newest stored record the clear check asks.
  ///
  /// A backend whose history was cleared since - from this device or from any
  /// other of the account - no longer returns that record, and its absence is
  /// the only way this client learns of a clear made elsewhere. The record is
  /// usually on the incremental pages already; when it is not, a range around
  /// it is asked for rather than taking the absence as a clear: the pages can
  /// stop early, as a backend may serve fewer records per page than asked, and
  /// a record missing for that reason must not cost the whole history. The
  /// range runs from the call's connect time to its disconnect time, since a
  /// backend may filter on either - PortaSwitch filters on the time the call
  /// was billed, a field the record does not carry - and the margin covers a
  /// billing time a little off both and bounds rounded to the second.
  static const clearCheckMargin = Duration(minutes: 1);

  final CdrsLocalRepository localRepo;
  final CdrsRemoteRepository remoteRepo;

  final int pageSize;

  /// The slices an empty store is filled from, the same ones the lists walk.
  final HistoryWindows historyWindows;

  @override
  bool get isActive => !_disposed;

  /// Runs one complete CDR sync cycle and returns when local persistence has
  /// finished.
  ///
  /// With records already stored, the cycle is incremental: every page from the
  /// last locally known update, advancing the page number after each full page.
  /// With none, it has to find some - and asking without a range reaches only
  /// recent history, so a first launch on a quiet day would fill nothing at all.
  /// The first cycle therefore walks back until a slice holds something, and a
  /// store that stays empty afterwards is asked about the most recent slice
  /// alone: there is nothing to be incremental from, but neither is there a
  /// reason to re-walk the archive every five minutes. Failures are offered to the local repository, which notifies
  /// initial-sync observers only while its durable sync cursor is absent, and
  /// are rethrown so the caller can apply retry or backoff policy.
  @override
  Future<void> refresh() async {
    if (_disposed) {
      throw StateError('Cannot refresh a disposed CDR sync worker.');
    }

    try {
      final lastUpdate = await localRepo.getLastUpdate();

      if (lastUpdate != null) {
        await _refreshIncrementalHistory(lastUpdate);
      } else if (await localRepo.getLastSyncTime() == null) {
        await _refreshInitialHistory();
      } else {
        await _refreshRecentHistory();
      }

      // The persisted marker is the source of truth. A cache wipe clears it,
      // so the next successful cycle naturally marks initial sync again without
      // mirroring that state in the worker.
      if (await localRepo.getLastSyncTime() == null) {
        await localRepo.markSyncCompleted(clock.now());
      }
    } catch (_) {
      await _notifyInitialSyncFailed();
      rethrow;
    }
  }

  /// Fills an empty store: slices of history walked back until one holds
  /// records, or until the horizon says there are none.
  ///
  /// Each slice is recorded as walked, so the lists that open afterwards resume
  /// where this left off instead of asking for the same days again.
  Future<void> _refreshInitialHistory() async {
    for (final window in historyWindows.backFrom(clock.now())) {
      final initialCdrs = await _fetchWindow(window);
      _logger.fine('Initial CDRs fetched from $window: ${initialCdrs.length}');
      if (initialCdrs.isEmpty) {
        await localRepo.markHistoryWalkedTo(window.timeFrom);
        continue;
      }

      await localRepo.upsertCdrs(initialCdrs.reversed.toList());
      // Only the part of the slice this page covers: the rest of it is still
      // for a list to walk.
      final oldest = initialCdrs.map((cdr) => cdr.connectTime).reduce((a, b) => a.isBefore(b) ? a : b);
      await localRepo.markHistoryWalkedTo(oldest);
      return;
    }

    if (historyWindows.horizon == Duration.zero) await _refreshRecentHistory();
  }

  /// Asks about the most recent slice only. The store is empty and the archive
  /// has already been walked once, so this is a cheap "anything new yet".
  Future<void> _refreshRecentHistory() async {
    final window = historyWindows.backFrom(clock.now()).firstOrNull;
    final recentCdrs = window != null
        ? await _fetchWindow(window)
        : (await remoteRepo.getHistory(page: 1, limit: pageSize)).records;

    _logger.fine('Recent CDRs fetched: ${recentCdrs.length}');
    if (recentCdrs.isNotEmpty) await localRepo.upsertCdrs(recentCdrs.reversed.toList());
  }

  Future<List<CdrRecord>> _fetchWindow(HistoryWindow window) async {
    final page = await remoteRepo.getHistory(
      timeFrom: window.timeFrom,
      timeTo: window.timeTo,
      page: 1,
      limit: pageSize,
    );
    return page.records;
  }

  Future<void> _refreshIncrementalHistory(DateTime lastUpdate) async {
    final newest = (await localRepo.getHistory(limit: 1)).firstOrNull;
    var page = 1;
    final fetchedCdrs = <CdrRecord>[];

    while (true) {
      final newCdrs = (await remoteRepo.getHistory(timeFrom: lastUpdate, page: page, limit: pageSize)).records;
      _logger.fine('New CDRs fetched from page $page: ${newCdrs.length}');
      fetchedCdrs.addAll(newCdrs);

      if (newCdrs.length < pageSize) break;
      page++;
    }

    // A cleared history: everything stored here is from before the clear, and
    // what the pages held - the calls made since - is all there is to keep.
    // The clear is inferred, so the archive is left for the lists to walk.
    if (newest != null && await _clearedSince(newest, fetchedCdrs)) {
      _logger.info('The newest stored CDR is no longer on the backend, dropping the local history');
      await localRepo.replaceAfterClear(fetchedCdrs.reversed.toList(), syncedAt: clock.now(), archiveHidden: false);
      return;
    }

    // Persist only after every page has been fetched. If a later request fails,
    // the local last-update anchor must not advance past records that were not
    // fetched yet.
    // Repository events update in-memory lists one record at a time by
    // prepending new records, so emit oldest-to-newest to preserve descending
    // chronology in consumers (the API pages are newest-first).
    await localRepo.upsertCdrs(fetchedCdrs.reversed.toList());
  }

  /// Whether the backend stopped returning [newest]: the history was cleared.
  ///
  /// Found among [fetched], it is still there; otherwise the backend is asked
  /// for the range around it.
  Future<bool> _clearedSince(CdrRecord newest, List<CdrRecord> fetched) async {
    if (fetched.any((cdr) => cdr.callId == newest.callId)) return false;

    final page = await remoteRepo.getHistory(
      timeFrom: newest.connectTime.subtract(clearCheckMargin),
      timeTo: newest.disconnectTime.add(clearCheckMargin),
      page: 1,
      limit: pageSize,
    );
    return !page.records.any((cdr) => cdr.callId == newest.callId);
  }

  Future<void> _notifyInitialSyncFailed() async {
    try {
      await localRepo.notifyInitialSyncFailed();
    } catch (e, s) {
      // Preserve the original cycle failure when notifying observers also
      // fails, so PollingService applies backoff to the real sync error.
      _logger.warning('notifyInitialSyncFailed', e, s);
    }
  }

  bool _disposed = false;

  @override
  Future<void> dispose() async {
    if (_disposed) return;

    _logger.info('Disposing');
    _disposed = true;
  }
}
