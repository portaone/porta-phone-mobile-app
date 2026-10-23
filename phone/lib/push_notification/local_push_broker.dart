import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:webtrit_phone/app/constants.dart';

import 'push_channel.dart';

/// This class is used to handle local notifications actions from global context
///
/// Routes the actions to the apropriate streams and holds them in a stream controller buffer
/// until it will be consumed by the apropriate app components when they are ready
class LocalPushsBroker {
  /// One channel per value of the `source` key the app puts in the payload of
  /// every local push it shows.
  static final _channels = {
    for (final source in [kLocalPushSourceMessaging, kLocalPushSourceSystemNotification])
      source: PushChannel<NotificationResponse>.buffered(),
  };

  /// Stream of messaging local notification actions
  /// e.g tap dismiss etc.
  /// The stream is broadcasted so it can be listened by multiple components
  static Stream<NotificationResponse> get messagingActions => _channels[kLocalPushSourceMessaging]!.stream;

  /// Stream of system local notification actions
  /// e.g tap dismiss etc.
  /// The stream is broadcasted so it can be listened by multiple components
  static Stream<NotificationResponse> get systemNotificationsActions =>
      _channels[kLocalPushSourceSystemNotification]!.stream;

  /// Handles the local notification action
  /// and routes it to the apropriate stream
  @pragma('vm:entry-point')
  static Future handleActionReceived(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null) return;
    _channels[json.decode(payload)['source']]?.add(response);
  }
}
