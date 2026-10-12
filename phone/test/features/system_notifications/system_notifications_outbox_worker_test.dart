import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/system_notifications/system_notifications.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

import '../../mocks/fake_connectivity_service.dart';

class MockSystemNotificationsLocalRepository extends Mock implements SystemNotificationsLocalRepository {}

class MockSystemNotificationsRemoteRepository extends Mock implements SystemNotificationsRemoteRepository {}

class MockSystemNotificationsOutboxWorker extends Mock implements SystemNotificationsOutboxWorker {}

class MockPollingTaskHandle extends Mock implements PollingTaskHandle {}

class MockPollingService extends Mock implements PollingService {}

class FakePollingRegistration extends Fake implements PollingRegistration {}

class FakeOutboxEntry extends Fake implements SystemNotificationOutboxEntry {}

SystemNotificationOutboxEntry _entry(int id, {int attempts = 0}) =>
    SystemNotificationOutboxEntry(notificationId: id, actionType: SnOutboxActionType.seen, sendAttempts: attempts);

SystemNotification _notification(int id, {required bool seen}) => SystemNotification(
  id: id,
  title: 'title $id',
  content: 'content $id',
  type: SystemNotificationType.system,
  seen: seen,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakePollingRegistration());
    registerFallbackValue(FakeOutboxEntry());
    registerFallbackValue(SnOutboxActionType.seen);
    registerFallbackValue(<SnOutboxState>[]);
    registerFallbackValue(Duration.zero);
  });

  late MockSystemNotificationsLocalRepository localRepository;
  late MockSystemNotificationsRemoteRepository remoteRepository;
  late StreamController<SystemNotificationEvent> events;
  late SystemNotificationsOutboxWorker worker;

  setUp(() {
    localRepository = MockSystemNotificationsLocalRepository();
    remoteRepository = MockSystemNotificationsRemoteRepository();
    events = StreamController<SystemNotificationEvent>.broadcast();
    when(() => localRepository.eventBus).thenAnswer((_) => events.stream);
    when(() => localRepository.upsertOutboxNotification(any())).thenAnswer((_) async {});
    when(() => localRepository.deleteOutboxNotification(any(), any())).thenAnswer((_) async {});
    when(() => remoteRepository.markSystemNotificationAsSeen(any())).thenAnswer((_) async {});
    when(() => localRepository.getNotificationById(any()))
        .thenAnswer((invocation) async => _notification(invocation.positionalArguments.single as int, seen: false));
    worker = SystemNotificationsOutboxWorker(localRepository, remoteRepository);
  });

  tearDown(() async {
    await worker.dispose();
    await events.close();
  });

  void stubPending(
    List<SystemNotificationOutboxEntry> entries, {
    List<SystemNotificationOutboxEntry> deletes = const [],
  }) {
    when(
      () => localRepository.getOutboxNotifications(
        actionType: SnOutboxActionType.seen,
        states: any(named: 'states'),
      ),
    ).thenAnswer((_) async => entries);
    when(
      () => localRepository.getOutboxNotifications(
        actionType: SnOutboxActionType.delete,
        states: any(named: 'states'),
      ),
    ).thenAnswer((_) async => deletes);
  }

  group('SystemNotificationsOutboxWorker.refresh', () {
    test('asks only for the pending seen entries', () async {
      stubPending([]);

      await worker.refresh();

      verify(
        () => localRepository.getOutboxNotifications(
          actionType: SnOutboxActionType.seen,
          states: const [SnOutboxState.pending],
        ),
      ).called(1);
      verifyNever(() => remoteRepository.markSystemNotificationAsSeen(any()));
      verifyNever(() => localRepository.upsertOutboxNotification(any()));
    });

    test('sends every pending entry and marks it sent', () async {
      stubPending([_entry(1), _entry(2)]);

      await worker.refresh();

      verifyInOrder([
        () => remoteRepository.markSystemNotificationAsSeen(1),
        () => localRepository.upsertOutboxNotification(_entry(1).toSent()),
        () => remoteRepository.markSystemNotificationAsSeen(2),
        () => localRepository.upsertOutboxNotification(_entry(2).toSent()),
      ]);
    });

    test('sends every queued delete in one request, then drops the notifications', () async {
      final deletes = [
        SystemNotificationOutboxEntry(notificationId: 5, actionType: SnOutboxActionType.delete),
        SystemNotificationOutboxEntry(notificationId: 6, actionType: SnOutboxActionType.delete),
      ];
      stubPending([], deletes: deletes);
      when(() => remoteRepository.deleteNotifications([5, 6])).thenAnswer((_) async => [5]);
      when(() => localRepository.deleteNotifications(any())).thenAnswer((_) async {});

      await worker.refresh();

      // 6 is not in deleted_ids - the backend no longer had it - and goes too.
      verifyInOrder([
        () => remoteRepository.deleteNotifications([5, 6]),
        () => localRepository.deleteNotifications([5, 6]),
      ]);
    });

    test('a refused delete keeps the queue, and the receipts still go', () async {
      final error = Exception('delete refused');
      stubPending(
        [_entry(1)],
        deletes: [SystemNotificationOutboxEntry(notificationId: 5, actionType: SnOutboxActionType.delete)],
      );
      when(() => remoteRepository.deleteNotifications(any())).thenThrow(error);

      await expectLater(worker.refresh(), throwsA(same(error)));

      verifyNever(() => localRepository.deleteNotifications(any()));
      verify(() => remoteRepository.markSystemNotificationAsSeen(1)).called(1);
    });

    test('a notification deleted while its receipt was out is not written back', () async {
      // The delete took the outbox row with it; writing a sent row back would
      // point at a notification that is gone, which the foreign key refuses.
      stubPending([_entry(1), _entry(2)]);
      when(() => localRepository.getNotificationById(1)).thenAnswer((_) async => null);

      await worker.refresh();

      verify(() => remoteRepository.markSystemNotificationAsSeen(1)).called(1);
      verifyNever(() => localRepository.upsertOutboxNotification(_entry(1).toSent()));
      verify(() => localRepository.upsertOutboxNotification(_entry(2).toSent())).called(1);
    });

    test('a failing entry does not stop the rest of the queue', () async {
      final error = Exception('send failed');
      final stackTrace = StackTrace.fromString('send failure origin');
      stubPending([_entry(1), _entry(2)]);
      when(() => remoteRepository.markSystemNotificationAsSeen(1))
          .thenAnswer((_) => Future<void>.error(error, stackTrace));

      await worker.refresh().then<void>(
        (_) => fail('A cycle with a failed send must not complete normally.'),
        onError: (Object actualError, StackTrace actualStackTrace) {
          // The cycle still reports the real failure, so polling backs off.
          expect(actualError, same(error));
          expect(actualStackTrace, same(stackTrace));
        },
      );

      // The second entry was attempted and sent even though the first failed.
      verify(() => remoteRepository.markSystemNotificationAsSeen(2)).called(1);
      verify(() => localRepository.upsertOutboxNotification(_entry(2).toSent())).called(1);
      // The first one is left untouched, so it is still pending next cycle.
      verifyNever(() => localRepository.upsertOutboxNotification(_entry(1).toSent()));
      verifyNever(() => localRepository.upsertOutboxNotification(_entry(1).incAttempts()));
    });

    test('the first failure is the one reported', () async {
      final first = Exception('first');
      stubPending([_entry(1), _entry(2)]);
      when(() => remoteRepository.markSystemNotificationAsSeen(1)).thenAnswer((_) async => throw first);
      when(() => remoteRepository.markSystemNotificationAsSeen(2)).thenAnswer((_) async => throw Exception('second'));

      await expectLater(worker.refresh(), throwsA(same(first)));
    });

    test('no number of failed cycles abandons an entry', () async {
      // Anything may trigger a cycle - a tap on another notification asks for
      // an immediate flush - so an entry must not be spent by how often the
      // queue happens to be walked. A receipt is retried for as long as
      // polling retries, and the entry is left exactly as it was.
      stubPending([_entry(1, attempts: 4)]);
      when(() => remoteRepository.markSystemNotificationAsSeen(1)).thenAnswer((_) async => throw Exception('nope'));

      for (var cycle = 0; cycle < 20; cycle++) {
        await expectLater(worker.refresh(), throwsException);
      }

      verify(() => remoteRepository.markSystemNotificationAsSeen(1)).called(20);
      verifyNever(() => localRepository.upsertOutboxNotification(any()));
    });
  });

  group('SystemNotificationsOutboxWorker confirmations', () {
    test('a notification confirmed as seen drops its queued entry', () async {
      events.add(SystemNotificationUpdate(_notification(7, seen: true)));
      await pumpEventQueue();

      verify(() => localRepository.deleteOutboxNotification(7, SnOutboxActionType.seen)).called(1);
    });

    test('a notification that is still unseen keeps its queued entry', () async {
      events.add(SystemNotificationUpdate(_notification(7, seen: false)));
      await pumpEventQueue();

      verifyNever(() => localRepository.deleteOutboxNotification(any(), any()));
    });

    test('disposal stops the confirmations', () async {
      await worker.dispose();

      events.add(SystemNotificationUpdate(_notification(7, seen: true)));
      await pumpEventQueue();

      verifyNever(() => localRepository.deleteOutboxNotification(any(), any()));
    });
  });

  group('SystemNotificationsOutboxWorker disposal', () {
    test('a disposed worker is inactive and reads nothing', () async {
      stubPending([_entry(1)]);

      expect(worker.isActive, isTrue);
      await worker.dispose();
      expect(worker.isActive, isFalse);

      await expectLater(worker.refresh(), throwsStateError);
      verifyNever(
        () => localRepository.getOutboxNotifications(
          actionType: any(named: 'actionType'),
          states: any(named: 'states'),
        ),
      );
    });

    test('disposal during a send stops the queue without writing', () async {
      stubPending([_entry(1), _entry(2)]);
      when(() => remoteRepository.markSystemNotificationAsSeen(1)).thenAnswer((_) async => worker.dispose());

      await expectLater(worker.refresh(), throwsStateError);

      verifyNever(() => localRepository.upsertOutboxNotification(any()));
      verifyNever(() => remoteRepository.markSystemNotificationAsSeen(2));
    });

    test('disposal during a failed send stops before the next entry', () async {
      stubPending([_entry(1), _entry(2)]);
      when(() => remoteRepository.markSystemNotificationAsSeen(1)).thenAnswer((_) async {
        await worker.dispose();
        throw Exception('send failed');
      });

      await expectLater(worker.refresh(), throwsStateError);

      verifyNever(() => remoteRepository.markSystemNotificationAsSeen(2));
      verifyNever(() => localRepository.upsertOutboxNotification(any()));
    });

    test('disposal is idempotent', () async {
      await worker.dispose();
      await worker.dispose();

      expect(worker.isActive, isFalse);
    });
  });

  group('SystemNotificationsOutbox against a real polling service', () {
    test('a burst of requested flushes is one cycle, not one per tap', () {
      fakeAsync((async) {
        stubPending([_entry(1)]);
        final connectivity = FakeConnectivityService(initialConnected: true);
        final polling = PollingService(
          connectivityService: connectivity,
          options: const PollingOptions(jitterRatio: 0),
        );
        final outbox = SystemNotificationsOutbox(
          worker: worker,
          pollingService: polling,
          interval: const Duration(seconds: 300),
        );
        addTearDown(connectivity.dispose);
        async.flushMicrotasks();

        // The leading refresh on connect is the first send.
        verify(() => remoteRepository.markSystemNotificationAsSeen(1)).called(1);

        // Reading a screenful of notifications: a tap every 100 ms.
        for (var tap = 0; tap < 10; tap++) {
          outbox.requestFlush();
          async.elapse(const Duration(milliseconds: 100));
        }
        verifyNever(() => remoteRepository.markSystemNotificationAsSeen(any()));

        // The debounce closes once the taps stop, and the backend is asked
        // once for the whole burst rather than ten times.
        async.elapse(const Duration(seconds: 1));
        verify(() => remoteRepository.markSystemNotificationAsSeen(1)).called(1);

        polling.dispose();
      });
    });

    test('a flush is dropped while the backend is refusing the queue', () {
      fakeAsync((async) {
        stubPending([_entry(1)]);
        when(() => remoteRepository.markSystemNotificationAsSeen(1)).thenAnswer((_) async => throw Exception('down'));
        final connectivity = FakeConnectivityService(initialConnected: true);
        final polling = PollingService(
          connectivityService: connectivity,
          options: const PollingOptions(jitterRatio: 0),
        );
        final outbox = SystemNotificationsOutbox(
          worker: worker,
          pollingService: polling,
          interval: const Duration(seconds: 300),
        );
        addTearDown(connectivity.dispose);
        async.flushMicrotasks();

        // The leading refresh on connect is the one attempt that discovers the
        // backend is refusing; the task is now failing.
        verify(() => remoteRepository.markSystemNotificationAsSeen(1)).called(1);
        expect(outbox.state.phase, PollingTaskPhase.failed);

        // Every cycle attempts the whole queue, so a flush per tap would be a
        // request per tap at a backend that is already failing. The receipts
        // are on disk; the scheduled retry is what sends them.
        for (var tap = 0; tap < 20; tap++) {
          outbox.requestFlush();
          async.elapse(const Duration(seconds: 3));
        }
        verifyNever(() => remoteRepository.markSystemNotificationAsSeen(any()));

        polling.dispose();
      });
    });
  });

  group('SystemNotificationsScreenCubit.markAsSeen', () {
    test('queues the receipt first, then asks the outbox to send it', () async {
      final outboxWorker = MockSystemNotificationsOutboxWorker();
      final pollingService = MockPollingService();
      final task = MockPollingTaskHandle();
      when(() => outboxWorker.dispose()).thenAnswer((_) async {});
      when(() => pollingService.register(any())).thenReturn(task);
      when(() => task.isRegistered).thenReturn(true);
      when(() => task.state).thenReturn(const PollingTaskState(phase: PollingTaskPhase.succeeded));
      final outbox = SystemNotificationsOutbox(
        worker: outboxWorker,
        pollingService: pollingService,
        interval: const Duration(seconds: 300),
      );
      addTearDown(outbox.dispose);
      // Not started: init() opens the screen's own subscription, and the
      // receipt path does not need it. (close() before init() throws on the
      // late subscription field, so an unstarted cubit is left unclosed.)
      final cubit = SystemNotificationsScreenCubit(localRepository, remoteRepository, outbox: outbox);

      await cubit.markAsSeen(_notification(7, seen: false));

      // The order is the point: a send asked for before the row exists would
      // find an empty queue and the receipt would wait out the interval.
      verifyInOrder([
        () => localRepository.upsertOutboxNotification(_entry(7)),
        () => task.invalidate(after: any(named: 'after')),
      ]);
    });
  });

  group('SystemNotificationsOutbox', () {
    test('owns one registration, flushes on request and releases both', () async {
      final outboxWorker = MockSystemNotificationsOutboxWorker();
      final pollingService = MockPollingService();
      final task = MockPollingTaskHandle();
      when(() => outboxWorker.dispose()).thenAnswer((_) async {});
      when(() => pollingService.register(any())).thenReturn(task);
      when(() => task.isRegistered).thenReturn(true);
      when(() => task.state).thenReturn(const PollingTaskState(phase: PollingTaskPhase.succeeded));
      final outbox = SystemNotificationsOutbox(
        worker: outboxWorker,
        pollingService: pollingService,
        interval: const Duration(seconds: 300),
      );

      final registration = verify(() => pollingService.register(captureAny())).captured.single as PollingRegistration;
      expect(registration.listener, same(outboxWorker));
      expect(registration.interval, const Duration(seconds: 300));

      outbox.requestFlush();
      verify(() => task.invalidate(after: const Duration(seconds: 1))).called(1);

      await outbox.dispose();
      await outbox.dispose();

      verify(() => task.unregister()).called(1);
      verify(() => outboxWorker.dispose()).called(1);
    });

    for (final (phase, armed) in <(PollingTaskPhase, bool)>[
      (PollingTaskPhase.idle, true),
      (PollingTaskPhase.succeeded, true),
      // Offline is not a refusing backend: the service defers the cycle without
      // a request of its own, so arming it costs nothing and the queue leaves
      // on the leading refresh that reconnecting runs.
      (PollingTaskPhase.waitingForConnectivity, true),
      (PollingTaskPhase.failed, false),
    ]) {
      test('a flush is ${armed ? 'armed' : 'dropped'} while the task is ${phase.name}', () async {
        final outboxWorker = MockSystemNotificationsOutboxWorker();
        final pollingService = MockPollingService();
        final task = MockPollingTaskHandle();
        when(() => outboxWorker.dispose()).thenAnswer((_) async {});
        when(() => pollingService.register(any())).thenReturn(task);
        when(() => task.isRegistered).thenReturn(true);
        when(() => task.state).thenReturn(PollingTaskState(phase: phase));
        final outbox = SystemNotificationsOutbox(
          worker: outboxWorker,
          pollingService: pollingService,
          interval: const Duration(seconds: 300),
        );
        addTearDown(outbox.dispose);

        outbox.requestFlush();

        if (armed) {
          verify(() => task.invalidate(after: any(named: 'after'))).called(1);
        } else {
          verifyNever(() => task.invalidate(after: any(named: 'after')));
        }
      });
    }

    test('ignores a flush requested after disposal', () async {
      final outboxWorker = MockSystemNotificationsOutboxWorker();
      final pollingService = MockPollingService();
      final task = MockPollingTaskHandle();
      when(() => outboxWorker.dispose()).thenAnswer((_) async {});
      when(() => pollingService.register(any())).thenReturn(task);
      when(() => task.isRegistered).thenReturn(true);
      when(() => task.state).thenReturn(const PollingTaskState(phase: PollingTaskPhase.succeeded));
      final outbox = SystemNotificationsOutbox(
        worker: outboxWorker,
        pollingService: pollingService,
        interval: const Duration(seconds: 300),
      );

      await outbox.dispose();
      outbox.requestFlush();

      verifyNever(() => task.invalidate(after: any(named: 'after')));
    });
  });
}
