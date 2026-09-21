import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';
import 'package:webtrit_phone/utils/utils.dart';

import '../services/cdrs_history_windows.dart';

part 'cdrs_list_state.dart';

/// Base for the CDR list cubits (full, missed, per-number). Owns the shared
/// lifecycle: the initial load with its loading gate (an empty cache only
/// means "loading" while the first remote sync can still complete), the
/// repository event handling, and the walk back through the remote history.
/// Subclasses provide the local query and the event predicate, and may override
/// the history fetching strategy.
abstract class CdrsListCubit extends Cubit<CdrsListState> {
  CdrsListCubit(
    this.localRepository,
    this.remoteRepository,
    this.syncStateSource, {
    this.pageSize = 50,
    HistoryWindows? historyWindows,
  }) : historyWindows = historyWindows ?? configuredCdrsHistoryWindows(),
       super(const CdrsListState());

  final CdrsLocalRepository localRepository;
  final CdrsRemoteRepository remoteRepository;
  final PollingTaskStateSource syncStateSource;
  final int pageSize;

  /// The slices the remote history is asked for, oldest bound first.
  final HistoryWindows historyWindows;

  late final Logger logger = Logger(runtimeType.toString());

  StreamSubscription<CdrRecordsEvent>? _eventsSub;
  StreamSubscription<PollingTaskState>? _syncStatesSub;
  bool _initialSyncHandled = false;

  /// Local query backing this list; [olderThan] is the pagination watermark.
  Future<List<CdrRecord>> queryLocal({DateTime? olderThan});

  /// Whether an upserted record belongs to this list.
  bool matches(CdrRecord cdr);

  Future<void> init() async {
    logger.info('Loading CDRs');
    try {
      final cached = await queryLocal();
      if (isClosed) return;
      // An empty cache only means "loading" while the initial remote sync has
      // not completed yet; after it, an empty list is genuinely empty.
      final synced = await localRepository.getLastSyncTime() != null;
      if (isClosed) return;
      emit(state.copyWith(records: cached, isLoading: cached.isEmpty && !synced));
      _eventsSub = localRepository.events.listen(_handleEvent);
      _syncStatesSub = syncStateSource.states.listen(_handleSyncState);

      if (state.isLoading) {
        // Close the race between the sync-time read above and the subscription:
        // if the initial sync completed in that window, resolve now.
        final syncedNow = await localRepository.getLastSyncTime() != null;
        if (isClosed) return;
        if (syncedNow) {
          await _onInitialSyncCompleted();
        } else {
          _releaseInitialLoadingIfUnavailable(syncStateSource.state);
        }
      } else {
        _initialSyncHandled = true;
        // A list shorter than the screen cannot be scrolled, so its pagination
        // listener never fires and the user has no way to ask for more; it has
        // to fill itself. A short list is the ordinary case now that what fills
        // the store first is one page of one slice, not a page of the archive.
        if (cached.length < pageSize) fetchHistory();
      }
    } catch (e, s) {
      logger.severe('Failed to initialize', e, s);
      // Resolve rather than spin forever on an unexpected local failure.
      if (!isClosed) emit(state.copyWith(isLoading: false));
    }
  }

  void _handleSyncState(PollingTaskState syncState) {
    _releaseInitialLoadingIfUnavailable(syncState);
  }

  void _releaseInitialLoadingIfUnavailable(PollingTaskState syncState) {
    if (syncState.phase == PollingTaskPhase.waitingForConnectivity ||
        syncState.phase == PollingTaskPhase.failed ||
        syncState.phase == PollingTaskPhase.stopped) {
      _releaseInitialLoading();
    }
  }

  /// Runs once the initial remote sync has completed: brings the list up to
  /// date and only then resolves the loading state, keeping the loader
  /// visible for the whole first load.
  Future<void> _onInitialSyncCompleted() async {
    if (_initialSyncHandled) return;
    _initialSyncHandled = true;
    try {
      await resolveInitialLoad();
    } catch (e, s) {
      logger.severe('Failed to resolve the initial load', e, s);
    }
    if (isClosed) return;
    emit(state.copyWith(isLoading: false));
  }

  /// Resolves the loading state after an initial failure or an automatic cycle
  /// waits for connectivity. Nothing is latched: the eventual successful cycle
  /// still triggers [resolveInitialLoad] once.
  void _releaseInitialLoading() {
    if (state.isLoading) emit(state.copyWith(isLoading: false));
  }

