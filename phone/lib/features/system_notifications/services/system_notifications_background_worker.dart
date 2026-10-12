import 'package:logging/logging.dart';
import 'package:workmanager/workmanager.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/models/system_notification.dart';
import 'package:webtrit_phone/push_notification/app_local_push.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

final _logger = Logger('SystemNotificationBackgroundWorker');

/// A worker responsible for handling system notifications in background.
///
/// This class fetches new system notifications from the remote repository,
/// updates the local repository, and displays useen's as local push notifications.
/// It uses the Workmanager package to schedule periodic tasks.
///
/// Main purpose is to support clients that can't rely on remote push services
/// by some reason like nation firewall or security policies.
class SystemNotificationBackgroundWorker {
  SystemNotificationBackgroundWorker(this._localRepo, this._remoteRepo, this._pushRepo) {
    _logger.info('SystemNotificationBackgroundWorker initialized');
  }

  final SystemNotificationsLocalRepository _localRepo;
  final SystemNotificationsRemoteRepository _remoteRepo;
  final LocalPushRepository _pushRepo;

  /// Executes the background worker task.
  ///
  /// Returns a [Future] that completes with `true` if the execution was successful,
  /// or `false` otherwise.
  Future<bool> execute() async {
    try {
      final lastUpdate = await _localRepo.getLastUpdate();
      _logger.info('Last update: $lastUpdate');

      List<SystemNotification> notifications = switch (lastUpdate) {
        null => await _remoteRepo.getHistory(),
        DateTime() => await _updatesSince(lastUpdate),
      };

      _logger.info('Fetched ${notifications.length} new notifications');
      await _dismissPushesOfDeleted(notifications);
      await _localRepo.upsertNotifications(notifications);

      // With no anchor the fetch was the history, not news: a store that was
      // never filled, or one emptied by deleting everything in it. Pushing its
      // unseen notifications would raise alerts for old ones, which the app in
      // the foreground does not do either.
      if (lastUpdate == null) return true;

      final unseenNotifications = notifications.where((n) => n.seen == false && !n.isDeleted).toList();
      await Future.forEach(unseenNotifications, (n) => _displayPush(n));

      return true;
    } catch (e, s) {
      _logger.severe('Unexpected error', e, s);
      return false;
    }
  }

  // Every update since the anchor, not one page of them.
  //
  // The updates carry the notifications deleted since as well, oldest change
  // first, and a deleted one is dropped rather than stored - so it does not
  // move the anchor the next run starts from. One page alone could then be the
  // same deletes run after run, never reaching the news behind them.
  Future<List<SystemNotification>> _updatesSince(DateTime lastUpdate) async {
    final updates = <SystemNotification>[];
    var since = lastUpdate;

    while (true) {
      final page = await _remoteRepo.getUpdates(since: since, limit: _pageSize);
      updates.addAll(page);
      if (page.length < _pageSize) break;

      final newest = page.map((n) => n.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b);
      if (!newest.isAfter(since)) break;
      since = newest;
    }
    return updates;
  }

  // In the app the push service takes a deleted notification's push out of the
  // shade when the store announces the removal. Nothing listens here, and by
  // the time the app starts the row is gone - so it is done by hand, from the
  // stored row: what arrives deleted no longer carries the text the push shows.
  Future<void> _dismissPushesOfDeleted(List<SystemNotification> notifications) async {
    for (final deleted in notifications.where((n) => n.isDeleted)) {
      final stored = await _localRepo.getNotificationById(deleted.id);
      if (stored != null) await _pushRepo.dismissByContent(stored.title, stored.content);
    }
  }

  static const _pageSize = 50;

  Future<void> _displayPush(SystemNotification notification) async {
    final push = AppLocalPush(
      notification.id,
      notification.title,
      notification.content,
      payload: {'source': kLocalPushSourceSystemNotification},
    );
    await _pushRepo.displayPush(push);
  }

  /// Dispatches a background task related to system notifications.
  ///
  /// This static method is responsible for initiating or scheduling
  /// a task to handle system notifications in the background.
  ///
  /// Typically used to ensure notifications are processed even when
  /// the app is not in the foreground.
  static void dispatchTask() {
    if (_taskRegistered) return;
    Workmanager().registerPeriodicTask(
      kSystemNotificationsTaskId,
      kSystemNotificationsTask,
      constraints: Constraints(networkType: NetworkType.connected),
      backoffPolicy: BackoffPolicy.linear,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      initialDelay: const Duration(minutes: 1),
    );
    _taskRegistered = true;
    _logger.info('System notifications background task registered');
  }

  /// Cancels the scheduled background task for system notifications.
  ///
  /// This method should be called to stop any ongoing or future background
  /// work related to system notifications.
  static void cancelTask() {
    if (!_taskRegistered) return;
    Workmanager().cancelByUniqueName(kSystemNotificationsTaskId);
    _taskRegistered = false;
    _logger.info('System notifications background task cancelled');
  }

  static bool _taskRegistered = false;
}
