import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/system_notifications/system_notifications.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import 'idle_outbox.dart';

class _Local extends Mock implements SystemNotificationsLocalRepository {}

class _Remote extends Mock implements SystemNotificationsRemoteRepository {}

// Deleting from the screen goes the way a seen receipt does: written to the
// outbox, which sends it. The screen itself never asks the backend, so a
// delete made offline is not lost and is not refused.
void main() {
  late _Local local;
  late _Remote remote;
  late SystemNotificationsScreenCubit cubit;

  final notification = SystemNotification(
    id: 7,
    title: 'Title',
    content: 'Content',
    type: SystemNotificationType.system,
    seen: false,
    createdAt: DateTime.utc(2026, 10, 1),
    updatedAt: DateTime.utc(2026, 10, 1),
  );

  setUpAll(() => registerFallbackValue(<int>[]));

  setUp(() {
    local = _Local();
    remote = _Remote();
    when(() => local.queueDeletes(any())).thenAnswer((_) async {});
    // Not started: init() opens the screen's own subscription, which deleting
    // does not need, and close() before init() throws on that late field.
    cubit = SystemNotificationsScreenCubit(local, remote, outbox: idleOutbox());
  });

  test('one notification is queued for delete and leaves at once', () async {
    expect(await cubit.deleteNotification(notification), isTrue);

    verify(() => local.queueDeletes([7])).called(1);
    verifyZeroInteractions(remote);
  });

  test('several are queued in one go', () async {
    await cubit.deleteNotifications([12, 15]);

    verify(() => local.queueDeletes([12, 15])).called(1);
    verifyZeroInteractions(remote);
  });

  test('nothing to delete queues nothing', () async {
    await cubit.deleteNotifications([]);

    verifyNever(() => local.queueDeletes(any()));
  });
}
