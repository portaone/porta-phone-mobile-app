import 'package:drift/drift.dart';
import 'package:app_database/src/app_database.dart';

part 'system_notifications_dao.g.dart';

@DriftAccessor(tables: [SystemNotificationsTable, SystemNotificationsOutboxTable])
class SystemNotificationsDao extends DatabaseAccessor<AppDatabase> with _$SystemNotificationsDaoMixin {
  SystemNotificationsDao(super.db);

  //
  // Notifications section
  //
  // A notification whose delete is queued stays in the table until the backend
  // confirms it - its outbox row references it, and deleting it would take the
  // queued delete with it - but nothing shows it any more.
  Expression<bool> _notPendingDelete(SystemNotificationsTable notifications) => notExistsQuery(
    select(systemNotificationsOutboxTable)..where(
      (outbox) =>
          outbox.notificationId.equalsExp(notifications.id) &
          outbox.actionType.equals(SnOutboxDataActionType.delete.name),
    ),
  );

  Future<List<SystemNotificationData>> getNotifications({DateTime? from, DateTime? to, int? limit}) {
    final query = select(systemNotificationsTable);
    query.orderBy([(t) => OrderingTerm.desc(t.createdAtRemoteUsec)]);
    query.where(_notPendingDelete);

    if (from != null) query.where((tbl) => tbl.createdAtRemoteUsec.isSmallerThanValue(from.microsecondsSinceEpoch));
    if (to != null) query.where((tbl) => tbl.createdAtRemoteUsec.isBiggerThanValue(to.microsecondsSinceEpoch));
    if (limit != null) query.limit(limit);

    return query.get();
  }

  Future<List<int>> getNotificationIds() {
    final query = selectOnly(systemNotificationsTable)
      ..addColumns([systemNotificationsTable.id])
      ..where(_notPendingDelete(systemNotificationsTable));
    return query.map((row) => row.read(systemNotificationsTable.id)!).get();
  }

  /// The ids among [ids] whose delete is queued.
  Future<Set<int>> getPendingDeleteIds(Iterable<int> ids) async {
    final query = selectOnly(systemNotificationsOutboxTable)
      ..addColumns([systemNotificationsOutboxTable.notificationId])
      ..where(
        systemNotificationsOutboxTable.actionType.equals(SnOutboxDataActionType.delete.name) &
            systemNotificationsOutboxTable.notificationId.isIn(ids),
      );
    final rows = await query.map((row) => row.read(systemNotificationsOutboxTable.notificationId)!).get();
    return rows.toSet();
  }

  /// Queues the delete of the stored notifications among [ids] and returns
  /// them, read in the same transaction.
  ///
  /// Only stored ones: the outbox row references its notification, and an id
  /// the device does not hold has nothing to hide and nothing to reference.
  Future<List<SystemNotificationData>> queueDeletes(List<int> ids) {
    return transaction(() async {
      final stored = await (select(systemNotificationsTable)..where((tbl) => tbl.id.isIn(ids))).get();
      await batch(
        (batch) => batch.insertAllOnConflictUpdate(systemNotificationsOutboxTable, [
          for (final notification in stored)
            SystemNotificationOutboxEntryData(
              notificationId: notification.id,
              actionType: SnOutboxDataActionType.delete,
              state: SnOutboxDataState.pending,
              sendAttempts: 0,
            ),
        ]),
      );
      return stored;
    });
  }

