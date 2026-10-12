import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/data/data.dart' show AppDatabase;
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

// Deleting notifications through both repositories. The local one must take
// the outbox with it - a seen receipt for a deleted notification can never be
// confirmed and would be retried forever - and the remote one must treat a
// notification the backend no longer has as deleted, not as a failure.
void main() {
  SystemNotification notification(int id, {bool seen = false}) => SystemNotification(
    id: id,
    title: 'Notification $id',
    content: 'Content $id',
    seen: seen,
    type: SystemNotificationType.system,
    createdAt: DateTime.utc(2026, 9, id),
    updatedAt: DateTime.utc(2026, 9, id),
  );

  group('local repository', () {
    late AppDatabase database;
    late SystemNotificationsLocalRepositoryDriftImpl local;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      local = SystemNotificationsLocalRepositoryDriftImpl(database);
      await local.upsertNotifications([notification(1), notification(2), notification(3)], silent: true);
    });

    tearDown(() => database.close());

    test('deletes the given notifications and keeps the rest', () async {
      await local.deleteNotifications([1, 3]);

      final left = await local.getNotifications();
      expect(left.map((n) => n.id), [2]);
    });

    test('takes the outbox entries of deleted notifications with them', () async {
      await local.upsertOutboxNotification(
        const SystemNotificationOutboxEntry(notificationId: 1, actionType: SnOutboxActionType.seen),
      );
      await local.upsertOutboxNotification(
        const SystemNotificationOutboxEntry(notificationId: 2, actionType: SnOutboxActionType.seen),
      );

      await local.deleteNotifications([1]);

      final outbox = await local.getOutboxNotifications();
      expect(outbox.map((e) => e.notificationId), [2]);
    });

    test('the unseen count drops when an unseen notification is deleted', () async {
      expect(await local.unseenCount().first, 3);

      await local.deleteNotifications([1, 2]);

      expect(await local.unseenCount().first, 1);
    });

    test('tells listeners what was removed', () async {
      await local.upsertOutboxNotification(
        const SystemNotificationOutboxEntry(notificationId: 1, actionType: SnOutboxActionType.seen),
      );
      final events = <SystemNotificationEvent>[];
      final sub = local.eventBus.listen(events.add);
      addTearDown(sub.cancel);

      await local.deleteNotifications([1, 2]);
      await pumpEventQueue();

      expect(
        events,
        unorderedEquals([
          SystemNotificationOutboxRemove(1, SnOutboxActionType.seen),
          SystemNotificationRemove(notification(1)),
          SystemNotificationRemove(notification(2)),
        ]),
      );
    });

    test('a remove event carries the notification, for whoever must find it by its text', () async {
      final events = <SystemNotificationEvent>[];
      final sub = local.eventBus.listen(events.add);
      addTearDown(sub.cancel);

      await local.deleteNotifications([2, 99]);
      await pumpEventQueue();

      final removes = events.whereType<SystemNotificationRemove>().toList();
      final removed = removes.single.notification;
      expect((removed.title, removed.content), ('Notification 2', 'Content 2'));
      // 99 was never stored: on no screen and in no shade, so nothing is said about it.
    });

    test('deleting one goes the same way', () async {
      await local.upsertOutboxNotification(
        const SystemNotificationOutboxEntry(notificationId: 2, actionType: SnOutboxActionType.seen),
      );

      await local.deleteNotification(2);

      expect((await local.getNotifications()).map((n) => n.id), [3, 1]);
      expect(await local.getOutboxNotifications(), isEmpty);
    });

    group('queued delete', () {
      test('hides the notifications from the list, the ids and the unseen count', () async {
        await local.queueDeletes([1, 3]);

        expect((await local.getNotifications()).map((n) => n.id), [2]);
        expect(await local.getNotificationIds(), [2]);
        expect(await local.unseenCount().first, 1);
      });

      test('keeps them stored, with a pending delete in the outbox', () async {
        await local.queueDeletes([1]);

        expect(await local.getNotificationById(1), isNotNull);
        final queued = await local.getOutboxNotifications(actionType: SnOutboxActionType.delete);
        expect(queued.single.notificationId, 1);
        expect(queued.single.state, SnOutboxState.pending);
      });

      test('says they left, with their text for whoever must find them by it', () async {
        final events = <SystemNotificationEvent>[];
        final sub = local.eventBus.listen(events.add);
        addTearDown(sub.cancel);

        await local.queueDeletes([2, 99]);
        await pumpEventQueue();

        final removed = events.whereType<SystemNotificationRemove>().single;
        expect(removed.id, 2);
        expect(removed.notification.title, 'Notification 2');
        // 99 is not stored: nothing to hide and nothing for the outbox row to reference.
        expect(await local.getOutboxNotifications(actionType: SnOutboxActionType.delete), hasLength(1));
      });

      test('a sync that brings one back before the backend confirms is not news', () async {
        await local.queueDeletes([1]);
        final events = <SystemNotificationEvent>[];
        final sub = local.eventBus.listen(events.add);
        addTearDown(sub.cancel);

        await local.upsertNotifications([notification(1, seen: true), notification(4)]);
        await pumpEventQueue();

        expect(events.whereType<SystemNotificationUpdate>().map((e) => e.id), [4]);
        expect((await local.getNotifications()).map((n) => n.id), isNot(contains(1)));
      });

      test('the confirmed delete removes the row and the queued entry', () async {
        await local.queueDeletes([1]);

        await local.deleteNotifications([1]);

        expect(await local.getNotificationById(1), isNull);
        expect(await local.getOutboxNotifications(), isEmpty);
      });
    });

    test('an empty list touches nothing', () async {
      final events = <SystemNotificationEvent>[];
      final sub = local.eventBus.listen(events.add);
      addTearDown(sub.cancel);

      await local.deleteNotifications([]);
      await pumpEventQueue();

      expect((await local.getNotifications()).length, 3);
      expect(events, isEmpty);
    });
  });

  group('remote repository', () {
    final requests = <http.Request>[];
    late http.Response Function(http.Request) respond;
    late api.WebtritApiClient client;
    late SystemNotificationsRemoteRepositoryApiImpl remote;

    http.Response json(Object body, int status) =>
        http.Response(jsonEncode(body), status, headers: const {'content-type': 'application/json'});

    setUp(() {
      requests.clear();
      client = api.WebtritApiClient.inner(
        Uri.parse('https://delete.test'),
        '',
        httpClient: MockClient((request) async {
          requests.add(request);
          return respond(request);
        }),
      );
      remote = SystemNotificationsRemoteRepositoryApiImpl(client, 'token');
    });

    tearDown(() => client.close());

    test('deletes one notification', () async {
      respond = (_) => http.Response('', 204);

      await remote.deleteNotification(12);

      expect(requests.single.method, equalsIgnoringCase('DELETE'));
      expect(requests.single.url.path, '/api/v1/user/notifications/12');
    });

    test('one the backend no longer has counts as deleted', () async {
      respond = (_) => json({'code': 'notification_not_found'}, 404);

      await expectLater(remote.deleteNotification(12), completes);
    });

    test('any other refusal is still a failure', () async {
      respond = (_) => json({'code': 'session_not_found'}, 404);

      await expectLater(remote.deleteNotification(12), throwsA(isA<api.RequestFailure>()));
    });

    test('deletes several and returns only what the backend deleted', () async {
      respond = (_) => json({
        'deleted_ids': [12],
      }, 200);

      final deleted = await remote.deleteNotifications([12, 15]);

      expect(deleted, [12]);
      expect(requests.single.method, equalsIgnoringCase('DELETE'));
      expect(jsonDecode(requests.single.body), {
        'ids': [12, 15],
      });
    });

    test('a Core without the bulk route gets one delete per id', () async {
      respond = (request) => request.url.path == '/api/v1/user/notifications'
          ? json({'message': 'Not Found'}, 404)
          : http.Response('', 204);

      final deleted = await remote.deleteNotifications([12, 15]);

      expect(deleted, [12, 15]);
      expect(requests.map((r) => r.url.path), [
        '/api/v1/user/notifications',
        '/api/v1/user/notifications/12',
        '/api/v1/user/notifications/15',
      ]);
    });

    test('a seen receipt for a notification the backend no longer has counts as sent', () async {
      respond = (_) => json({'code': 'notification_not_found'}, 404);

      await expectLater(remote.markSystemNotificationAsSeen(12), completes);
    });

    test('nothing to delete sends nothing', () async {
      respond = (_) => fail('no request expected');

      final deleted = await remote.deleteNotifications([]);

      expect(deleted, isEmpty);
      expect(requests, isEmpty);
    });
  });
}
