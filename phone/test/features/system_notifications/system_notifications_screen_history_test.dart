import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/system_notifications/system_notifications.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import 'idle_outbox.dart';

class _Local extends Mock implements SystemNotificationsLocalRepository {}

class _Remote extends Mock implements SystemNotificationsRemoteRepository {}

SystemNotification _notification(int id) => SystemNotification(
  id: id,
  title: 'title $id',
  content: 'content $id',
  type: SystemNotificationType.system,
  seen: true,
  createdAt: DateTime.utc(2026, 1, id),
  updatedAt: DateTime.utc(2026, 1, id),
);

// Scrolling back through the list. A page the store already holds is shown
// from it at once, and may hold what was deleted on another device since: it
// is then compared with the backend behind the person's back, and what is gone
// leaves through the store's remove event.
void main() {
  late _Local local;
  late _Remote remote;
  late StreamController<SystemNotificationEvent> events;
  late SystemNotificationsScreenCubit cubit;

  final shown = _notification(5);

  setUpAll(() => registerFallbackValue(<int>{}));

  setUp(() async {
    local = _Local();
    remote = _Remote();
    events = StreamController.broadcast();
    when(() => local.eventBus).thenAnswer((_) => events.stream);
    when(() => local.getOutboxNotifications()).thenAnswer((_) async => []);
    when(() => local.getNotifications(limit: 2)).thenAnswer((_) async => [shown]);
    when(
      () => local.deleteMissingFromPage(
        known: any(named: 'known'),
        present: any(named: 'present'),
        createdAfter: any(named: 'createdAfter'),
        createdBefore: any(named: 'createdBefore'),
      ),
    ).thenAnswer((_) async {});
    cubit = SystemNotificationsScreenCubit(local, remote, outbox: idleOutbox(), pageSize: 2);
    await cubit.init();
  });

  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
    await events.close();
  });

  test('a page shown from the store is then compared with the backend', () async {
    when(() => local.getNotifications(from: shown.createdAt, limit: 2))
        .thenAnswer((_) async => [_notification(4), _notification(3)]);
    when(() => local.getNotificationIds()).thenAnswer((_) async => [5, 4, 3]);
    // The backend no longer has 4: its page below 5 is 3 and 2.
    when(() => remote.getHistory(since: shown.createdAt, limit: 2))
        .thenAnswer((_) async => [_notification(3), _notification(2)]);

    await cubit.fetchHistory();
    expect(cubit.state.notifications.map((n) => n.id), [5, 4, 3], reason: 'shown at once, as stored');
    await pumpEventQueue();

    verify(
      () => local.deleteMissingFromPage(
        known: {5, 4, 3},
        present: {3, 2},
        createdAfter: DateTime.utc(2026, 1, 2),
        createdBefore: shown.createdAt,
      ),
    ).called(1);
  });

  test('what the comparison finds gone leaves the list', () async {
    when(() => local.getNotifications(from: shown.createdAt, limit: 2))
        .thenAnswer((_) async => [_notification(4), _notification(3)]);
    when(() => local.getNotificationIds()).thenAnswer((_) async => [5, 4, 3]);
    when(() => remote.getHistory(since: shown.createdAt, limit: 2)).thenAnswer((_) async => [_notification(3)]);
    when(
      () => local.deleteMissingFromPage(
        known: any(named: 'known'),
        present: any(named: 'present'),
        createdAfter: any(named: 'createdAfter'),
        createdBefore: any(named: 'createdBefore'),
      ),
    ).thenAnswer((_) async => events.add(SystemNotificationRemove(_notification(4))));

    await cubit.fetchHistory();
    await pumpEventQueue();

    expect(cubit.state.notifications.map((n) => n.id), [5, 3]);
  });

  test('a comparison that fails leaves the page as it was shown', () async {
    when(() => local.getNotifications(from: shown.createdAt, limit: 2))
        .thenAnswer((_) async => [_notification(4), _notification(3)]);
    when(() => local.getNotificationIds()).thenAnswer((_) async => [5, 4, 3]);
    when(() => remote.getHistory(since: shown.createdAt, limit: 2)).thenThrow(Exception('offline'));

    await cubit.fetchHistory();
    await pumpEventQueue();

    expect(cubit.state.notifications.map((n) => n.id), [5, 4, 3]);
    expect(cubit.state.fetchingHistory, isFalse);
    verifyNever(
      () => local.deleteMissingFromPage(
        known: any(named: 'known'),
        present: any(named: 'present'),
        createdAfter: any(named: 'createdAfter'),
        createdBefore: any(named: 'createdBefore'),
      ),
    );
  });

  test('a row shown from far below the page is reached by reading further pages', () async {
    // The store is not contiguous: 1 arrived alone and is shown right after 4.
    when(() => local.getNotifications(from: shown.createdAt, limit: 2))
        .thenAnswer((_) async => [_notification(4), _notification(1)]);
    when(() => local.getNotificationIds()).thenAnswer((_) async => [5, 4, 1]);
    when(() => remote.getHistory(since: shown.createdAt, limit: 2))
        .thenAnswer((_) async => [_notification(4), _notification(3)]);
    when(() => remote.getHistory(since: DateTime.utc(2026, 1, 3), limit: 2))
        .thenAnswer((_) async => [_notification(2)]);

    await cubit.fetchHistory();
    await pumpEventQueue();

    // The second page is short - the end of the history - so 1 is judged, and is gone there.
    verify(() => local.deleteMissingFromPage(known: {5, 4, 1}, present: {2}, createdBefore: DateTime.utc(2026, 1, 3)))
        .called(1);
  });

  test('a comparison that comes back after the screen is closed judges nothing', () async {
    when(() => local.getNotifications(from: shown.createdAt, limit: 2))
        .thenAnswer((_) async => [_notification(4), _notification(3)]);
    when(() => local.getNotificationIds()).thenAnswer((_) async => [5, 4, 3]);
    final page = Completer<List<SystemNotification>>();
    when(() => remote.getHistory(since: shown.createdAt, limit: 2)).thenAnswer((_) => page.future);

    await cubit.fetchHistory();
    await pumpEventQueue();
    await cubit.close();
    page.complete([_notification(3)]);
    await pumpEventQueue();

    verifyNever(
      () => local.deleteMissingFromPage(
        known: any(named: 'known'),
        present: any(named: 'present'),
        createdAfter: any(named: 'createdAfter'),
        createdBefore: any(named: 'createdBefore'),
      ),
    );
  });

  test('a page read from the backend is not compared with it again', () async {
    when(() => local.getNotifications(from: shown.createdAt, limit: 2)).thenAnswer((_) async => []);
    when(() => remote.getHistory(since: shown.createdAt, limit: 2)).thenAnswer((_) async => [_notification(4)]);
    when(() => local.upsertNotifications(any(), silent: any(named: 'silent'))).thenAnswer((_) async {});

    await cubit.fetchHistory();
    await pumpEventQueue();

    expect(cubit.state.notifications.map((n) => n.id), [5, 4]);
    verify(() => remote.getHistory(since: shown.createdAt, limit: 2)).called(1);
    verifyNever(() => local.getNotificationIds());
  });
}
