import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:http/http.dart' as http;

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/services/services.dart';

import 'system_notifications_integration_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  systemNotificationsIntegrationTests((name, body) => test(name, body));
}

/// Shared scenarios run on the host and through Patrol on native SQLite.
void systemNotificationsIntegrationTests(void Function(String, Future<void> Function()) register) {
  for (final emptyHistory in [true, false]) {
    for (final producePush in [true, false]) {
      register('notifications: ${emptyHistory ? 'empty' : 'populated'} initial sync, push $producePush', () async {
        final harness = await SystemNotificationsIntegrationHarness.create(producePush: producePush);
        final historical = SystemNotificationsIntegrationHarness.notification(1);
        final news = SystemNotificationsIntegrationHarness.notification(2);
        harness.respond = (_) async => SystemNotificationsIntegrationHarness.response(emptyHistory ? [] : [historical]);

        await harness.owner.runNow();
        await pumpEventQueue();
        expect(harness.owner.state.phase, PollingTaskPhase.succeeded);
        expect(harness.pushes, isEmpty);
        expect(await harness.local.getLastUpdate(), emptyHistory ? isNull : historical.updatedAt);
        harness.expectRequest(0);

        harness.respond = (_) async => SystemNotificationsIntegrationHarness.response([news]);
        await harness.owner.runNow();
        await pumpEventQueue();
        expect(await harness.local.getNotificationById(news.id), news);
        harness.expectRequest(1, since: emptyHistory ? null : historical.updatedAt);
        expect(harness.requests, hasLength(2));
        if (producePush) {
          expect(harness.pushes, hasLength(1));
          expect(harness.pushes.single.id, news.id);
          expect(harness.pushes.single.title, news.title);
          expect(harness.pushes.single.body, news.content);
        } else {
          expect(harness.pushes, isEmpty);
        }
      });
    }
  }

  register('notifications: deleted on another device leaves this one, and its push with it', () async {
    final harness = await SystemNotificationsIntegrationHarness.create();
    final kept = SystemNotificationsIntegrationHarness.notification(1);
    final gone = SystemNotificationsIntegrationHarness.notification(2);
    harness.respond = (_) async => SystemNotificationsIntegrationHarness.response([gone, kept]);
    await harness.owner.runNow();
    await pumpEventQueue();
    // A seen receipt was still waiting to be sent for it.
    await harness.local.upsertOutboxNotification(
      SystemNotificationOutboxEntry(notificationId: gone.id, actionType: SnOutboxActionType.seen),
    );
    await pumpEventQueue();
    harness.dismissed.clear(); // marking it seen took its push out once already

    final deletedAt = DateTime.utc(2026, 9, 20);
    harness.respond = (_) async => SystemNotificationsIntegrationHarness.response([
      SystemNotificationsIntegrationHarness.deleted(gone, deletedAt),
    ]);
    await harness.owner.runNow();
    await pumpEventQueue();

    harness.expectRequest(1, since: gone.updatedAt);
    expect((await harness.local.getNotifications()).map((n) => n.id), [kept.id]);
    expect(await harness.local.getOutboxNotifications(), isEmpty);
    expect(harness.dismissed, [gone.title]);
    expect(harness.pushes, isEmpty);

    // The delete was read, so the next cycle asks from after it rather than
    // fetching it again - though nothing stored carries that moment.
    harness.respond = (_) async => SystemNotificationsIntegrationHarness.response([]);
    await harness.owner.runNow();
    harness.expectRequest(2, since: deletedAt);
  });

  register('notifications: everything deleted on another device is not a first load', () async {
    final harness = await SystemNotificationsIntegrationHarness.create();
    final only = SystemNotificationsIntegrationHarness.notification(3);
    harness.respond = (_) async => SystemNotificationsIntegrationHarness.response([only]);
    await harness.owner.runNow();
    await pumpEventQueue();

    final deletedAt = DateTime.utc(2026, 9, 20);
    harness.respond = (_) async => SystemNotificationsIntegrationHarness.response([
      SystemNotificationsIntegrationHarness.deleted(only, deletedAt),
    ]);
    await harness.owner.runNow();
    await pumpEventQueue();
    expect(await harness.local.getNotifications(), isEmpty);

    // The store is empty, but the older history is not read back as news.
    final older = SystemNotificationsIntegrationHarness.notification(1);
    harness.respond = (request) async => SystemNotificationsIntegrationHarness.response(
      SystemNotificationsIntegrationHarness.isUpdates(request) ? [] : [older],
    );
    await harness.owner.runNow();
    await pumpEventQueue();

    harness.expectRequest(2, since: deletedAt);
    expect(await harness.local.getNotifications(), isEmpty);
    expect(harness.pushes, isEmpty);
  });

  register('notifications: a backend that cannot report deletes is asked the old way from then on', () async {
    final harness = await SystemNotificationsIntegrationHarness.create();
    final historical = SystemNotificationsIntegrationHarness.notification(1);
    final news = SystemNotificationsIntegrationHarness.notification(2);
    harness.respond = (_) async => SystemNotificationsIntegrationHarness.response([historical]);
    await harness.owner.runNow();
    await pumpEventQueue();

    harness.respond = (request) async => request.url.queryParameters.containsKey('include_deleted')
        ? SystemNotificationsIntegrationHarness.includeDeletedRefused()
        : SystemNotificationsIntegrationHarness.response([news]);
    await harness.owner.runNow();
    await pumpEventQueue();

    // Refused once, repeated without the parameter, and the news is delivered.
    harness.expectRequest(1, since: historical.updatedAt);
    harness.expectRequest(2, since: historical.updatedAt, includeDeleted: false);
    expect(await harness.local.getNotificationById(news.id), news);
    expect(harness.owner.state.phase, PollingTaskPhase.succeeded);

    // The next cycle does not try the parameter again.
    await harness.owner.runNow();
    harness.expectRequest(3, since: news.updatedAt, includeDeleted: false);
    expect(harness.requests, hasLength(4));
  });

  register('notifications: failed initialization retries silently before delivering news', () async {
    final harness = await SystemNotificationsIntegrationHarness.create();
    harness.respond = (_) async => http.Response('unavailable', 503);
    await expectLater(harness.owner.runNow(), throwsA(isA<api.RequestFailure>()));
    expect(harness.owner.state.phase, PollingTaskPhase.failed);
    expect(harness.owner.state.lastSuccessAt, isNull);
    expect(await harness.local.getNotifications(), isEmpty);

    final historical = SystemNotificationsIntegrationHarness.notification(1);
    harness.respond = (_) async => SystemNotificationsIntegrationHarness.response([historical]);
    await harness.owner.runNow();
    await pumpEventQueue();
    expect(await harness.local.getNotificationById(historical.id), historical);
    expect(harness.pushes, isEmpty);

    final news = SystemNotificationsIntegrationHarness.notification(2);
    harness.respond = (_) async => SystemNotificationsIntegrationHarness.response([news]);
    await harness.owner.runNow();
    await pumpEventQueue();
    expect(harness.pushes.single.id, news.id);
    expect(harness.owner.state.phase, PollingTaskPhase.succeeded);
    expect(harness.requests, hasLength(3));
    harness.expectRequest(0);
    harness.expectRequest(1);
    harness.expectRequest(2, since: historical.updatedAt);
  });

  for (final updates in [false, true]) {
    register(
      'notifications: logout rejects late ${updates ? 'full updates page' : 'history'} without restoring data',
      () async {
        final harness = await SystemNotificationsIntegrationHarness.create();
        final cached = SystemNotificationsIntegrationHarness.notification(1);
        if (updates) await harness.local.upsertNotifications([cached], silent: true);
        final arrived = Completer<void>();
        final response = Completer<http.Response>();
        harness.respond = (_) {
          if (!arrived.isCompleted) arrived.complete();
          return response.future;
        };
        // Always unblock the request before disposing the harness, even on failure.
        addTearDown(() {
          if (!response.isCompleted) response.complete(SystemNotificationsIntegrationHarness.response([]));
        });
        final outcome = harness.owner.runNow().then<Object?>((_) => null, onError: (Object error) => error);
        await arrived.future.timeout(const Duration(seconds: 5));
        harness.expectRequest(0, since: updates ? cached.updatedAt : null);

        await harness.owner.dispose();
        await harness.database.deleteEverything();
        expect(await harness.local.getNotifications(), isEmpty);
        response.complete(
          SystemNotificationsIntegrationHarness.response([
            SystemNotificationsIntegrationHarness.notification(2),
            SystemNotificationsIntegrationHarness.notification(3),
          ]),
        );
        expect(await outcome.timeout(const Duration(seconds: 5)), isA<StateError>());
        await pumpEventQueue();

        expect(await harness.local.getNotifications(), isEmpty);
        expect(await harness.local.getLastUpdate(), isNull);
        expect(harness.pushes, isEmpty);
        expect(harness.requests, hasLength(1), reason: 'A retired worker must not fetch another full page');
        expect(harness.owner.state.phase, PollingTaskPhase.stopped);
        await expectLater(harness.owner.runNow(), throwsStateError);
      },
    );
  }
}
