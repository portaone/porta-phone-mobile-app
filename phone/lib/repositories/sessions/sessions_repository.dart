import 'package:api/api.dart' show WebtritApiClient;

import 'package:webtrit_phone/mappers/mappers.dart';
import 'package:webtrit_phone/models/models.dart';

abstract interface class SessionsRepository {
  /// Fetches the account's active sessions, the current one included.
  Future<List<ActiveSession>> getSessions();

  /// Revokes the session with [sessionId], ending its SIP registration.
  Future<void> revokeSession(String sessionId);
}

class SessionsRepositoryApiImpl with ActiveSessionApiMapper implements SessionsRepository {
  SessionsRepositoryApiImpl(this._webtritApiClient, this._token);

  final WebtritApiClient _webtritApiClient;
  final String _token;

  @override
  Future<List<ActiveSession>> getSessions() async {
    final sessions = await _webtritApiClient.getUserSessions(_token);
    return sessions.map(activeSessionFromApi).toList();
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    await _webtritApiClient.deleteUserSession(_token, sessionId);
  }
}
