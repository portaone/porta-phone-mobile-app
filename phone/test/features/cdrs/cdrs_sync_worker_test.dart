import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/cdrs/cdrs.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

class MockCdrsLocalRepository extends Mock implements CdrsLocalRepository {}

class MockCdrsRemoteRepository extends Mock implements CdrsRemoteRepository {}

class MockCdrsSyncWorker extends Mock implements CdrsSyncWorker {}

class MockPollingTaskHandle extends Mock implements PollingTaskHandle {}

class MockPollingService extends Mock implements PollingService {}

class FakePollingRegistration extends Fake implements PollingRegistration {}

CdrRecord _record(String id, int minute) => CdrRecord(
  callId: id,
  direction: CallDirection.incoming,
  status: CdrStatus.accepted,
  callee: '1000',
  calleeNumber: '1000',
  caller: '2000',
  callerNumber: '2000',
  connectTime: DateTime.utc(2026, 1, 1, 0, minute),
  disconnectTime: DateTime.utc(2026, 1, 1, 0, minute, 10),
  disconnectReason: 'normal',
  duration: const Duration(seconds: 10),
);

CdrHistoryPage _page(List<CdrRecord> records, {int? itemsTotal}) =>
    CdrHistoryPage(records: records, itemsTotal: itemsTotal);

/// Fixed slices, so a test says which slice it is answering rather than
/// depending on how the deployment is configured.
const _windows = HistoryWindows(
  firstWidth: Duration(days: 7),
  maxWidth: Duration(days: 90),
  horizon: Duration(days: 365),
);

