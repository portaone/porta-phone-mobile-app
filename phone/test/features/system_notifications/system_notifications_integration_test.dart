import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:http/http.dart' as http;

import 'package:api/api.dart' as api;

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

        harness.respond = harness.serving(updates: [news], history: emptyHistory ? [news] : [news, historical]);
        await harness.owner.runNow();
        await pumpEventQueue();
        expect(await harness.local.getNotificationById(news.id), news);
        harness.expectRequest(1, since: emptyHistory ? null : historical.updatedAt);
        if (emptyHistory) {
          expect(harness.requests, hasLength(2));
        } else {
          // A cycle of updates ends by reading the top of the history, to
          // notice what was deleted elsewhere - as far down as the oldest
          // unseen notification, here the page below the first. Nothing was
          // deleted, so nothing changes.
          harness.expectRequest(2);
          harness.expectHistoryBelow(3, historical.createdAt);
          expect(harness.requests, hasLength(4));
          expect(await harness.local.getNotificationById(historical.id), historical);
        }
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
    harness.respond = harness.serving(updates: [news], history: [news, historical]);
    await harness.owner.runNow();
    await pumpEventQueue();
    expect(harness.pushes.single.id, news.id);
    expect(harness.owner.state.phase, PollingTaskPhase.succeeded);
    expect(harness.requests, hasLength(5));
    harness.expectRequest(0);
    harness.expectRequest(1);
    harness.expectRequest(2, since: historical.updatedAt);
    harness.expectRequest(3);
    harness.expectHistoryBelow(4, historical.createdAt);
  });

  register('notifications: one deleted on another device leaves the store on the next cycle', () async {
    final harness = await SystemNotificationsIntegrationHarness.create();
    final kept = SystemNotificationsIntegrationHarness.notification(1);
    final gone = SystemNotificationsIntegrationHarness.notification(2);
    harness.respond = (_) async => SystemNotificationsIntegrationHarness.response([gone, kept]);
    await harness.owner.runNow();
    await pumpEventQueue();
    expect(await harness.local.getNotifications(), hasLength(2));

    // The backend no longer has it and says so nowhere: no update, a shorter history.
    harness.respond = harness.serving(updates: [], history: [kept]);
    await harness.owner.runNow();
    await pumpEventQueue();

    expect(await harness.local.getNotificationById(gone.id), isNull);
    expect(await harness.local.getNotificationById(kept.id), kept);
    expect(harness.dismissed, [gone.title]);
    expect(harness.pushes, isEmpty);
    expect(harness.owner.state.phase, PollingTaskPhase.succeeded);
  });

  register('notifications: a history that cannot be read does not hold the updates back', () async {
    final harness = await SystemNotificationsIntegrationHarness.create();
    final historical = SystemNotificationsIntegrationHarness.notification(1);
    final news = SystemNotificationsIntegrationHarness.notification(2);
    harness.respond = (_) async => SystemNotificationsIntegrationHarness.response([historical]);
    await harness.owner.runNow();
    await pumpEventQueue();

    harness.respond = (request) async => request.url.path.endsWith('/updates')
        ? SystemNotificationsIntegrationHarness.response([news])
        : http.Response('unavailable', 503);
    await harness.owner.runNow();
    await pumpEventQueue();

    // The news is delivered and the cycle counts as done: comparing with the
    // history only tidies up, and is tried again with the next cycle.
    expect(await harness.local.getNotificationById(news.id), news);
    expect(harness.pushes.single.id, news.id);
    expect(harness.owner.state.phase, PollingTaskPhase.succeeded);
  });

  register('notifications: all deleted on another device is not a first load, and raises nothing', () async {
    final harness = await SystemNotificationsIntegrationHarness.create();
    final stored = SystemNotificationsIntegrationHarness.notification(3);
    // Stored by an earlier session: this worker finds it there and has stored nothing itself.
    await harness.local.upsertNotifications([stored], silent: true);

    // The other device deleted what it held; the backend still has older, unseen history.
    final older = [
      SystemNotificationsIntegrationHarness.notification(1),
      SystemNotificationsIntegrationHarness.notification(2),
    ];
    harness.respond = harness.serving(updates: [], history: older);
    await harness.owner.runNow();
    await pumpEventQueue();
    expect(await harness.local.getNotifications(), isEmpty);

    await harness.owner.runNow();
    await pumpEventQueue();

    // The emptied store is still read from where it stood: updates, not the history again.
    harness.expectRequest(harness.requests.length - 1, since: stored.updatedAt);
    expect(await harness.local.getNotifications(), isEmpty);
    expect(harness.pushes, isEmpty);
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
