import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/data/data.dart' show AppDatabase;
import 'package:webtrit_phone/features/system_notifications/system_notifications.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/push_notification/app_local_push.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _Remote extends Mock implements SystemNotificationsRemoteRepository {}

class _RemotePush extends Mock implements RemotePushRepository {}

class _LocalPush extends Mock implements LocalPushRepository {}

SystemNotification _notification(int id) => SystemNotification(
  id: id,
  title: 'Notification $id',
  content: 'Content $id',
  type: SystemNotificationType.system,
  seen: false,
  createdAt: DateTime(2026, 1, id),
  updatedAt: DateTime(2026, 1, id),
);

void main() {
  setUpAll(() => registerFallbackValue(AppLocalPush(0, '', '')));

  for (final emptyHistory in [true, false]) {
    for (final producePush in [true, false]) {
      test(
        'new notifications after ${emptyHistory ? 'empty' : 'populated'} history, local push $producePush',
        () async {
          final database = AppDatabase(NativeDatabase.memory());
          addTearDown(database.close);
          final local = SystemNotificationsLocalRepositoryDriftImpl(database);
          final remote = _Remote();
          final localPush = _LocalPush();
          final remotePush = _RemotePush();
          when(() => localPush.systemNotificationsActions).thenAnswer((_) => const Stream.empty());
          when(() => remotePush.systemNotificationsOpenedPushs).thenAnswer((_) => const Stream.empty());
          when(() => remotePush.systemNotificationsForegroundPushs).thenAnswer((_) => const Stream.empty());
          when(() => localPush.displayPush(any())).thenAnswer((_) async {});
          final pushes = SystemNotificationsPushService(
            remotePush,
            localPush,
            local,
            openNotifications: () {},
            producePush: producePush,
          )..init();
          addTearDown(pushes.dispose);
          final worker = SystemNotificationsSyncWorker(local, remote);
          addTearDown(worker.dispose);
          final historical = _notification(1);
          when(() => remote.getHistory(limit: 50)).thenAnswer((_) async => emptyHistory ? [] : [historical]);

          await worker.refresh();
          await pumpEventQueue();
          verifyNever(() => localPush.displayPush(any()));

          final news = _notification(2);
          if (emptyHistory) {
            expect(await local.getLastUpdate(), isNull);
            when(() => remote.getHistory(limit: 50)).thenAnswer((_) async => [news]);
          } else {
            when(() => remote.getUpdates(since: historical.updatedAt, limit: 50)).thenAnswer((_) async => [news]);
            // The history the cycle reconciles against carries the news too.
            when(() => remote.getHistory(limit: 50)).thenAnswer((_) async => [news, historical]);
          }
          await worker.refresh();
          await pumpEventQueue();

          expect(await local.getNotificationById(news.id), news);
          if (producePush) {
            final push = verify(() => localPush.displayPush(captureAny())).captured.single as AppLocalPush;
            expect(push.id, news.id);
            expect(push.title, news.title);
            expect(push.body, news.content);
          } else {
            verifyNever(() => localPush.displayPush(any()));
          }
        },
      );
    }
  }

  test('a store emptied by deleting is not a first load: nothing is read back, nothing is pushed', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final local = SystemNotificationsLocalRepositoryDriftImpl(database);
    final remote = _Remote();
    final localPush = _LocalPush();
    final remotePush = _RemotePush();
    when(() => localPush.systemNotificationsActions).thenAnswer((_) => const Stream.empty());
    when(() => remotePush.systemNotificationsOpenedPushs).thenAnswer((_) => const Stream.empty());
    when(() => remotePush.systemNotificationsForegroundPushs).thenAnswer((_) => const Stream.empty());
    when(() => localPush.displayPush(any())).thenAnswer((_) async {});
    when(() => localPush.dismissByContent(any(), any())).thenAnswer((_) async {});
    final pushes = SystemNotificationsPushService(
      remotePush,
      localPush,
      local,
      openNotifications: () {},
      producePush: true,
    )..init();
    addTearDown(pushes.dispose);
    final worker = SystemNotificationsSyncWorker(local, remote);
    addTearDown(worker.dispose);

    final stored = _notification(3);
    when(() => remote.getHistory(limit: 50)).thenAnswer((_) async => [stored]);
    await worker.refresh();

    // Everything on the device is deleted. The backend still has older,
    // unseen history, which a first load would read back and push.
    await local.deleteNotifications([stored.id]);
    await pumpEventQueue();
    when(() => remote.getHistory(limit: 50)).thenAnswer((_) async => [_notification(1), _notification(2)]);
    when(() => remote.getUpdates(since: stored.updatedAt, limit: 50)).thenAnswer((_) async => []);

    await worker.refresh();
    await pumpEventQueue();

    verify(() => remote.getHistory(limit: 50)).called(1);
    verify(() => remote.getUpdates(since: stored.updatedAt, limit: 50)).called(1);
    expect(await local.getNotifications(), isEmpty);
    verifyNever(() => localPush.displayPush(any()));
    // And the deleted notification's own push left the shade.
    verify(() => localPush.dismissByContent(stored.title, stored.content)).called(1);
  });
}
