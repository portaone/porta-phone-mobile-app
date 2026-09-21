// The CDR lists against a backend that answers a rangeless request about recent
// history only - the shape every deployment of the PortaSwitch adapter has. The
// point of every case here is one sentence: a stretch of days without a call is
// not the end of the archive.
import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/cdrs/cdrs.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

/// What the backend looks back over when the request names no lower bound.
const _defaultWindow = Duration(hours: 24);
final _now = DateTime.utc(2026, 9, 21, 12);

/// Deliberately small, so a slice that holds more than one page is cheap to set
/// up and the walk's paging is exercised rather than assumed.
const _pageSize = 5;

final _windows = HistoryWindows(
  firstWidth: const Duration(days: 7),
  maxWidth: const Duration(days: 90),
  horizon: const Duration(days: 365),
);

CdrRecord _record(String id, DateTime connectTime, {CdrStatus status = CdrStatus.accepted}) => CdrRecord(
  callId: id,
  direction: CallDirection.incoming,
  status: status,
  callee: '1000',
  calleeNumber: '1000',
  caller: '2000',
  callerNumber: '2000',
  connectTime: connectTime,
  disconnectTime: connectTime.add(const Duration(seconds: 10)),
  disconnectReason: 'normal',
  duration: const Duration(seconds: 10),
);

class HistoryRequest {
  HistoryRequest(this.from, this.to, this.page, this.limit);

  final DateTime? from;
  final DateTime? to;
  final int? page;
  final int? limit;

  @override
  String toString() => 'time_from=$from time_to=$to page=$page items_per_page=$limit';
}

/// The server as it behaves with the default window on: an omitted `time_to`
/// means now, an omitted `time_from` means `time_to` minus that window, and a
/// range given in full is used as it stands.
class FakeAdapterRemoteRepository implements CdrsRemoteRepository {
  FakeAdapterRemoteRepository(
    this.archive, {
    this.inclusiveUpperBound = false,
    this.overReportsTotalBy = 0,
    this.ignoresPage = false,
    this.reportsPagination = true,
  });

  final List<CdrRecord> archive;

  /// Whether a record sitting exactly on the upper bound is returned. Backends
  /// disagree, and the one behind this app truncates the bound to whole
  /// seconds before it filters, so a caller cannot assume either.
  final bool inclusiveUpperBound;

  /// Rows the reported total counts but the endpoint never serializes - a count
  /// taken before a filter, or a record deleted between count and fetch.
  final int overReportsTotalBy;

  /// A backend that hands page 1 back whatever page was asked for.
  final bool ignoresPage;

  /// Whether the answer carries `pagination` at all.
  final bool reportsPagination;

  final List<HistoryRequest> requests = [];

  /// Awaited before every answer, so a test can hold a request in flight.
  Future<void> Function()? beforeAnswer;

  @override
  Future<CdrHistoryPage> getHistory({DateTime? timeFrom, DateTime? timeTo, int? page, int? limit}) async {
    requests.add(HistoryRequest(timeFrom, timeTo, page, limit));
    await beforeAnswer?.call();

    final rangeTo = timeTo ?? _now;
    final rangeFrom = timeFrom ?? rangeTo.subtract(_defaultWindow);

    final matched =
        archive
            .where(
              (cdr) =>
                  !cdr.connectTime.isBefore(rangeFrom) &&
                  (inclusiveUpperBound ? !cdr.connectTime.isAfter(rangeTo) : cdr.connectTime.isBefore(rangeTo)),
            )
            .toList()
          ..sort((a, b) => b.connectTime.compareTo(a.connectTime));

    final total = reportsPagination ? matched.length + overReportsTotalBy : null;
    final offset = (ignoresPage ? 0 : (page ?? 1) - 1) * (limit ?? matched.length);
    if (offset >= matched.length) return CdrHistoryPage(records: const [], itemsTotal: total);
    return CdrHistoryPage(records: matched.skip(offset).take(limit ?? matched.length).toList(), itemsTotal: total);
  }
}

