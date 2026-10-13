import 'package:logging/logging.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/system_notifications/system_notifications_local_repository.dart';
import 'package:webtrit_phone/repositories/system_notifications/system_notifications_remote_repository.dart';
import 'package:webtrit_phone/repositories/system_notifications/system_notifications_sync_journal.dart';
import 'package:webtrit_phone/services/services.dart';

final _logger = Logger('SystemNotificationsSyncWorker');

/// Owns the system notifications worker and its polling registration.
///
/// The feature has no pull-to-refresh and no domain trigger of its own, so the
/// standard owner is the whole of it: one lifecycle, one single-flight
/// boundary, one backoff policy.
final class SystemNotificationsSync extends PollingWorkerOwner<SystemNotificationsSyncWorker> {
  SystemNotificationsSync({required super.worker, required super.pollingService, required super.interval});
}

/// Synchronizes remote system notifications with the local store.
///
/// One [refresh] is a finite domain sync cycle. [PollingService] owns
/// scheduling, connectivity, lifecycle, single-flight, and backoff.
///
/// A cycle fetches either the initial history or every update since the last
/// locally known one - never both, so the first cycle after a wipe stays one
/// bounded request. The updates carry the notifications deleted since as well,
/// and the store drops those: that is how a delete made on another device
/// reaches this one. A store not brought up to date for longer than the
/// backend reports deletes is read afresh instead.
class SystemNotificationsSyncWorker implements PollingWorker {
  SystemNotificationsSyncWorker(
    this.localRepo,
    this.remoteRepo, {
    this.pageSize = 50,
    this.journal,
    this.deletedRetention,
    DateTime Function()? now,
  }) : assert(pageSize > 0, 'pageSize must be greater than zero'),
       _now = now ?? DateTime.now;

  final SystemNotificationsLocalRepository localRepo;
  final SystemNotificationsRemoteRepository remoteRepo;

  final int pageSize;

  /// When the store was last brought up to date; without one the store is
  /// never taken for stale.
  final SystemNotificationsSyncJournal? journal;

  /// For how long the backend reports a deleted notification: [Duration.zero]
  /// for without limit, null while it reports none at all. Asked every cycle,
  /// since the backend may be upgraded, or set up differently, under a running
  /// app.
  final Duration? Function()? deletedRetention;

  final DateTime Function() _now;

  @override
  bool get isActive => !_disposed;

  /// Runs one complete sync cycle and returns when local persistence has
  /// finished.
  ///
  /// Failures keep their original error and stack trace so the caller can
  /// apply retry or backoff policy.
  @override
  Future<void> refresh() async {
    _ensureActive();

    // The store is the anchor, with two exceptions the newest update this
    // worker has read stands in for.
    //
    // A store emptied by deleting everything in it - here or on another device
    // - is not a first load: treating it as one would read the older history
    // back and push every unseen notification in it as news.
    //
    // And a deleted notification moves the anchor without being stored. Read
    // from the store alone, the same deletes would be fetched again in every
    // cycle until something newer is stored.
    final lastUpdate = _newer(await localRepo.getLastUpdate(), _lastReadUpdate);
    _ensureActive();

    final retention = deletedRetention?.call();

    if (lastUpdate == null) {
      await _refreshInitialHistory();
    } else if (_storeMayBeStale(retention)) {
      await _reloadStore();
    } else {
      await _refreshUpdatesSince(lastUpdate);
    }
    _hasCompletedSync = true;

    // Only against a backend that reports deletes: the record says "every
    // delete up to here has been heard of", which one that reports none cannot
    // back. Left unset there, the first cycle after it is upgraded finds no
    // record and reads the store afresh - once.
    if (retention != null) await journal?.markSynced(_now());
  }

