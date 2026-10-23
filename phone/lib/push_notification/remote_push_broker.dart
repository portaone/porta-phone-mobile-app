import 'dart:async';

import 'push_channel.dart';
import 'push_notifications.dart';

/// This class is used to handle remote push notifications from global context
///
/// Routes push to the apropriate streams and holds them in a stream controller buffer
/// until it will be consumed by the apropriate app components when they are ready
class RemotePushBroker {
  // Messaging remote push that open app
  static final _msgOpened = PushChannel<MessagePush>.buffered();

  // Messaging remote push that received while the app was in foreground
  static final _msgForeground = PushChannel<MessagePush>.buffered();

  // System remote push that open app
  static final _snOpened = PushChannel<SystemNotificationPush>.buffered();

  // System remote push that received while the app was in foreground
  static final _snForeground = PushChannel<SystemNotificationPush>.buffered();

  // Voicemail remote push that open app
  static final _vmOpened = PushChannel<VoicemailPush>.buffered();

  // Voicemail remote push that received while the app was in foreground. It only says to
  // show the push and read the mailbox now; replayed into a later session it would announce
  // a message that session has already read.
  static final _vmForeground = PushChannel<VoicemailPush>.unbuffered();

  static final _pendingCallForeground = PushChannel<PendingCallPush>.buffered();

  /// Stream of messaging remote push that opens app
  /// while the app was in terminated state when the notification is tapped
  ///
  /// The stream is broadcasted so it can be listened by multiple components
  static Stream<MessagePush> get messagingOpenedPushs => _msgOpened.stream;

  /// Stream of messaging remote push that received
  /// while the app was in foreground state when the notification is tapped
  ///
  /// The stream is broadcasted so it can be listened by multiple components
  static Stream<MessagePush> get messagingForegroundPushs => _msgForeground.stream;

  /// Stream of system remote push that opens app
  /// while the app was in terminated state when the notification is tapped
  ///
  /// The stream is broadcasted so it can be listened by multiple components
  static Stream<SystemNotificationPush> get systemNotificationsOpenedPushs => _snOpened.stream;

  /// Stream of system remote push that received
  /// while the app was in foreground state when the notification is tapped
  ///
  /// The stream is broadcasted so it can be listened by multiple components
  static Stream<SystemNotificationPush> get systemNotificationsForegroundPushs => _snForeground.stream;

  /// Stream of voicemail remote push that opens app
  /// while the app was in background or terminated state when the notification is tapped
  ///
  /// The stream is broadcasted so it can be listened by multiple components
  static Stream<VoicemailPush> get voicemailOpenedPushs => _vmOpened.stream;

  /// Stream of voicemail remote push that received
  /// while the app was in foreground state
  ///
  /// The stream is broadcasted so it can be listened by multiple components
  static Stream<VoicemailPush> get voicemailForegroundPushs => _vmForeground.stream;

  /// Stream of pending call push that was received while the app was in foreground.
  ///
  /// Signals that there is an incoming call waiting on the server.
  /// Consumers should use this only as a hint to trigger a signaling reconnect —
  /// the actual call arrives via the WebSocket handshake once signaling is up.
  static Stream<PendingCallPush> get pendingCallForegroundPushs => _pendingCallForeground.stream;

  /// Handles the remote notification that opens the app
  /// and routes it to the apropriate stream
  static void handleOpenedPush(AppRemotePush notification) {
    if (notification is MessagePush) _msgOpened.add(notification);
    if (notification is SystemNotificationPush) _snOpened.add(notification);
    if (notification is VoicemailPush) _vmOpened.add(notification);
  }

  /// Handles the remote notification that received while the app was in foreground
  /// and routes it to the apropriate stream
  static void handleForegroundPush(AppRemotePush notification) {
    if (notification is MessagePush) _msgForeground.add(notification);
    if (notification is SystemNotificationPush) _snForeground.add(notification);
    if (notification is VoicemailPush) _vmForeground.add(notification);
    if (notification is PendingCallPush) _pendingCallForeground.add(notification);
  }
}
