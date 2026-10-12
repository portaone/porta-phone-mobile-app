// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'dart:async';

import 'package:app_database/app_database.dart';

import 'package:webtrit_phone/mappers/drift/system_notification_drift_mapper.dart';
import 'package:webtrit_phone/mappers/drift/system_notification_outbox_drift_mapper.dart';
import 'package:webtrit_phone/models/system_notification.dart';
import 'package:webtrit_phone/models/system_notification_event.dart';
import 'package:webtrit_phone/models/system_notification_outbox_entry.dart';

abstract class SystemNotificationsLocalRepository {
  Stream<SystemNotificationEvent> get eventBus;

  Future<List<SystemNotification>> getNotifications({DateTime? from, DateTime? to, int limit = 50});

  /// The ids of every stored notification, not only of those on screen.
  Future<List<int>> getNotificationIds();

  Future<SystemNotification?> getNotificationById(int id);

  Future<DateTime?> getLastUpdate();

  Stream<int> unseenCount();

  /// When the oldest notification the unseen count counts was created, or null
  /// when it counts none.
  Future<DateTime?> getOldestUnseenCreatedAt();

  Future<void> upsertNotifications(
    List<SystemNotification> notifications, {
    bool silent = false,
    bool initialData = false,
  });

  /// Queues the delete of the stored notifications among [ids] in the outbox.
  ///
  /// They leave the list and the unseen count at once, but stay stored until
  /// the backend confirms: the outbox row references its notification. A sync
  /// that brings one of them back meanwhile is stored silently.
  Future<void> queueDeletes(List<int> ids);

  Future<void> deleteNotification(int id);

  /// Deletes the notifications with [ids] and whatever is queued for them in
  /// the outbox: what follows a confirmed delete.
  Future<void> deleteNotifications(List<int> ids);

  /// Deletes the stored notifications a history page of the backend shows to
  /// be gone: those among [known] - what was stored before the page was asked
  /// for - created strictly after [createdAfter] and strictly before
  /// [createdBefore] that the page does not list ([present]). Announced the
  /// way [deleteNotifications] announces.
  Future<void> deleteMissingFromPage({
    required Set<int> known,
    required Set<int> present,
    DateTime? createdAfter,
    DateTime? createdBefore,
  });

  Future<List<SystemNotificationOutboxEntry>> getOutboxNotifications({
    SnOutboxActionType? actionType,
    List<SnOutboxState> states = SnOutboxState.values,
  });

  Future<void> upsertOutboxNotification(SystemNotificationOutboxEntry entry);

  Future<void> deleteOutboxNotification(int notificationId, SnOutboxActionType actionType);

  Future<void> wipeData();
}