  // The backend reports a deleted notification for [retention] and then
  // forgets it - unless it keeps them without limit, as one set up to remove
  // nothing by age does. A store last brought up to date longer ago than that may hold
  // notifications deleted in between, with nothing left to read about them.
  //
  // No record at all is the same case: a store filled before this device kept
  // one, by a version of the app or against a backend that could not hear of
  // deletes - whatever was deleted elsewhere until now is still in it.
  //
  // Something is taken off for clocks that disagree: a day, but never more
  // than a tenth of the time itself. Taken whole from a backend that reports
  // deletes for a day or less, it would leave nothing, and every cycle would
  // find its own store stale.
  bool _storeMayBeStale(Duration? retention) {
    final journal = this.journal;
    if (journal == null || retention == null) return false;

    final lastSyncedAt = journal.lastSyncedAt;
    if (lastSyncedAt == null) return true;

    // Reported without limit: however long ago the last sync was, every
    // delete made since is still there to be read.
    if (retention == Duration.zero) return false;

    final tenth = retention ~/ 10;
    final margin = tenth < _clockMargin ? tenth : _clockMargin;
    final sinceSynced = _now().difference(lastSyncedAt);

    // A record from the future was written while the clock ran ahead and has
    // been put right since. It says nothing of how long ago that was, and left
    // alone it would keep the store from ever looking stale until the clock
    // caught up with it - so it counts as no record.
    if (sinceSynced < -margin) return true;

    return sinceSynced > retention - margin;
  }

  static const _clockMargin = Duration(days: 1);

  // Reads the first page of the history again and drops everything else: the
  // store as a first load would leave it. Quietly - none of it is news, and
  // what the page still lists is not taken off the screen and put back.
  //
  // The page is fetched before anything is dropped, so a failure leaves the
  // store as it was. A row the outbox has yet to send something for stays too:
  // dropping it would drop the seen receipt or the delete queued with it.
  Future<void> _reloadStore() async {
    _logger.info('The stored notifications may be stale; reading them afresh');

    final history = await remoteRepo.getHistory(limit: pageSize);
    _ensureActive();

    final pending = await localRepo.getOutboxNotifications(states: const [SnOutboxState.pending, SnOutboxState.failed]);
    final kept = {...history.map((n) => n.id), ...pending.map((entry) => entry.notificationId)};
    final stale = (await localRepo.getNotificationIds()).where((id) => !kept.contains(id)).toList();
    _ensureActive();
    await localRepo.deleteNotifications(stale);
    _ensureActive();

    await localRepo.upsertNotifications(history.reversed.toList(), initialData: true);
    _ensureActive();
    // The anchor starts over from what is stored now: an update read before
    // belongs to the copy that was just let go.
    _lastReadUpdate = null;
    _remember(history);
  }

  Future<void> _refreshInitialHistory() async {
    final notifications = await remoteRepo.getHistory(limit: pageSize);
    _ensureActive();
    _logger.fine('Initial notifications fetched: ${notifications.length}');

    // An empty successful load leaves no timestamp in the store. Remember it
    // for this worker's lifetime so notifications arriving later are news,
    // while the first history load (including retries) stays silent.
    await localRepo.upsertNotifications(notifications.reversed.toList(), initialData: !_hasCompletedSync);
    _ensureActive();
    _remember(notifications);
  }

  Future<void> _refreshUpdatesSince(DateTime lastUpdate) async {
    var since = lastUpdate;

    while (true) {
      final updates = await remoteRepo.getUpdates(since: since, limit: pageSize);
      _ensureActive();
      _logger.fine('Updates fetched since $since: ${updates.length}');
      await localRepo.upsertNotifications(updates);
      _ensureActive();
      _remember(updates);

      if (updates.length < pageSize) break;

      // The endpoint pages by timestamp, not by page number, so the anchor has
      // to move or the same full page is fetched forever. A full page whose
      // records do not move it ends the cycle instead: the store now holds
      // them, so the next cycle resumes from its own advanced anchor.
      final newest = _newestUpdate(updates);
      if (!newest.isAfter(since)) break;
      since = newest;
    }
  }

  void _remember(List<SystemNotification> read) {
    if (read.isEmpty) return;
    _lastReadUpdate = _newer(_lastReadUpdate, _newestUpdate(read));
  }

  DateTime? _newer(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  DateTime _newestUpdate(List<SystemNotification> notifications) =>
      notifications.map((notification) => notification.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b);

  // In-flight I/O cannot be cancelled, but a retired worker must not start
  // another request or write after an async boundary.
  void _ensureActive() {
    if (_disposed) {
      throw StateError('Cannot refresh a disposed system notifications sync worker.');
    }
  }

  bool _hasCompletedSync = false;
  DateTime? _lastReadUpdate;
  bool _disposed = false;

  @override
  Future<void> dispose() async {
    if (_disposed) return;

    _logger.info('Disposing');
    _disposed = true;
  }
}
