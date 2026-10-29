part of 'notifications_bloc.dart';

@freezed
class NotificationsState with _$NotificationsState {
  const NotificationsState({this.lastNotification});

  final Notification? lastNotification;
}
