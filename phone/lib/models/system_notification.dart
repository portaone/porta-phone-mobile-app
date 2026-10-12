import 'package:equatable/equatable.dart';

enum SystemNotificationType { announcement, promotion, security, system }

class SystemNotification extends Equatable {
  const SystemNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.seen,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final int id;
  final String title;
  final String content;
  final SystemNotificationType type;
  final bool seen;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// When the backend deleted it; null for a notification that exists.
  ///
  /// Only the updates of a sync carry a deleted notification. It is how a
  /// delete made on another device, or by the backend's retention, is heard of
  /// - and it is never stored: the store drops what arrives deleted.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  @override
  List<Object?> get props => [id, title, content, type, seen, createdAt, updatedAt, deletedAt];

  @override
  String toString() {
    return 'SystemNotification(id: $id, title: $title, content: $content, type: $type, seen: $seen, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt)';
  }

  SystemNotification copyWith({
    int? id,
    String? title,
    String? content,
    SystemNotificationType? type,
    bool? seen,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return SystemNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      seen: seen ?? this.seen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

extension SystemNotificationIterableExtension on Iterable<SystemNotification> {
  Iterable<SystemNotification> mergeWithUpdate(SystemNotification notification) {
    final isNew = !any((n) => n.id == notification.id);
    if (isNew) {
      return [notification, ...this];
    } else {
      return map((n) => n.id == notification.id ? notification : n);
    }
  }

  Iterable<SystemNotification> mergeWithRemove(int id) {
    return where((n) => n.id != id);
  }

  Iterable<SystemNotification> mergeWithHistory(Iterable<SystemNotification> history) {
    return [...this, ...history];
  }
}