class FakeLocalRepository implements CdrsLocalRepository {
  final List<CdrRecord> stored = [];
  final _events = StreamController<CdrRecordsEvent>.broadcast();
  DateTime? _syncCursor;

  @override
  Stream<CdrRecordsEvent> get events => _events.stream;

  @override
  Future<List<CdrRecord>> getHistory({
    String? number,
    String? destination,
    CdrStatus? status,
    CallDirection? direction,
    DateTime? olderThan,
    DateTime? newerThan,
    int? limit,
  }) async {
    // Mirrors cdrs_dao.dart: descending, paginated by the "older than" watermark.
    final rows = stored.where((cdr) {
      if (number != null && cdr.callerNumber != number && cdr.calleeNumber != number) return false;
      if (status != null && cdr.status != status) return false;
      if (direction != null && cdr.direction != direction) return false;
      if (olderThan != null && !cdr.connectTime.isBefore(olderThan)) return false;
      if (newerThan != null && !cdr.connectTime.isAfter(newerThan)) return false;
      return true;
    }).toList()..sort((a, b) => b.connectTime.compareTo(a.connectTime));
    return limit != null ? rows.take(limit).toList() : rows;
  }

  @override
  Future<void> upsertCdrs(List<CdrRecord> cdrs, {bool silent = false}) async {
    for (final cdr in cdrs) {
      stored.removeWhere((stored) => stored.callId == cdr.callId);
      stored.add(cdr);
      if (!silent) _events.add(CdrRecordUpserted(cdr));
    }
  }

  @override
  Future<DateTime?> getLastUpdate() async {
    if (stored.isEmpty) return null;
    return stored.map((cdr) => cdr.connectTime).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  Future<DateTime?> getFirstRecordTime() async {
    if (stored.isEmpty) return null;
    return stored.map((cdr) => cdr.connectTime).reduce((a, b) => a.isBefore(b) ? a : b);
  }

  @override
  Future<DateTime?> getLastSyncTime() async => _syncCursor;

  @override
  Future<void> markSyncCompleted(DateTime time) async {
    final first = _syncCursor == null;
    _syncCursor = time;
    if (first) _events.add(CdrsInitialSyncCompleted());
  }

  @override
  Future<void> notifyInitialSyncFailed() async {}

  @override
  Future<void> wipeData() async {
    stored.clear();
    _syncCursor = null;
    _events.add(CdrRecordsWiped());
  }

  Future<void> dispose() => _events.close();
}

class FakeSyncHandle implements PollingTaskStateSource, PollingTaskRunner {
  final _states = StreamController<PollingTaskState>.broadcast();
  Future<void> Function()? onRunNow;

  @override
  PollingTaskState get state => const PollingTaskState(phase: PollingTaskPhase.idle);

  @override
  Stream<PollingTaskState> get states => _states.stream;

  @override
  Future<void> runNow() async => onRunNow?.call();

