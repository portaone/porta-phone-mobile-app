// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_sessions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserSessionList _$UserSessionListFromJson(Map<String, dynamic> json) =>
    UserSessionList(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => UserSession.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      autoTerminate: json['auto_terminate'] == null
          ? null
          : UserSessionsAutoTerminate.fromJson(
              json['auto_terminate'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$UserSessionListToJson(UserSessionList instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'auto_terminate': instance.autoTerminate?.toJson(),
    };

UserSessionsAutoTerminate _$UserSessionsAutoTerminateFromJson(
  Map<String, dynamic> json,
) => UserSessionsAutoTerminate(
  inactivityTimeoutDays: (json['inactivity_timeout_days'] as num?)?.toInt(),
  installationMaxDays: (json['installation_max_days'] as num?)?.toInt(),
);

Map<String, dynamic> _$UserSessionsAutoTerminateToJson(
  UserSessionsAutoTerminate instance,
) => <String, dynamic>{
  'inactivity_timeout_days': instance.inactivityTimeoutDays,
  'installation_max_days': instance.installationMaxDays,
};
