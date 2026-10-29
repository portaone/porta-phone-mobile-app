part of 'session_status_cubit.dart';

@freezed
class SessionStatusState with _$SessionStatusState {
  const SessionStatusState({
    this.status = const SessionStatus(signalingStatus: CallStatus.inProgress),
    this.issues = const [],
  });

  final SessionStatus status;

  /// Side issues independent of the primary signaling [status] (e.g. limited
  /// standalone call mode). Drives the avatar indicator and account summary.
  final List<SessionIssue> issues;

  bool get hasIssues => issues.isNotEmpty;

  /// The most severe issue (ties resolved by first occurrence), or null.
  SessionIssue? get topIssue =>
      issues.isEmpty ? null : issues.reduce((a, b) => b.severity.index > a.severity.index ? b : a);
}
