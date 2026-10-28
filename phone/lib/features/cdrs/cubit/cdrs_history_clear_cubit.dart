import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import 'package:api/api.dart' show EndpointNotSupportedException;

import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

final _logger = Logger('CdrsHistoryClearCubit');

/// Where a clear of the server call history stands.
///
/// The three outcomes are kept apart because the screen says different things
/// about them: a backend that cannot clear is not worth a retry, a failed
/// request is.
enum CdrsHistoryClearState { idle, clearing, cleared, unsupported, failed }

/// Clears the server call history: asks the backend, then drops the local copy.
///
/// The backend remembers when the history was cleared and returns nothing older
/// from then on, on every device of the account. What this device still holds
/// is dropped through the local repository, which marks the store synced and
/// walked to the beginning, so neither the next cycle nor the lists ask for
/// the archive the backend now hides.
class CdrsHistoryClearCubit extends Cubit<CdrsHistoryClearState> {
  CdrsHistoryClearCubit(this._remoteRepository, this._localRepository, this._syncRunner)
    : super(CdrsHistoryClearState.idle);

  final CdrsRemoteRepository _remoteRepository;
  final CdrsLocalRepository _localRepository;
  final PollingTaskRunner _syncRunner;

  Future<void> clear() async {
    if (state == CdrsHistoryClearState.clearing) return;
    emit(CdrsHistoryClearState.clearing);

    try {
      await _remoteRepository.clearHistory();
    } on EndpointNotSupportedException {
      if (!isClosed) emit(CdrsHistoryClearState.unsupported);
      return;
    } catch (e, s) {
      _logger.warning('Clearing the call history failed', e, s);
      if (!isClosed) emit(CdrsHistoryClearState.failed);
      return;
    }

    // A cycle may be running that fetched its pages before the clear: let it
    // end first, or what it stores would land after the local copy is gone. A
    // cycle that starts after the clear notices it by itself.
    await _sync();

    // The backend has cleared, so the local copy goes even if the screen has
    // gone meanwhile. The clear is done either way: a copy that could not be
    // dropped here is dropped by the next cycle, which no longer finds its
    // newest record on the backend, and asking again would clear the calls
    // made in between.
    try {
      await _localRepository.replaceAfterClear(const [], syncedAt: clock.now());
    } catch (e, s) {
      _logger.warning('Dropping the local call history after a clear failed', e, s);
    }
    if (!isClosed) emit(CdrsHistoryClearState.cleared);

    // Brings in the calls made since the clear, if there are any already.
    await _sync();
  }

  Future<void> _sync() async {
    try {
      await _syncRunner.runNow();
    } catch (e, s) {
      // The scheduled cycle catches up anyway; this only saves the wait.
      _logger.fine('Sync around clearing the call history failed', e, s);
    }
  }
}