  Future<SystemNotificationData?> getNotificationById(int id) {
    return (select(systemNotificationsTable)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<DateTime?> getLastUpdate() async {
    final query = select(systemNotificationsTable)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAtRemoteUsec)])
      ..limit(1);
    final result = await query.getSingleOrNull();
    return result?.updatedAtRemoteUsec != null
        ? DateTime.fromMicrosecondsSinceEpoch(result!.updatedAtRemoteUsec)
        : null;
  }

  /// When the oldest notification that [unseenCount] counts was created, or
  /// null when it counts none.
  Future<DateTime?> getOldestUnseenCreatedAt() async {
    final pendingDelete = alias(systemNotificationsOutboxTable, 'pending_delete');
    final oldest = systemNotificationsTable.createdAtRemoteUsec.min();
    final query =
        selectOnly(systemNotificationsTable).join([
            leftOuterJoin(
              systemNotificationsOutboxTable,
              systemNotificationsOutboxTable.notificationId.equalsExp(systemNotificationsTable.id) &
                  systemNotificationsOutboxTable.actionType.equals(SnOutboxDataActionType.seen.name),
            ),
            leftOuterJoin(
              pendingDelete,
              pendingDelete.notificationId.equalsExp(systemNotificationsTable.id) &
                  pendingDelete.actionType.equals(SnOutboxDataActionType.delete.name),
            ),
          ])
          ..addColumns([oldest])
          ..where(
            systemNotificationsTable.seen.equals(false) &
                systemNotificationsOutboxTable.notificationId.isNull() &
                pendingDelete.notificationId.isNull(),
          );
    final usec = await query.map((row) => row.read(oldest)).getSingle();
    return usec == null ? null : DateTime.fromMicrosecondsSinceEpoch(usec);
  }

  Stream<int> unseenCount() {
    // Joined rather than a subquery so the watch follows the outbox table too.
    final pendingDelete = alias(systemNotificationsOutboxTable, 'pending_delete');
    final query =
        selectOnly(systemNotificationsTable).join([
            leftOuterJoin(
              systemNotificationsOutboxTable,
              systemNotificationsOutboxTable.notificationId.equalsExp(systemNotificationsTable.id) &
                  systemNotificationsOutboxTable.actionType.equals(SnOutboxDataActionType.seen.name),
            ),
            leftOuterJoin(
              pendingDelete,
              pendingDelete.notificationId.equalsExp(systemNotificationsTable.id) &
                  pendingDelete.actionType.equals(SnOutboxDataActionType.delete.name),
            ),
          ])
          ..addColumns([countAll()])
          ..where(
            systemNotificationsTable.seen.equals(false) &
                systemNotificationsOutboxTable.notificationId.isNull() &
                pendingDelete.notificationId.isNull(),
          );

    return query.map((row) => row.read(countAll()) ?? 0).watchSingle();
  }

  Future<void> upsertNotifications(List<SystemNotificationData> notifications) {
    return batch((batch) => batch.insertAllOnConflictUpdate(systemNotificationsTable, notifications));
  }

  Future<int> deleteNotification(int id) {
    return (delete(systemNotificationsTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Deletes the notifications with [ids] together with everything queued for
  /// them in the outbox: an action on a notification that no longer exists can
  /// never be confirmed, so it would stay queued forever.
  ///
  /// Returns what was deleted, read in the same transaction, so a caller can
  /// announce exactly that - including an outbox row queued a moment before.
  Future<({List<SystemNotificationData> notifications, List<SystemNotificationOutboxEntryData> outbox})>
  deleteNotifications(List<int> ids) {
    return transaction(() async {
      final notifications = await (select(systemNotificationsTable)..where((tbl) => tbl.id.isIn(ids))).get();
      final outbox = await (select(systemNotificationsOutboxTable)..where((tbl) => tbl.notificationId.isIn(ids))).get();
      await (delete(systemNotificationsOutboxTable)..where((tbl) => tbl.notificationId.isIn(ids))).go();
      await (delete(systemNotificationsTable)..where((tbl) => tbl.id.isIn(ids))).go();
      return (notifications: notifications, outbox: outbox);
    });
  }

  /// Deletes the stored notifications a history page of the backend shows to
  /// be gone: those among [known] created inside the page's window that the
  /// page does not list ([present]). Returns what was deleted, like
  /// [deleteNotifications].
  ///
  /// The window is open on both sides - strictly after [createdAfter] and
  /// strictly before [createdBefore], either of which may be absent - because
  /// the page is cut by a limit: other notifications created at the very
  /// instant of its oldest one may not have fitted, and absence from the page
  /// says nothing about them. [known] is what the store held BEFORE the page
  /// was asked for, so a notification that arrived while the request was out,
  /// and is therefore not in the page either, is left alone.
  ///
  /// Nothing gone is the ordinary outcome, and it writes nothing.
  Future<({List<SystemNotificationData> notifications, List<SystemNotificationOutboxEntryData> outbox})>
  deleteMissingFromPage({
    required Set<int> known,
    required Set<int> present,
    DateTime? createdAfter,
    DateTime? createdBefore,
  }) async {
    final unlisted = await _unlistedInWindow(present, createdAfter: createdAfter, createdBefore: createdBefore);
    // Narrowed here rather than in the query: the snapshot may be the whole
    // store, and one bound variable per id has a ceiling.
    final gone = unlisted.where(known.contains).toList();
    if (gone.isEmpty) return (notifications: <SystemNotificationData>[], outbox: <SystemNotificationOutboxEntryData>[]);

    return deleteNotifications(gone);
  }

  Future<List<int>> _unlistedInWindow(Set<int> present, {DateTime? createdAfter, DateTime? createdBefore}) {
    final query = selectOnly(systemNotificationsTable)
      ..addColumns([systemNotificationsTable.id])
      ..where(systemNotificationsTable.id.isNotIn(present));
    if (createdAfter != null) {
      query.where(systemNotificationsTable.createdAtRemoteUsec.isBiggerThanValue(createdAfter.microsecondsSinceEpoch));
    }
    if (createdBefore != null) {
      query.where(
        systemNotificationsTable.createdAtRemoteUsec.isSmallerThanValue(createdBefore.microsecondsSinceEpoch),
      );
    }
    return query.map((row) => row.read(systemNotificationsTable.id)!).get();
  }

  //
  // Outbox section
  //
  Future<List<SystemNotificationOutboxEntryData>> getOutboxNotifications(
    SnOutboxDataActionType? actionType, {
    List<SnOutboxDataState> states = SnOutboxDataState.values,
  }) {
    final query = select(systemNotificationsOutboxTable);
    if (actionType != null) query.where((tbl) => tbl.actionType.equals(actionType.name));
    query.where((tbl) => tbl.state.isIn(states.map((e) => e.name).toList()));
    return query.get();
  }

  Stream<List<SystemNotificationOutboxEntryData>> watchOutboxNotifications() {
    return select(systemNotificationsOutboxTable).watch();
  }

  Future<void> upsertOutboxNotification(SystemNotificationOutboxEntryData notification) {
    return into(systemNotificationsOutboxTable).insertOnConflictUpdate(notification);
  }

  Future<int> deleteOutboxNotification(int id, SnOutboxDataActionType actionType) {
    return (delete(systemNotificationsOutboxTable)
          ..where((tbl) => tbl.notificationId.equals(id))
          ..where((tbl) => tbl.actionType.equals(actionType.name)))
        .go();
  }

  Future<void> wipeData() async {
    await transaction(() async {
      await delete(systemNotificationsTable).go();
      await delete(systemNotificationsOutboxTable).go();
    });
  }
}
