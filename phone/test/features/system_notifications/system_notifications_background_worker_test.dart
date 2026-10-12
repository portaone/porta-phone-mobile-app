import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/system_notifications/system_notifications.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/push_notification/app_local_push.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _Local extends Mock implements SystemNotificationsLocalRepository {}

class _Remote extends Mock implements SystemNotificationsRemoteRepository {}

class _Push extends Mock implements LocalPushRepository {}

SystemNotification _notification(int id, {bool seen = false}) => SystemNotification(
  id: id,
  title: 'title $id',
  content: 'content $id',
  type: SystemNotificationType.system,
  seen: seen,
  createdAt: DateTime.utc(2026, 1, id),
  updatedAt: DateTime.utc(2026, 1, id),
);

SystemNotification _deleted(int id, DateTime at) =>
    _notification(id).copyWith(title: '-', content: '-', updatedAt: at, deletedAt: at);

// The task that syncs while the app is closed. It has no memory between runs
// and resumes from what is stored - which a deleted notification never is.
void main() {
  late _Local local;
  late _Remote remote;
  late _Push push;
  late SystemNotificationBackgroundWorker worker;
  final anchor = DateTime.utc(2026, 1, 1);

  setUpAll(() => registerFallbackValue(AppLocalPush(0, '', '')));

  setUp(() {
    local = _Local();
    remote = _Remote();
    push = _Push();
    when(() => local.getLastUpdate()).thenAnswer((_) async => anchor);
    when(() => local.upsertNotifications(any())).thenAnswer((_) async {});
    when(() => push.displayPush(any())).thenAnswer((_) async {});
    when(() => push.dismissByContent(any(), any())).thenAnswer((_) async {});
    when(() => local.getNotificationById(any())).thenAnswer((_) async => null);
    worker = SystemNotificationBackgroundWorker(local, remote, push);
  });

  List<int> pushed() =>
      verify(() => push.displayPush(captureAny())).captured.map((p) => (p as AppLocalPush).id).toList();

  test('reads past a page of deletes to the news behind it', () async {
    // Fifty deletes fill the first page; the unseen notification is on the second.
    final deletes = [for (var i = 0; i < 50; i++) _deleted(100 + i, DateTime.utc(2026, 2, 1, 0, i))];
    final news = _notification(7).copyWith(updatedAt: DateTime.utc(2026, 2, 2));
    when(() => remote.getUpdates(since: anchor, limit: 50)).thenAnswer((_) async => deletes);
    when(() => remote.getUpdates(since: deletes.last.updatedAt, limit: 50)).thenAnswer((_) async => [news]);

    expect(await worker.execute(), isTrue);

    verify(() => local.upsertNotifications([...deletes, news])).called(1);
    expect(pushed(), [news.id]);
  });

  test('raises no push for a notification that arrives deleted', () async {
    final gone = _deleted(3, DateTime.utc(2026, 2, 1));
    when(() => remote.getUpdates(since: anchor, limit: 50))
        .thenAnswer((_) async => [gone, _notification(4, seen: true)]);

    expect(await worker.execute(), isTrue);

    verifyNever(() => push.displayPush(any()));
  });

  test('takes the push of a notification deleted elsewhere out of the shade', () async {
    // Nothing listens to the store in this isolate, so the task dismisses by hand,
    // with the text the push was raised with - the deleted one arrives without it.
    final stored = _notification(3);
    when(() => local.getNotificationById(3)).thenAnswer((_) async => stored);
    when(() => remote.getUpdates(since: anchor, limit: 50))
        .thenAnswer((_) async => [_deleted(3, DateTime.utc(2026, 2, 1)), _deleted(8, DateTime.utc(2026, 2, 1))]);

    expect(await worker.execute(), isTrue);

    // 8 was never stored here: no push of it to look for.
    verify(() => push.dismissByContent(stored.title, stored.content)).called(1);
    verifyNever(() => push.dismissByContent('-', '-'));
  });

  test('a bulk delete longer than a page is one page, and the next request starts after it', () async {
    // The backend does not split what changed at one instant: 80 deletes come together.
    final at = DateTime.utc(2026, 2, 1);
    final deletes = [for (var i = 0; i < 80; i++) _deleted(100 + i, at)];
    when(() => remote.getUpdates(since: anchor, limit: 50)).thenAnswer((_) async => deletes);
    when(() => remote.getUpdates(since: at, limit: 50)).thenAnswer((_) async => []);

    expect(await worker.execute(), isTrue);

    verify(() => local.upsertNotifications(deletes)).called(1);
    verify(() => remote.getUpdates(since: at, limit: 50)).called(1);
  });
}
