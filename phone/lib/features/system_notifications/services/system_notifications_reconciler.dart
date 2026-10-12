import 'package:logging/logging.dart';

import 'package:webtrit_phone/repositories/system_notifications/system_notifications_local_repository.dart';
import 'package:webtrit_phone/repositories/system_notifications/system_notifications_remote_repository.dart';

final _logger = Logger('SystemNotificationsReconciler');

/// Drops from the store what the backend no longer has.
///
/// The backend deletes a notification outright - from another device, or by
/// its retention cleaner - and reports it nowhere: the updates endpoint lists
/// only rows that exist. The one way to learn of it is to read the history
/// again and compare. Whatever the store holds inside the window of a page,
/// and the page does not list, is gone.
///
/// It only deletes; it does not store what the pages carry, which is the
/// business of the sync and of the screen.
class SystemNotificationsReconciler {
  SystemNotificationsReconciler(this.localRepo, this.remoteRepo, {this.maxPages = 5})
    : assert(maxPages > 0, 'maxPages must be greater than zero');

  final SystemNotificationsLocalRepository localRepo;
  final SystemNotificationsRemoteRepository remoteRepo;

  /// How many pages one reconciliation may read to reach the depth it was
  /// asked for. One is the ordinary case; the cap keeps a store that holds
  /// something far down the history from turning one pass into a crawl.
  final int maxPages;

  /// Reconciles the top of the history, as far down as the unseen count
  /// reaches.
  ///
  /// The newest page is what the list opens on. The unseen badge, though, is
  /// counted from the whole store, so the pass goes on below that page while
  /// an unseen notification is still stored further down - or the badge would
  /// keep counting one that was deleted elsewhere. Unseen notifications are
  /// nearly always the newest, so this is nearly always one page.
  Future<void> reconcileNewest({required int limit, void Function()? stillWanted}) async {
    final known = await _snapshot(stillWanted);
    if (known.isEmpty) return;

    final oldestUnseen = await localRepo.getOldestUnseenCreatedAt();
    stillWanted?.call();
    await _reconcile(known, limit: limit, downTo: oldestUnseen, stillWanted: stillWanted);
  }

  /// Reconciles what the store holds below [before], down to and including
  /// what was created at [downTo]: the stretch a screen has just shown from
  /// the store.
  ///
  /// The stretch may be wider than one backend page. The store is not always
  /// contiguous - an old notification can arrive alone, through an update - so
  /// the rows shown may reach further back than the page read below [before].
  Future<void> reconcileBelow({
    required DateTime before,
    required DateTime downTo,
    required int limit,
    void Function()? stillWanted,
  }) async {
    final known = await _snapshot(stillWanted);
    if (known.isEmpty) return;

    await _reconcile(known, limit: limit, before: before, downTo: downTo, stillWanted: stillWanted);
  }

  // Taken before any page is asked for: a notification that arrives while a
  // request is out is not in the page, and must not be judged by it. One whose
  // delete is queued is not among them - the outbox settles it.
  Future<Set<int>> _snapshot(void Function()? stillWanted) async {
    final known = (await localRepo.getNotificationIds()).toSet();
    stillWanted?.call();
    return known;
  }

  Future<void> _reconcile(
    Set<int> known, {
    required int limit,
    DateTime? before,
    DateTime? downTo,
    void Function()? stillWanted,
  }) async {
    var upper = before;

    for (var read = 0; read < maxPages; read++) {
      final page = await remoteRepo.getHistory(since: upper, limit: limit);
      stillWanted?.call();

      // A full page vouches only for what is newer than its oldest
      // notification. A short one is taken to have reached the end of the
      // history, and so to speak for everything older as well.
      //
      // That rests on the backend returning as many as were asked for whenever
      // it has them, which Core does: it applies the limit it is given and has
      // no ceiling of its own. A backend that capped the page would make every
      // page look like the last one, and everything below it would be dropped.
      final reachedTheEnd = page.length < limit;
      final oldest = reachedTheEnd
          ? null
          : page.map((notification) => notification.createdAt).reduce((a, b) => a.isBefore(b) ? a : b);

      _logger.fine('Reconciling ${page.length} notifications before $upper, down to $oldest');
      await localRepo.deleteMissingFromPage(
        known: known,
        present: page.map((notification) => notification.id).toSet(),
        createdAfter: oldest,
        createdBefore: upper,
      );
      stillWanted?.call();

      // Deep enough once the window has passed below what was asked for: it
      // is open at its lower end, so that end has to be strictly older.
      if (oldest == null || downTo == null || oldest.isBefore(downTo)) return;
      upper = oldest;
    }
    _logger.fine('Stopped after $maxPages pages, before reaching $downTo');
  }
}
