import 'package:freezed_annotation/freezed_annotation.dart';

part 'system_notification.freezed.dart';

part 'system_notification.g.dart';

enum SystemNotificationType { announcement, promotion, security, system }

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SystemNotification with _$SystemNotification {
  const SystemNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.seen,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.readAt,
    this.deletedAt,
  });

  final int id;

  final String title;

  final String content;

  final bool seen;

  final SystemNotificationType type;

  final DateTime createdAt;

  final DateTime updatedAt;

  final DateTime? readAt;

  /// Set on a notification the backend has deleted. Only the updates feed
  /// returns one, and only when asked to; its title and content are blank.
  final DateTime? deletedAt;

  factory SystemNotification.fromJson(Map<String, Object?> json) => _$SystemNotificationFromJson(json);

  Map<String, Object?> toJson() => _$SystemNotificationToJson(this);
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SystemNotificationResponce with _$SystemNotificationResponce {
  const SystemNotificationResponce({required this.items});

  final List<SystemNotification> items;

  factory SystemNotificationResponce.fromJson(Map<String, Object?> json) => _$SystemNotificationResponceFromJson(json);

  Map<String, Object?> toJson() => _$SystemNotificationResponceToJson(this);
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SystemNotificationsDeleteResponse with _$SystemNotificationsDeleteResponse {
  const SystemNotificationsDeleteResponse({required this.deletedIds});

  final List<int> deletedIds;

  factory SystemNotificationsDeleteResponse.fromJson(Map<String, Object?> json) =>
      _$SystemNotificationsDeleteResponseFromJson(json);

  Map<String, Object?> toJson() => _$SystemNotificationsDeleteResponseToJson(this);
}