  /// Brings the list up to date after the initial sync: the local re-read, and
  /// the walk when that leaves the list too short to scroll.
  Future<void> resolveInitialLoad() => fetchHistory();

  /// Loads more records into the list: the next local page and, when that comes
  /// up short, the remote history walked further back.
  ///
  /// The walk is what makes an older record reachable at all. A history request
  /// without a range is answered about recent history alone, so reaching past
  /// it means naming the range - and a range that answers empty says "no calls
  /// in those days", never "the archive ends here". Only the horizon ends the
  /// list.
  Future<void> fetchHistory() async {
    if (state.fetchingHistory || state.historyEndReached) return;

    emit(state.copyWith(fetchingHistory: true));
    try {
      final oldestLocal = state.records.lastOrNull?.connectTime;
      final localPage = await queryLocal(olderThan: oldestLocal);
      if (isClosed) return;
      if (localPage.isNotEmpty) {
        emit(state.copyWith(records: state.records.mergeWithHistory(localPage).toList()));
      }

      if (localPage.length < pageSize) {
        logger.info('Local CDRs exhausted, walking the remote history back');
        await _walkRemoteHistory(collected: localPage.length);
      }
      if (isClosed) return;
      emit(state.copyWith(fetchingHistory: false));
    } catch (e, s) {
      logger.severe('Failed to load CDRs', e, s);
      CrashlyticsUtils.recordError(
        e,
        stack: s,
        reason: '$runtimeType.fetchHistory',
        information: [
          'oldestLocal: ${state.records.isNotEmpty ? state.records.last.connectTime.toIso8601String() : 'none'}',
          'historyCursor: ${state.historyCursor?.toIso8601String() ?? 'none'}',
          'pageSize: ${pageSize.toString()}',
          'currentCount: ${state.records.length.toString()}',
        ],
      );
      if (!isClosed) emit(state.copyWith(fetchingHistory: false));
    }
  }

  /// Pages one slice may be asked for before the walk gives up on it. Bounds a
  /// backend that ignores `page` and hands the same full page back forever;
  /// at fifty records a page it is two thousand records in one slice.
  static const _pagesPerWindowLimit = 40;

  /// How coarsely the backend stamps a record. A resumed slice overlaps the
  /// previous one by this much, so a record sharing its second with the oldest
  /// one taken is asked for again rather than lost; the merge drops the repeat.
  static const _backendResolution = Duration(seconds: 1);

  /// Bumped by a wipe. A walk that started before it must not write what it
  /// fetched into the wiped store nor put its cursor onto the fresh state.
  int _walkGeneration = 0;

