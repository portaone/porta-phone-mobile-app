import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/latest_attempt.dart';

part 'sessions_state.dart';

final _logger = Logger('SessionsCubit');

/// How a change of when idle sessions end went.
enum SessionAutoTerminateSaveResult {
  saved,

  /// The installation's limit is now shorter than the period chosen.
  exceedsInstallationLimit,

  /// The core no longer lets the user choose.
  notSupported,

  /// The core could not be asked or could not tell; the period stays as it was.
  failed,
}

class SessionsCubit extends Cubit<SessionsState> {
  SessionsCubit(this._sessionsRepository) : super(SessionsState());

  final SessionsRepository _sessionsRepository;

  final _saves = LatestAttempt();
  final _autoTerminateUpdates = LatestAttempt();

  /// The number of the latest save of the period, taken by [setInactivityTimeout] before it
  /// awaits anything, so it can be read right after the call. A "try again" offered for a failed
  /// save holds it and stands down once a newer save has begun: it would undo what the user
  /// chose since.
  int get latestSave => _saves.latest;

  /// Whether no save of the period has begun since [save].
  bool isLatestSave(int save) => _saves.isLatest(save);

  /// A request may outlive the screen: a save goes on after its sheet is dragged
  /// away and the user leaves Settings, which closes this cubit. Its answer then
  /// has nowhere to go.
  @override
  void emit(SessionsState state) {
    if (isClosed) return;
    super.emit(state);
  }

  Future<void> fetch() async => _fetch();

  Future<bool> _fetch() async {
    final autoTerminateUpdate = _autoTerminateUpdates.begin();
    emit(state.copyWith(loading: true, failed: false));
    try {
      final list = await _sessionsRepository.getSessions();
      emit(
        state.copyWith(
          sessions: list.sessions,
          autoTerminate: _autoTerminateUpdates.isLatest(autoTerminateUpdate) ? () => list.autoTerminate : null,
          loading: false,
        ),
      );
      return true;
    } catch (e, stackTrace) {
      _logger.warning('fetch', e, stackTrace);
      emit(state.copyWith(loading: false, failed: true));
      return false;
    }
  }

  /// Revokes [sessionId] and drops it from the list; returns whether it worked.
  Future<bool> revoke(String sessionId) async {
    emit(state.copyWith(revoking: {...state.revoking, sessionId}));
    final succeeded = await _revoke(sessionId);
    emit(state.copyWith(revoking: state.revoking.where((id) => id != sessionId).toSet()));
    return succeeded;
  }

  /// Revokes every session but the current one; returns false if any of them failed.
  ///
  /// The core has no bulk endpoint, so the sessions are revoked one by one and
  /// each successful one leaves the list on its own - a partial failure still
  /// shows what was actually revoked.
  Future<bool> revokeAllOthers() async {
    final targets = state.sessions.where((session) => !session.current).map((session) => session.id).toList();
    emit(state.copyWith(revoking: {...state.revoking, ...targets}));

    var allSucceeded = true;
    for (final sessionId in targets) {
      allSucceeded &= await _revoke(sessionId);
    }

    emit(state.copyWith(revoking: state.revoking.where((id) => !targets.contains(id)).toSet()));
    return allSucceeded;
  }

  /// Sets after how many idle [days] the account's sessions end, null being the
  /// installation's period.
  ///
  /// Nothing changes on screen until the core has answered: what it answers is
  /// what is shown. A refusal of the period itself reloads the screen, since it
  /// means the limit or the capability changed since it was read.
  Future<SessionAutoTerminateSaveResult> setInactivityTimeout(int? days) async {
    _saves.begin();
    _autoTerminateUpdates.begin();
    emit(state.copyWith(savingAutoTerminate: true));
    try {
      final saved = await _sessionsRepository.setInactivityTimeout(days);
      emit(state.copyWith(autoTerminate: () => saved, savingAutoTerminate: false));
      return SessionAutoTerminateSaveResult.saved;
    } on SessionAutoTerminateRefusedException catch (e) {
      _logger.warning('setInactivityTimeout $days refused: ${e.reason}');
      emit(state.copyWith(savingAutoTerminate: false));
      if (!isClosed && !await _fetch()) return SessionAutoTerminateSaveResult.failed;
      return switch (e.reason) {
        SessionAutoTerminateRefusal.exceedsInstallationLimit => SessionAutoTerminateSaveResult.exceedsInstallationLimit,
        SessionAutoTerminateRefusal.notSupported => SessionAutoTerminateSaveResult.notSupported,
      };
    } catch (e, stackTrace) {
      _logger.warning('setInactivityTimeout $days', e, stackTrace);
      emit(state.copyWith(savingAutoTerminate: false));
      return SessionAutoTerminateSaveResult.failed;
    }
  }

  Future<bool> _revoke(String sessionId) async {
    try {
      await _sessionsRepository.revokeSession(sessionId);
      emit(state.copyWith(sessions: state.sessions.where((session) => session.id != sessionId).toList()));
      return true;
    } catch (e, stackTrace) {
      _logger.warning('revoke $sessionId', e, stackTrace);
      return false;
    }
  }
}
