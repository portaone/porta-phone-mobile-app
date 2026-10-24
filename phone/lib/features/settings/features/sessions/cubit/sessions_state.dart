part of 'sessions_cubit.dart';

class SessionsState extends Equatable {
  SessionsState({
    this.sessions = const [],
    this.autoTerminate,
    this.loading = false,
    this.revoking = const {},
    this.failed = false,
    this.savingAutoTerminate = false,
  });

  final List<ActiveSession> sessions;

  /// When idle sessions end, as the core last said; null where it does not
  /// end them or has not been asked yet.
  final SessionAutoTerminate? autoTerminate;

  /// The session this device is signed in with; null when the core lists none
  /// as current, as after this device was signed out from another one.
  late final ActiveSession? currentSession = sessions.firstWhereOrNull((session) => session.current);

  late final List<ActiveSession> otherSessions = sessions.where((session) => !session.current).toList();

  /// True while the list is being fetched.
  final bool loading;

  /// Identifiers of the sessions whose revoke request is in flight.
  final Set<String> revoking;

  /// True when the last fetch failed; the sessions already loaded are kept.
  final bool failed;

  /// True while a new period for idle sessions is on its way to the core.
  final bool savingAutoTerminate;

  bool get hasOtherSessions => sessions.any((session) => !session.current);

  bool isRevoking(String sessionId) => revoking.contains(sessionId);

  @override
  List<Object?> get props => [sessions, autoTerminate, loading, revoking, failed, savingAutoTerminate];

  @override
  bool get stringify => true;

  SessionsState copyWith({
    List<ActiveSession>? sessions,
    SessionAutoTerminate? Function()? autoTerminate,
    bool? loading,
    Set<String>? revoking,
    bool? failed,
    bool? savingAutoTerminate,
  }) {
    return SessionsState(
      sessions: sessions ?? this.sessions,
      autoTerminate: autoTerminate != null ? autoTerminate() : this.autoTerminate,
      loading: loading ?? this.loading,
      revoking: revoking ?? this.revoking,
      failed: failed ?? this.failed,
      savingAutoTerminate: savingAutoTerminate ?? this.savingAutoTerminate,
    );
  }
}
