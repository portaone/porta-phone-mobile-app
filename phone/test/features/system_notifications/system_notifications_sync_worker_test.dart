import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/system_notifications/system_notifications.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

class MockSystemNotificationsLocalRepository extends Mock implements SystemNotificationsLocalRepository {}

class MockSystemNotificationsRemoteRepository extends Mock implements SystemNotificationsRemoteRepository {}

class MockSystemNotificationsSyncWorker extends Mock implements SystemNotificationsSyncWorker {}

class MockPollingTaskHandle extends Mock implements PollingTaskHandle {}

class MockPollingService extends Mock implements PollingService {}

class FakePollingRegistration extends Fake implements PollingRegistration {}

SystemNotification _notification(int id, int minute) => SystemNotification(
  id: id,
  title: 'title $id',
  content: 'content $id',
  type: SystemNotificationType.system,
  seen: false,
  createdAt: DateTime.utc(2026, 1, 1, 0, minute),
  updatedAt: DateTime.utc(2026, 1, 1, 0, minute),
);

void main() {
  setUpAll(() => registerFallbackValue(FakePollingRegistration()));

  late MockSystemNotificationsLocalRepository localRepository;
  late MockSystemNotificationsRemoteRepository remoteRepository;
  late SystemNotificationsSyncWorker worker;

  setUp(() {
    localRepository = MockSystemNotificationsLocalRepository();
    remoteRepository = MockSystemNotificationsRemoteRepository();
    when(
      () => localRepository.upsertNotifications(
        any(),
        silent: any(named: 'silent'),
        initialData: any(named: 'initialData'),
      ),
    ).thenAnswer((_) async {});
    worker = SystemNotificationsSyncWorker(localRepository, remoteRepository, pageSize: 2);
  });

  tearDown(() => worker.dispose());

  group('SystemNotificationsSyncWorker.refresh', () {
    test('stores the initial history oldest first and marks it as initial data', () async {
      final newer = _notification(2, 2);
      final older = _notification(1, 1);
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => null);
      when(() => remoteRepository.getHistory(limit: 2)).thenAnswer((_) async => [newer, older]);

      await worker.refresh();

      verify(() => remoteRepository.getHistory(limit: 2)).called(1);
      verify(() => localRepository.upsertNotifications([older, newer], initialData: true)).called(1);
      // One cycle is one branch: a first load must not also drain updates from
      // an anchor it has only just written.
      verifyNever(
        () => remoteRepository.getUpdates(
          since: any(named: 'since'),
          limit: any(named: 'limit'),
        ),
      );
    });

    test('an empty successful sync makes later history eligible for push', () async {
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => null);
      when(() => remoteRepository.getHistory(limit: 2)).thenAnswer((_) async => []);

      await worker.refresh();
      await worker.refresh();
      final notification = _notification(1, 1);
      when(() => remoteRepository.getHistory(limit: 2)).thenAnswer((_) async => [notification]);
      await worker.refresh();

      verifyInOrder([
        () => localRepository.upsertNotifications([], initialData: true),
        () => localRepository.upsertNotifications([], initialData: false),
        () => localRepository.upsertNotifications([notification], initialData: false),
      ]);
    });

    for (final failureSource in ['history', 'persistence']) {
      test('an initial $failureSource failure keeps the retry silent', () async {
        final notification = _notification(1, 1);
        when(() => localRepository.getLastUpdate()).thenAnswer((_) async => null);
        when(() => remoteRepository.getHistory(limit: 2)).thenAnswer((_) async => [notification]);
        if (failureSource == 'history') {
          when(() => remoteRepository.getHistory(limit: 2)).thenAnswer((_) async => throw StateError('fetch failed'));
        } else {
          when(() => localRepository.upsertNotifications(any(), initialData: any(named: 'initialData')))
              .thenAnswer((_) async => throw StateError('write failed'));
        }
        await expectLater(worker.refresh(), throwsStateError);
        clearInteractions(localRepository);
        when(() => remoteRepository.getHistory(limit: 2)).thenAnswer((_) async => [notification]);
        when(() => localRepository.upsertNotifications(any(), initialData: any(named: 'initialData')))
            .thenAnswer((_) async {});

        await worker.refresh();

        verify(() => localRepository.upsertNotifications([notification], initialData: true)).called(1);
        verifyNever(() => localRepository.upsertNotifications(any(), initialData: false));
      });
    }

    test('fetches updates from the stored anchor and stops after a partial page', () async {
      final lastUpdate = DateTime.utc(2026, 1, 1);
      final update = _notification(1, 1);
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => lastUpdate);
      when(() => remoteRepository.getUpdates(since: lastUpdate, limit: 2)).thenAnswer((_) async => [update]);

      await worker.refresh();

      verify(() => remoteRepository.getUpdates(since: lastUpdate, limit: 2)).called(1);
      // Updates are stored as received, and are news rather than history.
      verify(() => localRepository.upsertNotifications([update])).called(1);
      verifyNever(() => remoteRepository.getHistory(limit: any(named: 'limit')));
    });

    test('advances the anchor page by page until a page is not full', () async {
      final lastUpdate = DateTime.utc(2026, 1, 1);
      final page1 = [_notification(1, 1), _notification(2, 2)];
      final page2 = [_notification(3, 3)];
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => lastUpdate);
      when(() => remoteRepository.getUpdates(since: any(named: 'since'), limit: 2)).thenAnswer((invocation) async {
        return switch (invocation.namedArguments[#since]) {
          final DateTime since when since == lastUpdate => page1,
          // The second page starts at the newest record of the first one.
          final DateTime since when since == page1.last.updatedAt => page2,
          final other => throw StateError('Unexpected since: $other'),
        };
      });

      await worker.refresh();

      verifyInOrder([
        () => remoteRepository.getUpdates(since: lastUpdate, limit: 2),
        () => localRepository.upsertNotifications(page1),
        () => remoteRepository.getUpdates(since: page1.last.updatedAt, limit: 2),
        () => localRepository.upsertNotifications(page2),
      ]);
      verifyNoMoreInteractions(remoteRepository);
    });

    test('a delete that was read moves the anchor though the store does not hold it', () async {
      final stored = DateTime.utc(2026, 1, 1);
      final deletedAt = DateTime.utc(2026, 1, 2);
      final deleted = _notification(1, 1).copyWith(updatedAt: deletedAt, deletedAt: deletedAt);
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => stored);
      when(() => remoteRepository.getUpdates(since: stored, limit: 2)).thenAnswer((_) async => [deleted]);
      when(() => remoteRepository.getUpdates(since: deletedAt, limit: 2)).thenAnswer((_) async => []);

      await worker.refresh();
      await worker.refresh();

      // The store still answers with its own, older anchor; the delete is not fetched again.
      verify(() => remoteRepository.getUpdates(since: stored, limit: 2)).called(1);
      verify(() => remoteRepository.getUpdates(since: deletedAt, limit: 2)).called(1);
      verify(() => localRepository.upsertNotifications([deleted])).called(1);
    });

    test('a full page that cannot advance the anchor ends the cycle', () async {
      // The endpoint pages by timestamp. A full page of records sharing one
      // timestamp would otherwise be requested and stored forever, hanging the
      // cycle and hammering the backend; the stored page advances the local
      // anchor, so the next cycle resumes instead.
      final sameInstant = [_notification(1, 1), _notification(2, 1)];
      // Every record carries the anchor's own timestamp, so no page can move it.
      final lastUpdate = sameInstant.first.updatedAt;
      var requests = 0;
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => lastUpdate);
      when(() => remoteRepository.getUpdates(since: any(named: 'since'), limit: 2)).thenAnswer((_) async {
        // The stub refuses to feed a loop that does not terminate. A timeout
        // around refresh() would not help: a spinning cycle starves the event
        // loop, so the timer never fires and the whole suite hangs instead of
        // failing.
        if (++requests > 1) fail('The cycle did not terminate on a non-advancing page.');
        return [...sameInstant];
      });

      await worker.refresh();

      expect(requests, 1);
      verify(() => remoteRepository.getUpdates(since: lastUpdate, limit: 2)).called(1);
      verify(() => localRepository.upsertNotifications(sameInstant)).called(1);
      verifyNoMoreInteractions(remoteRepository);
    });

    for (final failureSource in ['history', 'updates', 'persistence']) {
      test('a $failureSource failure keeps its error and stack trace', () async {
        final error = Exception('$failureSource failed');
        final stackTrace = StackTrace.fromString('$failureSource failure origin');
        final lastUpdate = failureSource == 'history' ? null : DateTime.utc(2026, 1, 1);
        when(() => localRepository.getLastUpdate()).thenAnswer((_) async => lastUpdate);
        when(() => remoteRepository.getHistory(limit: 2)).thenAnswer((_) async => [_notification(1, 1)]);
        when(() => remoteRepository.getUpdates(since: any(named: 'since'), limit: 2))
            .thenAnswer((_) async => [_notification(1, 1)]);
        switch (failureSource) {
          case 'history':
            when(() => remoteRepository.getHistory(limit: 2))
                .thenAnswer((_) => Future<List<SystemNotification>>.error(error, stackTrace));
          case 'updates':
            when(() => remoteRepository.getUpdates(since: any(named: 'since'), limit: 2))
                .thenAnswer((_) => Future<List<SystemNotification>>.error(error, stackTrace));
          case 'persistence':
            when(
              () => localRepository.upsertNotifications(
                any(),
                silent: any(named: 'silent'),
                initialData: any(named: 'initialData'),
              ),
            ).thenAnswer((_) => Future<void>.error(error, stackTrace));
        }

        await worker.refresh().then<void>(
          (_) => fail('A failed cycle must not complete normally.'),
          onError: (Object actualError, StackTrace actualStackTrace) {
            expect(actualError, same(error));
            expect(actualStackTrace, same(stackTrace));
          },
        );
      });
    }

    test('a disposed worker is inactive and rejects a refresh before fetching', () async {
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => null);

      expect(worker.isActive, isTrue);
      await worker.dispose();
      expect(worker.isActive, isFalse);

      await expectLater(worker.refresh(), throwsStateError);
      verifyNever(() => localRepository.getLastUpdate());
    });

    test('disposal while reading the anchor prevents a remote request', () async {
      final anchor = Completer<DateTime?>();
      when(() => localRepository.getLastUpdate()).thenAnswer((_) => anchor.future);
      final cycle = worker.refresh();
      final outcome = expectLater(cycle, throwsStateError);

      await worker.dispose();
      anchor.complete(null);
      await outcome;

      verifyNoMoreInteractions(remoteRepository);
    });

    for (final initialHistory in [true, false]) {
      test('disposal during ${initialHistory ? 'history' : 'updates'} fetch prevents persistence', () async {
        final response = Completer<List<SystemNotification>>();
        final started = Completer<void>();
        final anchor = DateTime.utc(2026, 1, 1);
        when(() => localRepository.getLastUpdate()).thenAnswer((_) async => initialHistory ? null : anchor);
        Future<List<SystemNotification>> fetch(Invocation _) {
          started.complete();
          return response.future;
        }

        if (initialHistory) {
          when(() => remoteRepository.getHistory(limit: 2)).thenAnswer(fetch);
        } else {
          when(() => remoteRepository.getUpdates(since: anchor, limit: 2)).thenAnswer(fetch);
        }
        final cycle = worker.refresh();
        final outcome = expectLater(cycle, throwsStateError);
        await started.future;

        await worker.dispose();
        response.complete([_notification(1, 1), _notification(2, 2)]);
        await outcome;

        verifyNever(
          () => localRepository.upsertNotifications(
            any(),
            silent: any(named: 'silent'),
            initialData: any(named: 'initialData'),
          ),
        );
        if (!initialHistory) {
          verify(() => remoteRepository.getUpdates(since: any(named: 'since'), limit: 2)).called(1);
        }
      });
    }

    test('disposal during a page write prevents fetching the next page', () async {
      final persisted = Completer<void>();
      final started = Completer<void>();
      final anchor = DateTime.utc(2026, 1, 1);
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => anchor);
      when(() => remoteRepository.getUpdates(since: any(named: 'since'), limit: 2))
          .thenAnswer((_) async => [_notification(1, 1), _notification(2, 2)]);
      when(() => localRepository.upsertNotifications(any())).thenAnswer((_) {
        started.complete();
        return persisted.future;
      });
      final cycle = worker.refresh();
      final outcome = expectLater(cycle, throwsStateError);
      await started.future;

      await worker.dispose();
      persisted.complete();
      await outcome;

      verify(() => remoteRepository.getUpdates(since: any(named: 'since'), limit: 2)).called(1);
    });

    test('disposal is idempotent', () async {
      await worker.dispose();
      await worker.dispose();

      expect(worker.isActive, isFalse);
    });
  });

  group('SystemNotificationsSync', () {
    test('owns one registration and releases it with the worker', () async {
      final syncWorker = MockSystemNotificationsSyncWorker();
      final pollingService = MockPollingService();
      final task = MockPollingTaskHandle();
      when(() => syncWorker.dispose()).thenAnswer((_) async {});
      when(() => pollingService.register(any())).thenReturn(task);
      when(() => task.isRegistered).thenReturn(true);
      when(() => task.state).thenReturn(const PollingTaskState(phase: PollingTaskPhase.idle));
      when(() => task.states).thenAnswer((_) => const Stream<PollingTaskState>.empty());
      when(() => task.runNow()).thenAnswer((_) async {});
      final sync = SystemNotificationsSync(
        worker: syncWorker,
        pollingService: pollingService,
        interval: const Duration(seconds: 10),
      );

      final registration = verify(() => pollingService.register(captureAny())).captured.single as PollingRegistration;
      expect(registration.listener, same(syncWorker));
      expect(registration.interval, const Duration(seconds: 10));
      expect(sync.state.phase, PollingTaskPhase.idle);

      await sync.runNow();
      verify(() => task.runNow()).called(1);

      await sync.dispose();
      await sync.dispose();

      verify(() => task.unregister()).called(1);
      verify(() => syncWorker.dispose()).called(1);
    });
  });
}