  Future<void> dispose() => _states.close();
}

void main() {
  late FakeLocalRepository local;
  late FakeSyncHandle syncHandle;

  setUp(() {
    local = FakeLocalRepository();
    syncHandle = FakeSyncHandle();
  });

  tearDown(() async {
    await local.dispose();
    await syncHandle.dispose();
  });

  FullRecentCdrsCubit fullCubit(CdrsRemoteRepository remote, {HistoryWindows? windows}) => FullRecentCdrsCubit(
    local,
    remote,
    syncHandle,
    syncHandle,
    pageSize: _pageSize,
    historyWindows: windows ?? _windows,
  );

  /// Waits out a fetch the cubit started on its own, so a test never races the
  /// list filling itself.
  Future<void> settle(CdrsListCubit cubit, {int pumps = 200}) async {
    for (var i = 0; i < pumps && cubit.state.fetchingHistory; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Scrolls to the bottom until the list stops growing or says the history
  /// ended, so a test asserts on what a user can actually reach.
  Future<void> scrollToTheEnd(CdrsListCubit cubit, {int limit = 20}) async {
    await settle(cubit);
    for (var i = 0; i < limit; i++) {
      final before = cubit.state.records.length;
      await cubit.fetchHistory();
      await settle(cubit);
      if (cubit.state.historyEndReached) return;
      if (cubit.state.records.length == before) return;
    }
  }

  test(
    'a gap wider than a slice no longer ends the history',
    () => withClock(Clock.fixed(_now), () async {
      // Two calls today, then FOUR QUIET DAYS, then eight older ones.
      final archive = <CdrRecord>[
        _record('today-1', _now.subtract(const Duration(hours: 1))),
        _record('today-2', _now.subtract(const Duration(hours: 5))),
        for (var i = 0; i < 8; i++) _record('old-$i', _now.subtract(Duration(days: 5, hours: i * 3))),
      ];
      final remote = FakeAdapterRemoteRepository(archive);

      // The cache as a first launch leaves it: one page, newest first.
      await CdrsSyncWorker(local, remote, pageSize: _pageSize, historyWindows: _windows).refresh();
      expect(local.stored, hasLength(_pageSize));

      final cubit = fullCubit(remote);
      await cubit.init();
      await scrollToTheEnd(cubit);

      expect(cubit.state.records.map((cdr) => cdr.callId).toSet(), {
        'today-1',
        'today-2',
        for (var i = 0; i < 8; i++) 'old-$i',
      }, reason: 'the four silent days are crossed instead of ending the list');
      await cubit.close();
    }),
  );

  test(
    'the horizon ends the list, and an empty answer does not',
    () => withClock(Clock.fixed(_now), () async {
      final remote = FakeAdapterRemoteRepository([_record('today-1', _now.subtract(const Duration(hours: 1)))]);
      await CdrsSyncWorker(local, remote, pageSize: _pageSize, historyWindows: _windows).refresh();

      final seeded = remote.requests.length;
      final cubit = fullCubit(remote);
      await cubit.init();
      await scrollToTheEnd(cubit);

      expect(cubit.state.historyEndReached, isTrue);
      final walked = remote.requests.skip(seeded).where((request) => request.from != null).toList();
      expect(walked, hasLength(7), reason: 'a year of silence is seven slices, not seven hundred');
      expect(walked.last.from, _now.subtract(const Duration(days: 365)));
      await cubit.close();
    }),
  );

  test(
    'an empty slice still moves the walk on',
    () => withClock(Clock.fixed(_now), () async {
      final remote = FakeAdapterRemoteRepository([_record('today-1', _now.subtract(const Duration(hours: 1)))]);
      await CdrsSyncWorker(local, remote, pageSize: _pageSize, historyWindows: _windows).refresh();

      final seeded = remote.requests.length;
      final cubit = fullCubit(remote);
      await cubit.init();
      await scrollToTheEnd(cubit);

      final ranges = remote.requests
          .skip(seeded)
          .where((r) => r.from != null)
          .map((r) => '${r.from}..${r.to}')
          .toList();
      expect(ranges.toSet(), hasLength(ranges.length), reason: 'no range is asked for twice');
      await cubit.close();
    }),
  );

  test(
    'a slice holding more than a page is drained page by page',
    () => withClock(Clock.fixed(_now), () async {
      // Twelve calls in the same week, two of them missed: the missed list has to
      // page through the slice to find them, and the page size is five.
      final archive = <CdrRecord>[
        for (var i = 0; i < 12; i++) _record('call-$i', _now.subtract(Duration(days: 2, hours: i))),
        _record('missed-1', _now.subtract(const Duration(days: 2, hours: 20)), status: CdrStatus.missed),
        _record('missed-2', _now.subtract(const Duration(days: 2, hours: 21)), status: CdrStatus.missed),
      ];
      final remote = FakeAdapterRemoteRepository(archive);

      final cubit = MissedRecentCdrsCubit(
        local,
        remote,
        syncHandle,
        syncHandle,
        pageSize: _pageSize,
        historyWindows: _windows,
      );
      await cubit.init();
      await scrollToTheEnd(cubit);

      expect(cubit.state.records.map((cdr) => cdr.callId).toSet(), {'missed-1', 'missed-2'});
      final firstSlice = remote.requests.where((r) => r.from == _now.subtract(const Duration(days: 7))).toList();
      expect(firstSlice.map((r) => r.page), containsAllInOrder([1, 2, 3]), reason: 'the slice is drained by pages');
      await cubit.close();
    }),
  );

  test(
    'a record returned on both sides of a boundary is listed once',
    () => withClock(Clock.fixed(_now), () async {
      // The walk resumes at the oldest cached record, so the first slice runs
      // from seven days before THAT. A record sitting exactly there is returned
      // by both slices when the backend counts its upper bound in.
      final cachedAt = _now.subtract(const Duration(hours: 1));
      final archive = <CdrRecord>[
        _record('today-1', cachedAt),
        _record('edge', cachedAt.subtract(const Duration(days: 7))),
      ];
      final remote = FakeAdapterRemoteRepository(archive, inclusiveUpperBound: true);
      await CdrsSyncWorker(local, remote, pageSize: _pageSize, historyWindows: _windows).refresh();

      final cubit = fullCubit(remote);
      await cubit.init();
      await scrollToTheEnd(cubit);

      expect(cubit.state.records.where((cdr) => cdr.callId == 'edge'), hasLength(1));
      await cubit.close();
    }),
  );

  test(
    'the walk resumes where it left off, not where the cache happens to end',
    () => withClock(Clock.fixed(_now), () async {
      // The walk's progress is its own bookkeeping. Deriving it from the cache
      // would let anything else that writes a record - a sync cycle, another
      // screen - move it, and the days in between would never be walked.
      //
      // Eight calls over the last two days fill a page of five before the first
      // slice is drained, so the walk stops with part of that slice still
      // unasked - which is exactly where it has to pick up again.
      final archive = <CdrRecord>[
        for (var i = 0; i < 8; i++) _record('recent-$i', _now.subtract(Duration(hours: 6 + i * 6))),
      ];
      final remote = FakeAdapterRemoteRepository(archive);
      // A cache holding two of them, as a cycle interrupted after one page
      // would leave it.
      await local.upsertCdrs(archive.take(2).toList(), silent: true);
      await local.markSyncCompleted(_now);

      final cubit = fullCubit(remote);
      await cubit.init();
      await settle(cubit);
      final cursorAfterFirstWalk = cubit.state.historyCursor;
      expect(cursorAfterFirstWalk, isNotNull);
      expect(cubit.state.historyEndReached, isFalse, reason: 'the page filled before the horizon');

      // Something else drops a much older record into the shared cache.
      await local.upsertCdrs([_record('from-elsewhere', _now.subtract(const Duration(days: 300)))]);
      final askedBefore = remote.requests.length;

      await cubit.fetchHistory();
      await settle(cubit);

      final resumed = remote.requests.skip(askedBefore).where((r) => r.from != null).toList();
      expect(resumed, isNotEmpty);
      expect(
        resumed.first.to,
        cursorAfterFirstWalk,
        reason: 'the next slice ends at the cursor, not at the 300-day-old record',
      );
      await cubit.close();
    }),
  );

  test(
    'a list too short to scroll fills itself instead of waiting to be scrolled',
    () => withClock(Clock.fixed(_now), () async {
      // What a device showed and no fake had: three calls today, the rest of
      // the archive ten days back. Three rows do not fill a screen, a list that
      // does not scroll never fires its pagination listener, and the user is
      // left looking at three calls with no way to ask for the others.
      final archive = <CdrRecord>[
        for (var i = 0; i < 3; i++) _record('today-$i', _now.subtract(Duration(hours: 1 + i))),
        for (var i = 0; i < 4; i++) _record('old-$i', _now.subtract(Duration(days: 10, hours: i))),
      ];
      final remote = FakeAdapterRemoteRepository(archive);
      await CdrsSyncWorker(local, remote, pageSize: _pageSize, historyWindows: _windows).refresh();
      expect(local.stored, hasLength(3), reason: 'the first slice holds only today');

      final cubit = fullCubit(remote);
      await cubit.init();
      await settle(cubit);

      expect(cubit.state.records.map((cdr) => cdr.callId).toSet(), {
        'today-0',
        'today-1',
        'today-2',
        'old-0',
        'old-1',
        'old-2',
        'old-3',
      }, reason: 'nobody scrolled: the list had to fill itself');
      await cubit.close();
    }),
  );

  test(
    'a screen opened before the first sync also fills itself once it lands',
    () => withClock(Clock.fixed(_now), () async {
      // The same shortfall through the other door: the list is already on
      // screen when the first cycle completes, so what it shows is whatever
      // that cycle stored - three rows, and nothing to scroll.
      final archive = <CdrRecord>[
        for (var i = 0; i < 3; i++) _record('today-$i', _now.subtract(Duration(hours: 1 + i))),
        for (var i = 0; i < 4; i++) _record('old-$i', _now.subtract(Duration(days: 10, hours: i))),
      ];
      final remote = FakeAdapterRemoteRepository(archive);

      final cubit = fullCubit(remote);
      await cubit.init();
      expect(cubit.state.isLoading, isTrue, reason: 'nothing cached and never synced');

      await CdrsSyncWorker(local, remote, pageSize: _pageSize, historyWindows: _windows).refresh();
      await Future<void>.delayed(Duration.zero);
      await settle(cubit);

      expect(cubit.state.records.map((cdr) => cdr.callId).toSet(), {
        'today-0',
        'today-1',
        'today-2',
        'old-0',
        'old-1',
        'old-2',
        'old-3',
      });
      await cubit.close();
    }),
  );

  test(
    'a slice whose reported total is never reached ends on the empty page',
    () => withClock(Clock.fixed(_now), () async {
      // The count can include rows the endpoint never serializes. Trusting it
      // alone would ask for page after page of nothing, forever.
      final archive = <CdrRecord>[
        for (var i = 0; i < 7; i++) _record('today-$i', _now.subtract(Duration(hours: 1 + i))),
      ];
      final remote = FakeAdapterRemoteRepository(archive, overReportsTotalBy: 20);
      await local.markSyncCompleted(_now);

      final cubit = MissedRecentCdrsCubit(
        local,
        remote,
        syncHandle,
        syncHandle,
        pageSize: _pageSize,
        historyWindows: _windows,
      );
      await cubit.init();
      await settle(cubit);

      final firstSlice = remote.requests.where((r) => r.to == _now).toList();
      expect(firstSlice.map((r) => r.page), [1, 2, 3], reason: 'two pages of records, one empty page, then on');
      expect(cubit.state.historyEndReached, isTrue, reason: 'and the walk still ended at the horizon');
      await cubit.close();
    }),
  );

  test(
    'a backend that ignores the page number cannot hold the walk in one slice',
    () => withClock(Clock.fixed(_now), () async {
      final archive = <CdrRecord>[
        for (var i = 0; i < 7; i++) _record('today-$i', _now.subtract(Duration(hours: 1 + i))),
      ];
      final remote = FakeAdapterRemoteRepository(archive, ignoresPage: true, reportsPagination: false);
      await local.markSyncCompleted(_now);

      final cubit = MissedRecentCdrsCubit(
        local,
        remote,
        syncHandle,
        syncHandle,
        pageSize: _pageSize,
        historyWindows: _windows,
      );
      await cubit.init();
      await settle(cubit);

      final firstSlice = remote.requests.where((r) => r.to == _now).toList();
      expect(firstSlice.length, lessThanOrEqualTo(40), reason: 'a page budget, not an infinite loop');
      expect(remote.requests.where((r) => r.to != _now), isNotEmpty, reason: 'and the walk moved on');
      await cubit.close();
    }),
  );

  test(
    'a record sharing its second with the oldest one taken is not left behind',
    () => withClock(Clock.fixed(_now), () async {
      // PortaBilling stamps a call to the second, so two legs of one call carry
      // the same connect time. Resuming at exactly that instant, with an upper
      // bound the backend treats as exclusive, would never ask for the second
      // leg again.
      final shared = _now.subtract(const Duration(hours: 3));
      final archive = <CdrRecord>[
        _record('n-1', _now.subtract(const Duration(hours: 1))),
        _record('n-2', _now.subtract(const Duration(hours: 2))),
        _record('leg-a', shared),
        _record('leg-b', shared),
        _record('older', _now.subtract(const Duration(hours: 9))),
      ];
      final remote = FakeAdapterRemoteRepository(archive);
      await local.markSyncCompleted(_now);

      final cubit = FullRecentCdrsCubit(local, remote, syncHandle, syncHandle, pageSize: 3, historyWindows: _windows);
      await cubit.init();
      await settle(cubit);
      expect(cubit.state.records, hasLength(3), reason: 'the page filled with n-1, n-2 and one leg');

      await scrollToTheEnd(cubit);

      expect(cubit.state.records.map((cdr) => cdr.callId).toSet(), containsAll(['leg-a', 'leg-b', 'older']));
      await cubit.close();
    }),
  );

  test(
    'with the walk switched off a filtered list still moves past records it does not match',
    () => withClock(Clock.fixed(_now), () async {
      // Deriving the next request from the FILTERED list's oldest row would ask
      // the same question forever: a page of accepted calls changes nothing the
      // Missed list shows.
      final archive = <CdrRecord>[
        _record('missed-recent', _now.subtract(const Duration(hours: 1)), status: CdrStatus.missed),
        for (var i = 0; i < 5; i++) _record('accepted-$i', _now.subtract(Duration(hours: 2 + i))),
        _record('missed-old', _now.subtract(const Duration(hours: 20)), status: CdrStatus.missed),
      ];
      final remote = FakeAdapterRemoteRepository(archive);
      await local.upsertCdrs([archive.first], silent: true);
      await local.markSyncCompleted(_now);

      final cubit = MissedRecentCdrsCubit(
        local,
        remote,
        syncHandle,
        syncHandle,
        pageSize: _pageSize,
        historyWindows: const HistoryWindows(
          firstWidth: Duration(days: 7),
          maxWidth: Duration(days: 90),
          horizon: Duration.zero,
        ),
      );
      await cubit.init();
      await settle(cubit);
      await cubit.fetchHistory();
      await settle(cubit);

      expect(cubit.state.records.map((cdr) => cdr.callId), ['missed-recent', 'missed-old']);
      final asked = remote.requests.map((r) => '${r.to}').toList();
      expect(asked.toSet(), hasLength(asked.length), reason: 'no request was repeated');
      await cubit.close();
    }),
  );

  test(
    'a page worth means records the list gained, not records the page held',
    () => withClock(Clock.fixed(_now), () async {
      // The record already on screen comes back on the boundary; counting it
      // would stop the walk a row short, and a list one row short of a screen
      // has nothing to scroll.
      final shown = _record('shown', _now.subtract(const Duration(hours: 1)));
      final archive = <CdrRecord>[
        shown,
        for (var i = 0; i < 4; i++) _record('new-$i', _now.subtract(Duration(hours: 2 + i))),
      ];
      final remote = FakeAdapterRemoteRepository(archive, inclusiveUpperBound: true);
      await local.upsertCdrs([shown], silent: true);
      await local.markSyncCompleted(_now);

      final cubit = FullRecentCdrsCubit(local, remote, syncHandle, syncHandle, pageSize: 3, historyWindows: _windows);
      await cubit.init();
      await settle(cubit);

      expect(cubit.state.records.length - 1, greaterThanOrEqualTo(3), reason: 'three NEW rows, the repeat not counted');
      await cubit.close();
    }),
  );

  test(
    'a wipe while a walk is in flight discards what the walk brings back',
    () => withClock(Clock.fixed(_now), () async {
      final archive = <CdrRecord>[
        for (var i = 0; i < 3; i++) _record('today-$i', _now.subtract(Duration(hours: 1 + i))),
      ];
      final remote = FakeAdapterRemoteRepository(archive);
      await local.markSyncCompleted(_now);
      final gate = Completer<void>();
      remote.beforeAnswer = () => gate.future;

      final cubit = FullRecentCdrsCubit(
        local,
        remote,
        syncHandle,
        syncHandle,
        pageSize: _pageSize,
        historyWindows: _windows,
      );
      await cubit.init(); // starts a walk: the store is short
      await Future<void>.delayed(Duration.zero);
      expect(remote.requests, isNotEmpty, reason: 'the first slice is in flight');

      await local.wipeData();
      await Future<void>.delayed(Duration.zero);
      remote.beforeAnswer = null;
      gate.complete();
      await settle(cubit);
      await Future<void>.delayed(Duration.zero);

      expect(local.stored, isEmpty, reason: 'the pre-wipe answer must not land in the wiped store');
      expect(cubit.state.historyCursor, isNull, reason: 'nor may its cursor land on the fresh state');
      await cubit.close();
    }),
  );

  test(
    'a walk cut short by the sanity bound does not declare the history over',
    () => withClock(Clock.fixed(_now), () async {
      // Widths that defeat the widening reach 64 slices before the horizon; the
      // list must keep its cursor and go on next time, not latch the end.
      final remote = FakeAdapterRemoteRepository([_record('today', _now.subtract(const Duration(hours: 1)))]);
      await local.markSyncCompleted(_now);

      final cubit = FullRecentCdrsCubit(
        local,
        remote,
        syncHandle,
        syncHandle,
        pageSize: _pageSize,
        historyWindows: const HistoryWindows(
          firstWidth: Duration(hours: 1),
          maxWidth: Duration(hours: 1),
          horizon: Duration(days: 365),
        ),
      );
      await cubit.init();
      await settle(cubit);

      expect(cubit.state.historyEndReached, isFalse);
      expect(cubit.state.historyCursor, isNotNull);
      await cubit.close();
    }),
  );

  test(
    'a zero horizon asks the way the app asked before the walk',
    () => withClock(Clock.fixed(_now), () async {
      final remote = FakeAdapterRemoteRepository([_record('today-1', _now.subtract(const Duration(hours: 1)))]);
      await CdrsSyncWorker(local, remote, pageSize: _pageSize, historyWindows: _windows).refresh();
      final requestsBefore = remote.requests.length;

      final cubit = fullCubit(
        remote,
        windows: const HistoryWindows(
          firstWidth: Duration(days: 7),
          maxWidth: Duration(days: 90),
          horizon: Duration.zero,
        ),
      );
      await cubit.init();
      await settle(cubit);
      await cubit.fetchHistory();
      await settle(cubit);
      await settle(cubit);

      final asked = remote.requests.skip(requestsBefore).toList();
      expect(asked, hasLength(1), reason: 'one request, no walk');
      expect(asked.single.from, isNull, reason: 'and no lower bound, exactly as before');
      await cubit.close();
    }),
  );

  test(
    'slices that hold nothing for a filtered list keep the walk going',
    () => withClock(Clock.fixed(_now), () async {
      final archive = <CdrRecord>[
        for (var i = 0; i < 6; i++) _record('recent-$i', _now.subtract(Duration(days: 1, hours: i))),
        _record('missed-old', _now.subtract(const Duration(days: 40)), status: CdrStatus.missed),
      ];
      final remote = FakeAdapterRemoteRepository(archive);

      final cubit = MissedRecentCdrsCubit(
        local,
        remote,
        syncHandle,
        syncHandle,
        pageSize: _pageSize,
        historyWindows: _windows,
      );
      await cubit.init();
      await scrollToTheEnd(cubit);

      expect(cubit.state.records.map((cdr) => cdr.callId), ['missed-old']);
      await cubit.close();
    }),
  );
}
