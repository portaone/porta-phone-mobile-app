import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/system_notifications/system_notifications.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _Local extends Mock implements SystemNotificationsLocalRepository {}

class _Remote extends Mock implements SystemNotificationsRemoteRepository {}

DateTime _day(int day) => DateTime.utc(2026, 1, day);

SystemNotification _notification(int id) => SystemNotification(
  id: id,
  title: 'title $id',
  content: 'content $id',
  type: SystemNotificationType.system,
  seen: true,
  createdAt: _day(id),
  updatedAt: _day(id),
);

// What a reconciliation asks of the backend and what it then tells the store
// to judge. The deleting itself - the window, the snapshot - is tested against
// a real store in test/repositories/system_notifications_reconcile_test.dart.
void main() {
  late _Local local;
  late _Remote remote;
  late SystemNotificationsReconciler reconciler;

  setUpAll(() => registerFallbackValue(<int>{}));

  void verifyNothingJudged() => verifyNever(
    () => local.deleteMissingFromPage(
      known: any(named: 'known'),
      present: any(named: 'present'),
      createdAfter: any(named: 'createdAfter'),
      createdBefore: any(named: 'createdBefore'),
    ),
  );

  setUp(() {
    local = _Local();
    remote = _Remote();
    when(
      () => local.deleteMissingFromPage(
        known: any(named: 'known'),
        present: any(named: 'present'),
        createdAfter: any(named: 'createdAfter'),
        createdBefore: any(named: 'createdBefore'),
      ),
    ).thenAnswer((_) async {});
    when(() => local.getOldestUnseenCreatedAt()).thenAnswer((_) async => null);
    reconciler = SystemNotificationsReconciler(local, remote);
  });

  group('the top of the history', () {
    test('a full page vouches only down to its oldest notification', () async {
      when(() => local.getNotificationIds()).thenAnswer((_) async => [1, 2, 3, 4]);
      when(() => remote.getHistory(limit: 2)).thenAnswer((_) async => [_notification(4), _notification(3)]);

      await reconciler.reconcileNewest(limit: 2);

      verify(() => local.deleteMissingFromPage(known: {1, 2, 3, 4}, present: {4, 3}, createdAfter: _day(3))).called(1);
      verify(() => remote.getHistory(limit: 2)).called(1);
    });

    // The assumption the whole deletion below a short page rests on: the
    // backend returns as many as were asked for whenever it has them. Core
    // applies the limit it is given and has no ceiling of its own. If that
    // ever stops being true, this is the behaviour to change first.
    test('a short page is taken for the end of the history and speaks for all of it', () async {
      when(() => local.getNotificationIds()).thenAnswer((_) async => [1, 2, 3]);
      when(() => remote.getHistory(limit: 5)).thenAnswer((_) async => [_notification(3)]);

      await reconciler.reconcileNewest(limit: 5);

      verify(() => local.deleteMissingFromPage(known: {1, 2, 3}, present: {3})).called(1);
    });

    test('goes on below the first page while an unseen notification is stored further down', () async {
      // The unseen badge counts 2, which the first page does not reach.
      when(() => local.getNotificationIds()).thenAnswer((_) async => [2, 4, 5, 6]);
      when(() => local.getOldestUnseenCreatedAt()).thenAnswer((_) async => _day(2));
      when(() => remote.getHistory(limit: 2)).thenAnswer((_) async => [_notification(6), _notification(5)]);
      when(() => remote.getHistory(since: _day(5), limit: 2))
          .thenAnswer((_) async => [_notification(4), _notification(3)]);
      when(() => remote.getHistory(since: _day(3), limit: 2)).thenAnswer((_) async => [_notification(1)]);

      await reconciler.reconcileNewest(limit: 2);

      verifyInOrder([
        () => local.deleteMissingFromPage(known: {2, 4, 5, 6}, present: {6, 5}, createdAfter: _day(5)),
        () => local.deleteMissingFromPage(
          known: {2, 4, 5, 6},
          present: {4, 3},
          createdAfter: _day(3),
          createdBefore: _day(5),
        ),
        // Short: the end of the history, so 2 - deleted elsewhere - is judged at last.
        () => local.deleteMissingFromPage(known: {2, 4, 5, 6}, present: {1}, createdBefore: _day(3)),
      ]);
    });

    test('stops after its page limit rather than crawl the whole history', () async {
      reconciler = SystemNotificationsReconciler(local, remote, maxPages: 2);
      when(() => local.getNotificationIds()).thenAnswer((_) async => [1, 9]);
      when(() => local.getOldestUnseenCreatedAt()).thenAnswer((_) async => _day(1));
      when(() => remote.getHistory(limit: 1)).thenAnswer((_) async => [_notification(9)]);
      when(() => remote.getHistory(since: _day(9), limit: 1)).thenAnswer((_) async => [_notification(8)]);

      await reconciler.reconcileNewest(limit: 1);

      verify(() => remote.getHistory(limit: 1)).called(1);
      verify(() => remote.getHistory(since: _day(9), limit: 1)).called(1);
      verifyNever(() => remote.getHistory(since: _day(8), limit: 1));
    });

    test('an empty store asks the backend nothing', () async {
      when(() => local.getNotificationIds()).thenAnswer((_) async => []);

      await reconciler.reconcileNewest(limit: 50);

      verifyZeroInteractions(remote);
      verifyNothingJudged();
    });

    test('a caller retired while the page was on its way writes nothing', () async {
      var wanted = true;
      when(() => local.getNotificationIds()).thenAnswer((_) async => [1]);
      when(() => remote.getHistory(limit: 50)).thenAnswer((_) async {
        wanted = false;
        return [];
      });

      await expectLater(
        reconciler.reconcileNewest(limit: 50, stillWanted: () => wanted ? null : throw StateError('retired')),
        throwsStateError,
      );

      verifyNothingJudged();
    });
  });

  group('a stretch shown from the store', () {
    test('one page is enough when it reaches below the oldest row shown', () async {
      when(() => local.getNotificationIds()).thenAnswer((_) async => [1, 2, 3, 4]);
      when(() => remote.getHistory(since: _day(5), limit: 2))
          .thenAnswer((_) async => [_notification(4), _notification(2)]);

      await reconciler.reconcileBelow(before: _day(5), downTo: _day(3), limit: 2);

      verify(
        () => local.deleteMissingFromPage(
          known: {1, 2, 3, 4},
          present: {4, 2},
          createdAfter: _day(2),
          createdBefore: _day(5),
        ),
      ).called(1);
      verify(() => remote.getHistory(since: _day(5), limit: 2)).called(1);
    });

    test('a row shown from far below is reached page by page', () async {
      // The store is not contiguous: 1 arrived alone, through an update, and
      // was shown right after 5. The page below 6 ends well above it.
      when(() => local.getNotificationIds()).thenAnswer((_) async => [1, 5]);
      when(() => remote.getHistory(since: _day(6), limit: 2))
          .thenAnswer((_) async => [_notification(5), _notification(4)]);
      when(() => remote.getHistory(since: _day(4), limit: 2))
          .thenAnswer((_) async => [_notification(3), _notification(2)]);
      when(() => remote.getHistory(since: _day(2), limit: 2)).thenAnswer((_) async => []);

      await reconciler.reconcileBelow(before: _day(6), downTo: _day(1), limit: 2);

      verifyInOrder([
        () => remote.getHistory(since: _day(6), limit: 2),
        () => remote.getHistory(since: _day(4), limit: 2),
        () => remote.getHistory(since: _day(2), limit: 2),
        () => local.deleteMissingFromPage(known: {1, 5}, present: {}, createdBefore: _day(2)),
      ]);
    });
  });
}
