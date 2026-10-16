import 'package:api/api.dart'
    show SessionAutoTerminateLimitExceededException, SessionAutoTerminateNotSupportedException, WebtritApiClient;

import 'package:webtrit_phone/mappers/mappers.dart';
import 'package:webtrit_phone/models/models.dart';

abstract interface class SessionsRepository {
  /// Fetches the account's active sessions, the current one included, and
  /// when idle ones end.
  Future<SessionList> getSessions();

  /// Revokes the session with [sessionId], ending its SIP registration.
  Future<void> revokeSession(String sessionId);

  /// Sets after how many idle [days] the account's sessions end; null returns
  /// to the installation's period. Answers with what the core now holds.
  ///
  /// Throws [SessionAutoTerminateRefusedException] when the core refuses the
  /// period itself; any other failure is rethrown as it came.
  Future<SessionAutoTerminate> setInactivityTimeout(int? days);
}

class SessionsRepositoryApiImpl with ActiveSessionApiMapper implements SessionsRepository {
  SessionsRepositoryApiImpl(this._webtritApiClient, this._token);

  final WebtritApiClient _webtritApiClient;
  final String _token;

  @override
  Future<SessionList> getSessions() async {
    final list = await _webtritApiClient.getUserSessionList(_token);
    final autoTerminate = list.autoTerminate;
    return SessionList(
      sessions: list.items.map(activeSessionFromApi).toList(),
      autoTerminate: autoTerminate == null ? null : sessionAutoTerminateFromApi(autoTerminate),
    );
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    await _webtritApiClient.deleteUserSession(_token, sessionId);
  }

  @override
  Future<SessionAutoTerminate> setInactivityTimeout(int? days) async {
    try {
      final result = await _webtritApiClient.updateUserSessionsSettings(_token, inactivityTimeoutDays: days);
      return sessionAutoTerminateFromApi(result);
    } on SessionAutoTerminateLimitExceededException {
      throw const SessionAutoTerminateRefusedException(SessionAutoTerminateRefusal.exceedsInstallationLimit);
    } on SessionAutoTerminateNotSupportedException {
      throw const SessionAutoTerminateRefusedException(SessionAutoTerminateRefusal.notSupported);
    }
  }
}
