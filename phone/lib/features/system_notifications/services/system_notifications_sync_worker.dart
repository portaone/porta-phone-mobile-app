import 'package:logging/logging.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/system_notifications/system_notifications_local_repository.dart';
import 'package:webtrit_phone/repositories/system_notifications/system_notifications_remote_repository.dart';
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
/// bounded request.
class SystemNotificationsSyncWorker implements PollingWorker {
  SystemNotificationsSyncWorker(this.localRepo, this.remoteRepo, {this.pageSize = 50})
    : assert(pageSize > 0, 'pageSize must be greater than zero');

  final SystemNotificationsLocalRepository localRepo;
  final SystemNotificationsRemoteRepository remoteRepo;

  final int pageSize;

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

    // The store is the anchor, except when it has been emptied by deleting
    // everything in it: that is not a first load, and treating it as one would
    // read the older history back and push every unseen notification in it as
    // news. The newest update this worker has stored stands in for it then.
    final lastUpdate = await localRepo.getLastUpdate() ?? _lastStoredUpdate;
    _ensureActive();

    if (lastUpdate == null) {
      await _refreshInitialHistory();
    } else {
      await _refreshUpdatesSince(lastUpdate);
    }
    _hasCompletedSync = true;
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

  void _remember(List<SystemNotification> stored) {
    if (stored.isEmpty) return;
    final newest = _newestUpdate(stored);
    final last = _lastStoredUpdate;
    if (last == null || newest.isAfter(last)) _lastStoredUpdate = newest;
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
  DateTime? _lastStoredUpdate;
  bool _disposed = false;

  @override
  Future<void> dispose() async {
    if (_disposed) return;

    _logger.info('Disposing');
    _disposed = true;
  }
}