  /// Walks slices of remote history back from the cursor until this list has a
  /// page worth of records or the horizon is reached.
  ///
  /// Every record a slice returns is persisted, matching or not: the walk is
  /// paid for once and the cache keeps all of it.
  Future<void> _walkRemoteHistory({required int collected}) async {
    if (historyWindows.horizon == Duration.zero) {
      // The way back to the behaviour that predates the walk, without a code
      // change: one request that names no lower bound and lets the backend
      // decide how far back it reaches.
      await _fetchUnboundedPage();
      return;
    }

    final generation = _walkGeneration;
    // The watermark belongs to the store, not to this list: whatever walked
    // before - the other tab, this screen last time, the cycle that filled an
    // empty store - covered those days for everyone.
    final resumeAt =
        await localRepository.getHistoryWalkedTo() ?? await localRepository.getFirstRecordTime() ?? clock.now();
    if (isClosed || generation != _walkGeneration) return;

    var reachedHorizon = false;
    for (final window in historyWindows.backFrom(resumeAt)) {
      var page = 1;
      var takenFromWindow = 0;
      DateTime? oldestTaken;

      while (true) {
        final result = await remoteRepository.getHistory(
          timeFrom: window.timeFrom,
          timeTo: window.timeTo,
          page: page,
          limit: pageSize,
        );
        if (isClosed || generation != _walkGeneration) return;
        await localRepository.upsertCdrs(result.records, silent: true);
        if (isClosed || generation != _walkGeneration) return;

        takenFromWindow += result.records.length;
        for (final cdr in result.records) {
          if (oldestTaken == null || cdr.connectTime.isBefore(oldestTaken)) oldestTaken = cdr.connectTime;
        }

        final matched = result.records.where(matches).toList();
        if (matched.isNotEmpty) {
          // Count what the list actually gained, not what the page held: a
          // record already listed - a boundary repeat, or a slice another list
          // walked first - adds nothing to scroll through.
          final before = state.records.length;
          emit(state.copyWith(records: state.records.mergeWithHistory(matched).toList()));
          collected += state.records.length - before;
        }
        logger.fine('Walked $window page $page: ${result.records.length} records, ${matched.length} for this list');

        if (collected >= pageSize) {
          // Enough for the user to go on with. Resume from the oldest record
          // taken rather than from the slice's far edge, so whatever is left of
          // this slice is still walked next time - overlapping by one backend
          // tick so a record stamped with the same second is not left behind.
          final resume = oldestTaken?.add(_backendResolution) ?? window.timeFrom;
          final walkedTo = resume.isBefore(window.timeTo) ? resume : window.timeTo;
          await localRepository.markHistoryWalkedTo(walkedTo);
          if (isClosed || generation != _walkGeneration) return;
          emit(state.copyWith(historyCursor: walkedTo));
          return;
        }

        // An empty page ends a slice whatever a total said: a count can include
        // rows the endpoint never serializes, and asking for page after page of
        // nothing is the one way this loop could fail to end.
        if (result.records.isEmpty || !result.hasMoreAfter(takenFromWindow)) break;
        if (page >= _pagesPerWindowLimit) {
          logger.warning('Gave up on $window after $page pages; the backend may be ignoring the page number');
          break;
        }
        page++;
      }

      // The slice moves the cursor whatever it held. A walk that advanced by
      // the records instead would stand still on an empty answer, which is the
      // whole reason older history was unreachable.
      await localRepository.markHistoryWalkedTo(window.timeFrom);
      if (isClosed || generation != _walkGeneration) return;
      emit(state.copyWith(historyCursor: window.timeFrom));
      reachedHorizon = window.endsAtHorizon;
    }

    // Only the horizon ends a list. A walk that ran out of slices any other way
    // - the sanity bound on a misconfigured width - resumes from the watermark
    // on the next gesture instead of declaring the archive over.
    if (reachedHorizon || !resumeAt.isAfter(clock.now().subtract(historyWindows.horizon))) {
      emit(state.copyWith(historyEndReached: true));
    }
  }

  /// One page of history with no lower bound, for a deployment that switched
  /// the walk off. The backend decides how far back it looks; what this side
  /// owns is where the next page starts, and that is the oldest record the
  /// LAST PAGE returned - not the oldest record this list shows, which a
  /// filtered list would never move past a page of records it does not match.
  Future<void> _fetchUnboundedPage() async {
    final generation = _walkGeneration;
    final timeTo =
        state.historyCursor ?? await localRepository.getHistoryWalkedTo() ?? state.records.lastOrNull?.connectTime;
    if (isClosed || generation != _walkGeneration) return;

    final result = await remoteRepository.getHistory(timeTo: timeTo, limit: pageSize);
    if (isClosed || generation != _walkGeneration) return;
    await localRepository.upsertCdrs(result.records, silent: true);
    if (isClosed || generation != _walkGeneration) return;

    if (result.records.isEmpty) {
      emit(state.copyWith(historyEndReached: true));
      return;
    }

    final matched = result.records.where(matches).toList();
    final oldest = result.records.map((cdr) => cdr.connectTime).reduce((a, b) => a.isBefore(b) ? a : b);
    await localRepository.markHistoryWalkedTo(oldest);
    if (isClosed || generation != _walkGeneration) return;
    emit(
      state.copyWith(
        records: matched.isEmpty ? null : state.records.mergeWithHistory(matched).toList(),
        historyCursor: oldest,
      ),
    );
  }

  void _handleEvent(CdrRecordsEvent event) {
    if (event is CdrRecordUpserted && matches(event.cdr)) {
      final records = state.records.mergeWithUpdate(event.cdr).toList();
      emit(state.copyWith(records: records, isLoading: false));
    }
    if (event is CdrsInitialSyncCompleted) {
      _onInitialSyncCompleted();
    }
    if (event is CdrsInitialSyncFailed) {
      _releaseInitialLoading();
    }
    if (event is CdrRecordsWiped) {
      // A wipe clears the sync cursor as well, returning the store to its
      // pre-initial-sync state: drop the in-memory records, the walk cursor
      // with them, and re-arm the loading gate until the next sync cycle
      // reports the fresh state.
      _initialSyncHandled = false;
      _walkGeneration++;
      emit(const CdrsListState());
      _releaseInitialLoadingIfUnavailable(syncStateSource.state);
    }
  }

  @override
  Future<void> close() async {
    await _eventsSub?.cancel();
    await _syncStatesSub?.cancel();
    return super.close();
  }
}