void main() {
  setUpAll(() => registerFallbackValue(FakePollingRegistration()));

  late MockCdrsLocalRepository localRepository;
  late MockCdrsRemoteRepository remoteRepository;
  late CdrsSyncWorker worker;

  setUp(() {
    localRepository = MockCdrsLocalRepository();
    remoteRepository = MockCdrsRemoteRepository();
    worker = CdrsSyncWorker(localRepository, remoteRepository, pageSize: 2, historyWindows: _windows);

    when(() => localRepository.upsertCdrs(any())).thenAnswer((_) async {});
    when(() => localRepository.getLastSyncTime()).thenAnswer((_) async => null);
    when(() => localRepository.markSyncCompleted(any())).thenAnswer((_) async {});
    when(() => localRepository.getHistoryWalkedTo()).thenAnswer((_) async => null);
    when(() => localRepository.markHistoryWalkedTo(any())).thenAnswer((_) async {});
    when(() => localRepository.notifyInitialSyncFailed()).thenAnswer((_) async {});
  });

  tearDown(() => worker.dispose());

  group('CdrsSyncWorker.refresh', () {
    test('stores the newest page it finds and marks the completed cycle', () async {
      final newer = _record('newer', 2);
      final older = _record('older', 1);
      final completedAt = DateTime.utc(2026, 1, 2);
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => null);
      _answerWindows(remoteRepository, [
        [newer, older],
      ]);

      await withClock(Clock.fixed(completedAt), worker.refresh);

      expect(_windowsAsked(remoteRepository), 1, reason: 'the first slice held records, so the walk stops there');
      verify(() => localRepository.upsertCdrs([older, newer])).called(1);
      verify(() => localRepository.markSyncCompleted(completedAt)).called(1);
      verifyNever(() => localRepository.notifyInitialSyncFailed());
    });

    test('walks past the days that hold nothing instead of filling nothing', () async {
      // The reason the cycle walks at all: a request that names no range is
      // answered about recent history alone, so a first launch after a quiet
      // week used to store an empty list and call it a day.
      final found = _record('older-than-a-week', 1);
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => null);
      _answerWindows(remoteRepository, [
        [],
        [],
        [found],
      ]);

      await worker.refresh();

      expect(_windowsAsked(remoteRepository), 3);
      verify(() => localRepository.upsertCdrs([found])).called(1);
    });

    test('marks a successful initial cycle even when the whole horizon is empty', () async {
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => null);
      _answerWindows(remoteRepository, const []);

      await worker.refresh();

      expect(_windowsAsked(remoteRepository), 7, reason: 'a year of silence is seven slices');
      verifyNever(() => localRepository.upsertCdrs(any()));
      verify(() => localRepository.markSyncCompleted(any())).called(1);
    });

    test('records every slice it walked, so the lists do not walk them again', () async {
      // The cycle and the lists share one archive and one cache; days this
      // walked are days nobody needs to ask about a second time.
      final found = _record('older-than-two-weeks', 1);
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => null);
      _answerWindows(remoteRepository, [
        [],
        [],
        [found],
      ]);

      await worker.refresh();

      final marked = verify(() => localRepository.markHistoryWalkedTo(captureAny())).captured.cast<DateTime>();
      expect(marked, hasLength(3), reason: 'two empty slices and the page that ended the walk');
      expect(marked.last, found.connectTime, reason: 'the rest of that slice is still for a list to walk');
      expect(marked[1].isBefore(marked[0]), isTrue, reason: 'each empty slice moved it further back');
    });

    test('an account that stays empty is asked about the most recent slice only', () async {
      // Nothing to be incremental from, but no reason to re-walk the archive
      // every five minutes either.
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => null);
      when(() => localRepository.getLastSyncTime()).thenAnswer((_) async => DateTime.utc(2026, 1, 1));
      _answerWindows(remoteRepository, const []);

      await worker.refresh();

      expect(_windowsAsked(remoteRepository), 1);
    });

    test('with the walk switched off the first cycle asks for no range at all', () async {
      final worker = CdrsSyncWorker(
        localRepository,
        remoteRepository,
        pageSize: 2,
        historyWindows: const HistoryWindows(
          firstWidth: Duration(days: 7),
          maxWidth: Duration(days: 90),
          horizon: Duration.zero,
        ),
      );
      addTearDown(worker.dispose);
      final record = _record('1', 1);
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => null);
      when(() => remoteRepository.getHistory(page: 1, limit: 2)).thenAnswer((_) async => _page([record]));

      await worker.refresh();

      verify(() => remoteRepository.getHistory(page: 1, limit: 2)).called(1);
      verify(() => localRepository.upsertCdrs([record])).called(1);
    });

    test('drains incremental pages in order and stops after a partial page', () async {
      final lastUpdate = DateTime.utc(2026, 1, 1);
      final page1 = [_record('4', 4), _record('3', 3)];
      final page2 = [_record('2', 2)];
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => lastUpdate);
      when(
        () => remoteRepository.getHistory(
          timeFrom: lastUpdate,
          page: any(named: 'page'),
          limit: 2,
        ),
      ).thenAnswer((invocation) async {
        return switch (invocation.namedArguments[#page]) {
          1 => _page(page1),
          2 => _page(page2),
          _ => throw StateError('Unexpected page'),
        };
      });

      await worker.refresh();

      verifyInOrder([
        () => remoteRepository.getHistory(timeFrom: lastUpdate, page: 1, limit: 2),
        () => remoteRepository.getHistory(timeFrom: lastUpdate, page: 2, limit: 2),
        () => localRepository.upsertCdrs([...page2.reversed, ...page1.reversed]),
      ]);
      verifyNever(() => remoteRepository.getHistory(timeFrom: lastUpdate, page: 3, limit: 2));
    });

    test('requests a terminating empty page after an exact number of full pages', () async {
      final lastUpdate = DateTime.utc(2026, 1, 1);
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => lastUpdate);
      when(
        () => remoteRepository.getHistory(
          timeFrom: lastUpdate,
          page: any(named: 'page'),
          limit: 2,
        ),
      ).thenAnswer((invocation) async {
        return switch (invocation.namedArguments[#page]) {
          1 => _page([_record('4', 4), _record('3', 3)]),
          2 => _page([_record('2', 2), _record('1', 1)]),
          3 => const CdrHistoryPage.empty(),
          _ => throw StateError('Unexpected page'),
        };
      });

      await worker.refresh();

      verifyInOrder([
        () => remoteRepository.getHistory(timeFrom: lastUpdate, page: 1, limit: 2),
        () => remoteRepository.getHistory(timeFrom: lastUpdate, page: 2, limit: 2),
        () => remoteRepository.getHistory(timeFrom: lastUpdate, page: 3, limit: 2),
      ]);
    });

    test('does not advance local history when a later incremental page fails', () async {
      final lastUpdate = DateTime.utc(2026, 1, 1);
      final error = Exception('page 2 failed');
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => lastUpdate);
      when(
        () => remoteRepository.getHistory(
          timeFrom: lastUpdate,
          page: any(named: 'page'),
          limit: 2,
        ),
      ).thenAnswer((invocation) async {
        if (invocation.namedArguments[#page] == 1) {
          return _page([_record('2', 2), _record('1', 1)]);
        }
        throw error;
      });

      await expectLater(worker.refresh(), throwsA(same(error)));

      verifyNever(() => localRepository.upsertCdrs(any()));
      verifyNever(() => localRepository.markSyncCompleted(any()));
      verify(() => localRepository.notifyInitialSyncFailed()).called(1);
    });

    test('uses the persisted marker as source of truth after a cache wipe', () async {
      final lastUpdate = DateTime.utc(2026, 1, 1);
      var markerRead = 0;
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => lastUpdate);
      when(() => remoteRepository.getHistory(timeFrom: lastUpdate, page: 1, limit: 2))
          .thenAnswer((_) async => const CdrHistoryPage.empty());
      when(() => localRepository.getLastSyncTime()).thenAnswer((_) async {
        markerRead++;
        return markerRead == 1 ? DateTime.utc(2026, 1, 1) : null;
      });

      await worker.refresh();
      verifyNever(() => localRepository.markSyncCompleted(any()));

      await worker.refresh();
      verify(() => localRepository.markSyncCompleted(any())).called(1);
    });

    test('reports and rethrows a remote failure without marking success', () async {
      final error = Exception('offline');
      final stackTrace = StackTrace.current;
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => null);
      when(
        () => remoteRepository.getHistory(
          timeFrom: any(named: 'timeFrom'),
          timeTo: any(named: 'timeTo'),
          page: 1,
          limit: 2,
        ),
      ).thenAnswer((_) => Future<CdrHistoryPage>.error(error, stackTrace));

      Object? caughtError;
      StackTrace? caughtStackTrace;
      try {
        await worker.refresh();
      } catch (error, stackTrace) {
        caughtError = error;
        caughtStackTrace = stackTrace;
      }

      expect(caughtError, same(error));
      expect(caughtStackTrace, same(stackTrace));
      verify(() => localRepository.notifyInitialSyncFailed()).called(1);
      verifyNever(() => localRepository.markSyncCompleted(any()));
    });

    test('reports and rethrows a local persistence failure', () async {
      final error = Exception('database unavailable');
      when(() => localRepository.getLastUpdate()).thenAnswer((_) async => null);
      _answerWindows(remoteRepository, [
        [_record('1', 1)],
      ]);
      when(() => localRepository.upsertCdrs(any())).thenThrow(error);

      await expectLater(worker.refresh(), throwsA(same(error)));

      verify(() => localRepository.notifyInitialSyncFailed()).called(1);
      verifyNever(() => localRepository.markSyncCompleted(any()));
    });

    test('a notification failure never masks the original cycle failure', () async {
      final syncError = Exception('sync failed');
      when(() => localRepository.getLastUpdate()).thenThrow(syncError);
      when(() => localRepository.notifyInitialSyncFailed()).thenThrow(Exception('notification failed'));

      await expectLater(worker.refresh(), throwsA(same(syncError)));
    });

    test('rejects refresh after disposal', () async {
      await worker.dispose();

      await expectLater(worker.refresh(), throwsA(isA<StateError>()));
      expect(worker.isActive, isFalse);
      verifyNever(() => localRepository.getLastUpdate());
    });
  });

  group('CdrsSync', () {
    test('owns one registration and forwards call-ended refresh requests', () async {
      final syncWorker = MockCdrsSyncWorker();
      final pollingService = MockPollingService();
      final task = MockPollingTaskHandle();
      when(() => syncWorker.dispose()).thenAnswer((_) async {});
      when(() => pollingService.register(any())).thenReturn(task);
      when(() => task.isRegistered).thenReturn(true);
      when(() => task.state).thenReturn(const PollingTaskState(phase: PollingTaskPhase.idle));
      when(() => task.states).thenAnswer((_) => const Stream<PollingTaskState>.empty());
      when(() => task.runNow()).thenAnswer((_) async {});
      final sync = CdrsSync(worker: syncWorker, pollingService: pollingService, interval: const Duration(seconds: 10));

      final registration = verify(() => pollingService.register(captureAny())).captured.single as PollingRegistration;
      expect(registration.listener, same(syncWorker));
      expect(registration.interval, const Duration(seconds: 10));
      expect(sync.state.phase, PollingTaskPhase.idle);
      expect(sync.states, same(task.states));

      await sync.runNow();
      verify(() => task.runNow()).called(1);

      sync.requestPostCallRefresh();
      verify(() => task.invalidate(after: const Duration(seconds: 1))).called(1);

      await sync.dispose();
      await sync.dispose();

      verify(() => task.unregister()).called(1);
      verify(() => syncWorker.dispose()).called(1);
    });

    test('a configured post-call delay is used instead of the default', () async {
      final syncWorker = MockCdrsSyncWorker();
      final pollingService = MockPollingService();
      final task = MockPollingTaskHandle();
      when(() => syncWorker.dispose()).thenAnswer((_) async {});
      when(() => pollingService.register(any())).thenReturn(task);
      when(() => task.isRegistered).thenReturn(true);
      final sync = CdrsSync(
        worker: syncWorker,
        pollingService: pollingService,
        interval: const Duration(seconds: 10),
        postCallRefreshDelay: const Duration(seconds: 3),
      );
      addTearDown(sync.dispose);

      sync.requestPostCallRefresh();

      verify(() => task.invalidate(after: const Duration(seconds: 3))).called(1);
    });

    test('ignores a late call-ended refresh after disposal', () async {
      final syncWorker = MockCdrsSyncWorker();
      final pollingService = MockPollingService();
      final task = MockPollingTaskHandle();
      when(() => syncWorker.dispose()).thenAnswer((_) async {});
      when(() => pollingService.register(any())).thenReturn(task);
      final sync = CdrsSync(worker: syncWorker, pollingService: pollingService, interval: const Duration(seconds: 10));

      await sync.dispose();

      expect(sync.requestPostCallRefresh, returnsNormally);
      verifyNever(() => task.invalidate(after: const Duration(seconds: 1)));
    });

    test('ignores a refresh request after the polling service unregisters the task', () async {
      final syncWorker = MockCdrsSyncWorker();
      final pollingService = MockPollingService();
      final task = MockPollingTaskHandle();
      when(() => syncWorker.dispose()).thenAnswer((_) async {});
      when(() => pollingService.register(any())).thenReturn(task);
      when(() => task.isRegistered).thenReturn(false);
      final sync = CdrsSync(worker: syncWorker, pollingService: pollingService, interval: const Duration(seconds: 10));

      expect(sync.requestPostCallRefresh, returnsNormally);
      verifyNever(() => task.invalidate(after: const Duration(seconds: 1)));
      await sync.dispose();
    });
  });
}

/// Answers the walk slice by slice: [slices] in order, then empty.
void _answerWindows(MockCdrsRemoteRepository remote, List<List<CdrRecord>> slices) {
  var asked = 0;
  when(
    () => remote.getHistory(
      timeFrom: any(named: 'timeFrom'),
      timeTo: any(named: 'timeTo'),
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer((_) async {
    final records = asked < slices.length ? slices[asked] : const <CdrRecord>[];
    asked++;
    return _page(records, itemsTotal: records.length);
  });
}

int _windowsAsked(MockCdrsRemoteRepository remote) => verify(
  () => remote.getHistory(
    timeFrom: any(named: 'timeFrom'),
    timeTo: any(named: 'timeTo'),
    page: any(named: 'page'),
    limit: any(named: 'limit'),
  ),
).callCount;
