import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';
import 'package:webtrit_phone/utils/utils.dart';

import '../services/cdrs_history_walk.dart';

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
    CdrsHistoryWalk? historyWalk,
  }) : historyWalk = historyWalk ?? CdrsHistoryWalk(localRepository, remoteRepository, pageSize: pageSize),
       super(const CdrsListState());

  final CdrsLocalRepository localRepository;
  final CdrsRemoteRepository remoteRepository;
  final PollingTaskStateSource syncStateSource;
  final int pageSize;

  /// Shared with the other lists over the same store: one walk at a time, one
  /// watermark, one set of slices.
  final CdrsHistoryWalk historyWalk;

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

  /// Loads more records into the list: what the store already holds, and then
  /// the history walked further back.
  ///
  /// The walk itself belongs to [historyWalk], which is one object for the
  /// whole store. What this list contributes is what it is FOR: which records
  /// it wants, how it shows them, and when it has stopped caring.
  Future<void> fetchHistory() async {
    if (state.fetchingHistory || state.historyEndReached) return;

    emit(state.copyWith(fetchingHistory: true));
    final generation = _walkGeneration;
    try {
      final result = await historyWalk.forList(
        wanted: pageSize,
        matches: matches,
        takeWhatIsStored: _takeLocalPage,
        show: _show,
        cancelled: () => isClosed || generation != _walkGeneration,
      );
      if (isClosed || generation != _walkGeneration) return;
      emit(state.copyWith(fetchingHistory: false, historyEndReached: result.reachedHorizon ? true : null));
    } catch (e, s) {
      logger.severe('Failed to load CDRs', e, s);
      CrashlyticsUtils.recordError(
        e,
        stack: s,
        reason: '$runtimeType.fetchHistory',
        information: [
          'oldestLocal: ${state.records.isNotEmpty ? state.records.last.connectTime.toIso8601String() : 'none'}',
          'pageSize: ${pageSize.toString()}',
          'currentCount: ${state.records.length.toString()}',
        ],
      );
      if (!isClosed) emit(state.copyWith(fetchingHistory: false));
    }
  }

  /// Reads the next local page into the list and answers with how many rows it
  /// GAINED - records already listed add nothing to scroll through.
  ///
  /// The generation is checked like every other await in the fetch path: a wipe
  /// landing while this query is in flight leaves it holding rows the store no
  /// longer has, and emitting them would put deleted calls back on screen.
  Future<int> _takeLocalPage() async {
    final generation = _walkGeneration;
    final oldestLocal = state.records.lastOrNull?.connectTime;
    final localPage = await queryLocal(olderThan: oldestLocal);
    if (isClosed || generation != _walkGeneration || localPage.isEmpty) return 0;

    return _show(localPage);
  }

  /// Puts a batch on screen and answers with the rows the list actually gained:
  /// a record already there - a boundary repeat, or one another list fetched
  /// first - adds nothing to scroll through.
  int _show(List<CdrRecord> records) {
    final before = state.records.length;
    emit(state.copyWith(records: state.records.mergeWithHistory(records).toList()));
    return state.records.length - before;
  }

  /// Bumped by a wipe. A walk that started before it must not write what it
  /// fetched onto the fresh state.
  int _walkGeneration = 0;

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
