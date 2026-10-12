import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/system_notifications/system_notifications.dart';
import 'package:webtrit_phone/services/services.dart';

class _OutboxWorker extends Mock implements SystemNotificationsOutboxWorker {}

class _PollingService extends Mock implements PollingService {}

class _PollingTask extends Mock implements PollingTaskHandle {}

class _PollingRegistration extends Fake implements PollingRegistration {}

/// A real outbox over a worker that sends nothing and a scheduler that never
/// runs it, for tests of the screen: a requested flush is accepted and goes
/// nowhere. The outbox is final, so it is built rather than mocked.
SystemNotificationsOutbox idleOutbox() {
  registerFallbackValue(_PollingRegistration());
  final worker = _OutboxWorker();
  final pollingService = _PollingService();
  final task = _PollingTask();
  when(() => worker.dispose()).thenAnswer((_) async {});
  when(() => pollingService.register(any())).thenReturn(task);
  when(() => task.isRegistered).thenReturn(true);
  when(() => task.state).thenReturn(const PollingTaskState(phase: PollingTaskPhase.idle));

  final outbox = SystemNotificationsOutbox(
    worker: worker,
    pollingService: pollingService,
    interval: const Duration(seconds: 300),
  );
  addTearDown(outbox.dispose);
  return outbox;
}
