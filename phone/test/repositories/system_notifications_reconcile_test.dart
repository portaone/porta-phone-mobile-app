import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';

import 'package:webtrit_phone/data/data.dart' show AppDatabase;
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

// A notification deleted on another device, or by the backend's retention
// cleaner, is never reported: the row is simply gone there. The store learns
// of it only by comparing itself with a history page, and the comparison has
// to stay inside what that page can vouch for - its window - and inside what
// the store held before the page was asked for.
void main() {
  // Created on day [id] of September 2026, so ids order the notifications in time.
  SystemNotification notification(int id) => SystemNotification(
    id: id,
    title: 'Notification $id',
    content: 'Content $id',
    seen: true,
    type: SystemNotificationType.system,
    createdAt: DateTime.utc(2026, 9, id),
    updatedAt: DateTime.utc(2026, 9, id),
  );

  late AppDatabase database;
  late SystemNotificationsLocalRepositoryDriftImpl local;

  Future<List<int>> stored() async => (await local.getNotifications()).map((n) => n.id).toList();

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    local = SystemNotificationsLocalRepositoryDriftImpl(database);
    await local.upsertNotifications([for (var id = 1; id <= 6; id++) notification(id)], silent: true);
  });

  tearDown(() => database.close());

  test('what the page does not list inside its window is deleted, the rest stays', () async {
    // The backend's page between day 2 and day 6 lists 5 and 3: 4 is gone there.
    await local.deleteMissingFromPage(
      known: {1, 2, 3, 4, 5, 6},
      present: {5, 3},
      createdAfter: DateTime.utc(2026, 9, 2),
      createdBefore: DateTime.utc(2026, 9, 6),
    );

    expect(await stored(), [6, 5, 3, 2, 1]);
  });

  test('the page vouches for nothing at the instant of its oldest notification, nor older', () async {
    // A full page ending at 3: another notification of that same instant may
    // not have fitted, and 2 and 1 are simply further down the history.
    await local.deleteMissingFromPage(
      known: {1, 2, 3, 4, 5, 6},
      present: {6, 5, 4},
      createdAfter: DateTime.utc(2026, 9, 3),
    );

    expect(await stored(), [6, 5, 4, 3, 2, 1]);
  });

  test('nothing at or after the upper bound is touched', () async {
    await local.deleteMissingFromPage(known: {1, 2, 3, 4, 5, 6}, present: {}, createdBefore: DateTime.utc(2026, 9, 3));

    expect(await stored(), [6, 5, 4, 3]);
  });

  test('a page that reached the end of the history speaks for everything older', () async {
    // The newest page came back short: the backend has only 6 and 2.
    await local.deleteMissingFromPage(known: {1, 2, 3, 4, 5, 6}, present: {6, 2});

    expect(await stored(), [6, 2]);
  });

  test('a notification that arrived while the page was on its way is left alone', () async {
    // 6 was stored after the snapshot was taken, so the page cannot list it.
    await local.deleteMissingFromPage(known: {1, 2, 3, 4, 5}, present: {5, 4, 3, 2, 1});

    expect(await stored(), [6, 5, 4, 3, 2, 1]);
  });

  test('a deleted notification takes its outbox entries with it and is announced', () async {
    await local.upsertOutboxNotification(
      const SystemNotificationOutboxEntry(notificationId: 4, actionType: SnOutboxActionType.seen),
    );
    final events = <SystemNotificationEvent>[];
    final sub = local.eventBus.listen(events.add);
    addTearDown(sub.cancel);

    await local.deleteMissingFromPage(known: {1, 2, 3, 4, 5, 6}, present: {6, 5, 3, 2, 1});
    await pumpEventQueue();

    expect(await local.getOutboxNotifications(), isEmpty);
    expect(events.whereType<SystemNotificationRemove>().single.notification.title, 'Notification 4');
    expect(events.whereType<SystemNotificationOutboxRemove>().single.id, 4);
  });

  test('the oldest unseen notification is the one the unseen count reaches down to', () async {
    SystemNotification unseen(int id) => notification(id).copyWith(seen: false);
    await local.upsertNotifications([unseen(2), unseen(3), unseen(5)], silent: true);
    // 2 has a seen receipt queued and 3 a delete: the count leaves both out.
    await local.upsertOutboxNotification(
      const SystemNotificationOutboxEntry(notificationId: 2, actionType: SnOutboxActionType.seen),
    );
    await local.queueDeletes([3]);

    expect(await local.unseenCount().first, 1);
    expect(await local.getOldestUnseenCreatedAt(), DateTime.utc(2026, 9, 5).toLocal());
  });

  test('with nothing unseen there is no oldest unseen', () async {
    expect(await local.getOldestUnseenCreatedAt(), isNull);
  });

  test('an empty snapshot deletes nothing', () async {
    final events = <SystemNotificationEvent>[];
    final sub = local.eventBus.listen(events.add);
    addTearDown(sub.cancel);

    await local.deleteMissingFromPage(known: {}, present: {});
    await pumpEventQueue();

    expect(await stored(), [6, 5, 4, 3, 2, 1]);
    expect(events, isEmpty);
  });
}
