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

class _Journal implements SystemNotificationsSyncJournal {
  _Journal([this.lastSyncedAt]);

  @override
  DateTime? lastSyncedAt;

  @override
  Future<void> markSynced(DateTime at) async => lastSyncedAt = at;
}

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

  // The backend reports a deleted notification for a limited time. A store not
  // brought up to date for longer may hold some deleted since, with nothing
  // left to read about them - so it is read afresh instead of updated.
  group('a store that may be stale', () {
    final now = DateTime.utc(2026, 10, 12, 12);
    final anchor = DateTime.utc(2026, 1, 1);
    const retention = Duration(days: 180);
    late _Journal journal;
    Duration? reported;

    SystemNotificationsSyncWorker build() => SystemNotificationsSyncWorker(
      localRepository,
      remoteRepository,
      pageSize: 2,
      journal: journal,
      deletedRetention: () => reported,
      now: () => now,
    );

    setUp(() {
      reported = retention;
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => anchor);
      when(() => localRepository.getNotificationIds()).thenAnswer((_) async => []);
      when(() => localRepository.deleteNotifications(any())).thenAnswer((_) async {});
      when(() => localRepository.getOutboxNotifications(states: any(named: 'states'))).thenAnswer((_) async => []);
      when(() => remoteRepository.getUpdates(since: any(named: 'since'), limit: 2)).thenAnswer((_) async => []);
      when(() => remoteRepository.getHistory(limit: 2)).thenAnswer((_) async => []);
    });

    test('synced within the time deletes are reported for: updates, as ever', () async {
      journal = _Journal(now.subtract(const Duration(days: 30)));
      final worker = build();
      addTearDown(worker.dispose);

      await worker.refresh();

      verify(() => remoteRepository.getUpdates(since: anchor, limit: 2)).called(1);
      verifyNever(() => remoteRepository.getHistory(limit: any(named: 'limit')));
      expect(journal.lastSyncedAt, now);
    });

    test('away for longer: the first page is read again and the rest is dropped, quietly', () async {
      journal = _Journal(now.subtract(const Duration(days: 181)));
      final still = _notification(5, 5);
      final fresh = _notification(6, 6);
      // 1 was deleted while the device was away; 2 has a seen receipt yet to send.
      when(() => localRepository.getNotificationIds()).thenAnswer((_) async => [1, 2, 5]);
      when(() => localRepository.getOutboxNotifications(states: any(named: 'states'))).thenAnswer(
        (_) async => [const SystemNotificationOutboxEntry(notificationId: 2, actionType: SnOutboxActionType.seen)],
      );
      when(() => remoteRepository.getHistory(limit: 2)).thenAnswer((_) async => [fresh, still]);
      final worker = build();
      addTearDown(worker.dispose);

      await worker.refresh();

      verifyInOrder([
        () => remoteRepository.getHistory(limit: 2),
        // Not 5, which the page still lists, nor 2, which the outbox is not done with.
        () => localRepository.deleteNotifications([1]),
        () => localRepository.upsertNotifications([still, fresh], initialData: true),
      ]);
      verifyNever(
        () => remoteRepository.getUpdates(
          since: any(named: 'since'),
          limit: any(named: 'limit'),
        ),
      );
      expect(journal.lastSyncedAt, now);
    });

    test('the cycle after a reload reads updates again: it happens once, not every cycle', () async {
      journal = _Journal(now.subtract(const Duration(days: 400)));
      final worker = build();
      addTearDown(worker.dispose);

      await worker.refresh();
      await worker.refresh();

      verify(() => remoteRepository.getHistory(limit: 2)).called(1);
      verify(() => remoteRepository.getUpdates(since: anchor, limit: 2)).called(1);
    });

    test('a backend that reports deletes for a day does not make every cycle a reload', () async {
      // The allowance for clocks that disagree is a day - which here is all there is.
      reported = const Duration(days: 1);
      journal = _Journal(now.subtract(const Duration(seconds: 10)));
      final worker = build();
      addTearDown(worker.dispose);

      await worker.refresh();

      verify(() => remoteRepository.getUpdates(since: anchor, limit: 2)).called(1);
      verifyNever(() => remoteRepository.getHistory(limit: any(named: 'limit')));
    });

    test('the allowance for clocks is a day off half a year, and a tenth off a short time', () async {
      Future<bool> reloads(Duration retention, Duration away) async {
        reported = retention;
        journal = _Journal(now.subtract(away));
        var historyReads = 0;
        when(() => remoteRepository.getHistory(limit: 2)).thenAnswer((_) async {
          historyReads++;
          return [];
        });
        final worker = build();
        await worker.refresh();
        await worker.dispose();
        return historyReads == 1;
      }

      expect(await reloads(retention, const Duration(days: 178)), isFalse);
      expect(await reloads(retention, const Duration(days: 179, hours: 1)), isTrue);
      // Ten days: nine and over is stale, under nine is not.
      expect(await reloads(const Duration(days: 10), const Duration(days: 8, hours: 23)), isFalse);
      expect(await reloads(const Duration(days: 10), const Duration(days: 9, hours: 1)), isTrue);
    });

    test('a record from the future counts as none, and is replaced by the present', () async {
      // Written while the phone's clock ran a year ahead; the clock has been put right since.
      journal = _Journal(now.add(const Duration(days: 365)));
      final worker = build();
      addTearDown(worker.dispose);

      await worker.refresh();
      await worker.refresh();

      verify(() => remoteRepository.getHistory(limit: 2)).called(1);
      expect(journal.lastSyncedAt, now);
    });

    test('a record a moment ahead is a clock that disagrees, not one from the future', () async {
      journal = _Journal(now.add(const Duration(minutes: 5)));
      final worker = build();
      addTearDown(worker.dispose);

      await worker.refresh();

      verifyNever(() => remoteRepository.getHistory(limit: any(named: 'limit')));
    });

    test('deletes reported without limit: no absence is too long', () async {
      // Zero is the backend set up to remove nothing by age - every delete is still there to read.
      reported = Duration.zero;
      journal = _Journal(now.subtract(const Duration(days: 3000)));
      final worker = build();
      addTearDown(worker.dispose);

      await worker.refresh();

      verify(() => remoteRepository.getUpdates(since: anchor, limit: 2)).called(1);
      verifyNever(() => remoteRepository.getHistory(limit: any(named: 'limit')));
      expect(journal.lastSyncedAt, now);
    });

    test('deletes reported without limit: a store with no record is still read afresh, once', () async {
      // What was deleted elsewhere before the app could hear of deletes is in it all the same.
      reported = Duration.zero;
      journal = _Journal();
      final worker = build();
      addTearDown(worker.dispose);

      await worker.refresh();
      await worker.refresh();

      verify(() => remoteRepository.getHistory(limit: 2)).called(1);
      verify(() => remoteRepository.getUpdates(since: anchor, limit: 2)).called(1);
    });

    test('no record of a sync at all counts as stale, once', () async {
      // A store filled before the app kept the record, or against a backend that
      // could not report deletes: what was deleted elsewhere until now is still in it.
      journal = _Journal();
      final worker = build();
      addTearDown(worker.dispose);

      await worker.refresh();

      verify(() => remoteRepository.getHistory(limit: 2)).called(1);
      expect(journal.lastSyncedAt, now);
    });

    test('a backend that reports no deletes is never a reason to reload, and leaves no record', () async {
      reported = null;
      journal = _Journal();
      final worker = build();
      addTearDown(worker.dispose);

      await worker.refresh();

      verify(() => remoteRepository.getUpdates(since: anchor, limit: 2)).called(1);
      verifyNever(() => remoteRepository.getHistory(limit: any(named: 'limit')));
      // So that the first cycle after it is upgraded finds none, and reloads then.
      expect(journal.lastSyncedAt, isNull);
    });

    test('a reload that cannot read the history leaves the store and the record as they were', () async {
      final before = now.subtract(const Duration(days: 181));
      journal = _Journal(before);
      when(() => localRepository.getNotificationIds()).thenAnswer((_) async => [1]);
      when(() => remoteRepository.getHistory(limit: 2)).thenThrow(Exception('offline'));
      final worker = build();
      addTearDown(worker.dispose);

      await expectLater(worker.refresh(), throwsException);

      verifyNever(() => localRepository.deleteNotifications(any()));
      expect(journal.lastSyncedAt, before);
    });

    test('an empty store is a first load whatever the record says', () async {
      journal = _Journal(now.subtract(const Duration(days: 400)));
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => null);
      final worker = build();
      addTearDown(worker.dispose);

      await worker.refresh();

      verify(() => remoteRepository.getHistory(limit: 2)).called(1);
      verifyNever(() => localRepository.deleteNotifications(any()));
      expect(journal.lastSyncedAt, now);
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
