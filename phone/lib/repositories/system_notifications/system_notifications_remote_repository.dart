import 'package:api/api.dart' show EndpointNotSupportedException, SystemNotificationGoneException, WebtritApiClient;

import 'package:webtrit_phone/mappers/api/system_notification_mapper.dart';
import 'package:webtrit_phone/models/system_notification.dart';

abstract class SystemNotificationsRemoteRepository {
  /// Fetches the history of system notifications.
  /// [since] - Optional parameter to filter notifications `before` this date.
  /// [limit] - Optional parameter to limit the number of notifications returned. Defaults to `20`.
  Future<List<SystemNotification>> getHistory({DateTime? since, int limit = 20});

  /// Fetches the updates of system notifications.
  /// [since] - Optional parameter to filter notifications created `after` this date.
  /// [limit] - Optional parameter to limit the number of notifications returned. Defaults to `20`.
  Future<List<SystemNotification>> getUpdates({required DateTime since, int limit = 20});

  /// Marks a system notification as seen.
  ///
  /// One the backend no longer has has nothing left to mark, so that counts
  /// as done rather than as a failure the outbox would retry forever.
  Future<void> markSystemNotificationAsSeen(int notificationId);

  /// Deletes a system notification.
  ///
  /// One the backend no longer has - deleted from another device or by the
  /// retention cleaner - counts as deleted rather than as a failure.
  Future<void> deleteNotification(int notificationId);

  /// Deletes several system notifications and returns the ids the backend
  /// actually deleted. Ids it does not have are skipped, not refused.
  ///
  /// A backend without the bulk route gets one request per id instead.
  Future<List<int>> deleteNotifications(List<int> notificationIds);
}

class SystemNotificationsRemoteRepositoryApiImpl
    with SystemNotificationApiMapper
    implements SystemNotificationsRemoteRepository {
  SystemNotificationsRemoteRepositoryApiImpl(this._webtritApiClient, this._token);

  final WebtritApiClient _webtritApiClient;
  final String _token;

  @override
  Future<List<SystemNotification>> getHistory({DateTime? since, int limit = 20}) async {
    final response = await _webtritApiClient.getSystemNotificationsHistory(_token, since: since, limit: limit);
    return response.items.map(systemNotificationFromApi).toList();
  }

  @override
  Future<List<SystemNotification>> getUpdates({required DateTime since, int limit = 20}) async {
    final response = await _webtritApiClient.getSystemNotificationsUpdates(_token, since: since, limit: limit);
    return response.items.map(systemNotificationFromApi).toList();
  }

  @override
  Future<void> markSystemNotificationAsSeen(int notificationId) async {
    try {
      await _webtritApiClient.markSystemNotificationAsSeen(_token, notificationId);
    } on SystemNotificationGoneException {
      // Deleted elsewhere: nothing left to mark.
    }
  }

  @override
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _webtritApiClient.deleteSystemNotification(_token, notificationId);
    } on SystemNotificationGoneException {
      // Already gone is what was asked for.
    }
  }

  @override
  Future<List<int>> deleteNotifications(List<int> notificationIds) async {
    if (notificationIds.isEmpty) return const [];

    try {
      final response = await _webtritApiClient.deleteSystemNotifications(_token, notificationIds);
      return response.deletedIds;
    } on EndpointNotSupportedException {
      // A Core from before the bulk route (WT-1872) still deletes one at a time.
      // Each id is gone from the backend afterwards, deleted now or before.
      for (final id in notificationIds) {
        await deleteNotification(id);
      }
      return notificationIds;
    }
  }
}
