import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_session.dart';

part 'user_sessions.freezed.dart';

part 'user_sessions.g.dart';

/// `GET /user/sessions`: the user's active sessions, and when idle ones end.
@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserSessionList with _$UserSessionList {
  const UserSessionList({this.items = const [], this.autoTerminate});

  @override
  final List<UserSession> items;

  /// Absent from a core without idle-session cleanup.
  @override
  final UserSessionsAutoTerminate? autoTerminate;

  factory UserSessionList.fromJson(Map<String, Object?> json) => _$UserSessionListFromJson(json);

  Map<String, Object?> toJson() => _$UserSessionListToJson(this);
}

/// When the core ends the user's idle sessions, as `auto_terminate` of
/// `GET /user/sessions` and the body of `/user/sessions/settings`.
@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserSessionsAutoTerminate with _$UserSessionsAutoTerminate {
  const UserSessionsAutoTerminate({this.inactivityTimeoutDays, this.installationMaxDays});

  /// Idle days after which the user's sessions end - the shorter of the user's
  /// own choice and [installationMaxDays]. Null when sessions are never ended.
  @override
  final int? inactivityTimeoutDays;

  /// The installation's own timeout, set by its administrator; a user may only
  /// choose a shorter one. Null when the installation sets none.
  @override
  final int? installationMaxDays;

  factory UserSessionsAutoTerminate.fromJson(Map<String, Object?> json) => _$UserSessionsAutoTerminateFromJson(json);

  Map<String, Object?> toJson() => _$UserSessionsAutoTerminateToJson(this);
}