class SystemNotificationsLocalRepositoryDriftImpl
    with SystemNotificationOutboxDriftMapper, SystemNotificationDriftMapper
    implements SystemNotificationsLocalRepository {
  SystemNotificationsLocalRepositoryDriftImpl(this._appDatabase);

  final AppDatabase _appDatabase;
  late final _dao = _appDatabase.systemNotificationsDao;

  final StreamController<SystemNotificationEvent> _eventBus = StreamController.broadcast();

  void _addEvent(SystemNotificationEvent event) => _eventBus.add(event);

  @override
  Stream<SystemNotificationEvent> get eventBus => _eventBus.stream;

  @override
  Future<List<SystemNotification>> getNotifications({DateTime? from, DateTime? to, int limit = 50}) async {
    final data = await _dao.getNotifications(from: from, to: to, limit: limit);
    return data.map(systemNotificationFromDrift).toList();
  }

  @override
  Future<List<int>> getNotificationIds() => _dao.getNotificationIds();

  @override
  Future<SystemNotification?> getNotificationById(int id) async {
    final data = await _dao.getNotificationById(id);
    return data != null ? systemNotificationFromDrift(data) : null;
  }

  @override
  Future<DateTime?> getLastUpdate() async {
    return await _dao.getLastUpdate();
  }

  @override
  Stream<int> unseenCount() {
    return _dao.unseenCount();
  }

  @override
  Future<DateTime?> getOldestUnseenCreatedAt() => _dao.getOldestUnseenCreatedAt();

  @override
  Future<void> upsertNotifications(
    List<SystemNotification> notifications, {
    bool silent = false,
    bool initialData = false,
  }) async {
    final data = notifications.map(systemNotificationToDrift).toList();
    await _dao.upsertNotifications(data);
    if (silent == false) {
      // One the user has deleted is not news, even when a sync brings it back
      // before the backend has confirmed the delete.
      final deleting = await _dao.getPendingDeleteIds(notifications.map((n) => n.id));
      notifications
          .where((n) => !deleting.contains(n.id))
          .forEach((n) => _addEvent(SystemNotificationUpdate(n, initialData: initialData)));
    }
  }

  @override
  Future<void> queueDeletes(List<int> ids) async {
    if (ids.isEmpty) return;

    final queued = await _dao.queueDeletes(ids);
    for (final data in queued) {
      final entry = SystemNotificationOutboxEntry(notificationId: data.id, actionType: SnOutboxActionType.delete);
      _addEvent(SystemNotificationOutboxUpdate(entry));
      _addEvent(SystemNotificationRemove(systemNotificationFromDrift(data)));
    }
  }

  @override
  Future<void> deleteNotification(int id) => deleteNotifications([id]);

  @override
  Future<void> deleteNotifications(List<int> ids) async {
    if (ids.isEmpty) return;

    _announceDeleted(await _dao.deleteNotifications(ids));
  }

  @override
  Future<void> deleteMissingFromPage({
    required Set<int> known,
    required Set<int> present,
    DateTime? createdAfter,
    DateTime? createdBefore,
  }) async {
    if (known.isEmpty) return;

    _announceDeleted(
      await _dao.deleteMissingFromPage(
        known: known,
        present: present,
        createdAfter: createdAfter,
        createdBefore: createdBefore,
      ),
    );
  }

  void _announceDeleted(
    ({List<SystemNotificationData> notifications, List<SystemNotificationOutboxEntryData> outbox}) deleted,
  ) {
    for (final entry in deleted.outbox) {
      _addEvent(SystemNotificationOutboxRemove(entry.notificationId, actionTypefromDrift(entry.actionType)));
    }
    // Only what the store held: an id it did not hold was on no screen and in
    // no shade, so there is nothing to tell.
    for (final data in deleted.notifications) {
      _addEvent(SystemNotificationRemove(systemNotificationFromDrift(data)));
    }
  }

  @override
  Future<List<SystemNotificationOutboxEntry>> getOutboxNotifications({
    SnOutboxActionType? actionType,
    List<SnOutboxState> states = SnOutboxState.values,
  }) async {
    final actionTypeData = actionType != null ? actionTypeToDrift(actionType) : null;
    final statesData = states.map(stateToDrift).toSet().toList();
    final data = await _dao.getOutboxNotifications(actionTypeData, states: statesData);
    return data.map(notificationOutboxEntryFromDrift).toList();
  }

  @override
  Future<void> upsertOutboxNotification(SystemNotificationOutboxEntry entry) async {
    final data = notificationOutboxEntryToDrift(entry);
    await _dao.upsertOutboxNotification(data);
    _addEvent(SystemNotificationOutboxUpdate(entry));
  }

  @override
  Future<void> deleteOutboxNotification(int notificationId, SnOutboxActionType actionType) async {
    final actionTypeData = actionTypeToDrift(actionType);
    final count = await _dao.deleteOutboxNotification(notificationId, actionTypeData);
    if (count > 0) _addEvent(SystemNotificationOutboxRemove(notificationId, actionType));
  }

  @override
  Future<void> wipeData() async {
    await _dao.wipeData();
  }
}
