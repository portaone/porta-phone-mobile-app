import 'package:equatable/equatable.dart';

import 'active_session.dart';

/// A login the backend has accepted the credentials of and is holding back:
/// the account is signed in on as many devices as it is allowed.
///
/// It is finished by signing one of [sessions] out, with no password or code
/// asked for again.
class PendingLogin extends Equatable {
  const PendingLogin({required this.token, required this.tenantId, required this.sessions});

  /// Finishes the login together with the id of the session to sign out.
  final String token;

  /// The tenant the refused request was made in; finishing it is made there too.
  final String tenantId;

  /// The sessions of the account, any of which may be signed out.
  final List<ActiveSession> sessions;

  PendingLogin withoutSession(String sessionId) {
    return PendingLogin(
      token: token,
      tenantId: tenantId,
      sessions: [
        for (final session in sessions)
          if (session.id != sessionId) session,
      ],
    );
  }

  @override
  List<Object?> get props => [token, tenantId, sessions];

  // Not stringified: the token finishes a login and must not reach a log.
  @override
  bool get stringify => false;
}
