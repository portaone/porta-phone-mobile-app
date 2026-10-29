import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:webtrit_callkeep_platform_interface/webtrit_callkeep_platform_interface.dart';

/// Configures the background push notification service on Android.
class BackgroundPushNotificationBootstrapService {
  /// Returns the singleton instance.
  factory BackgroundPushNotificationBootstrapService() => _instance;

  BackgroundPushNotificationBootstrapService._();

  static final _instance = BackgroundPushNotificationBootstrapService._();

  /// The [WebtritCallkeepPlatform] instance used to perform platform specific operations.
  static WebtritCallkeepPlatform get platform => WebtritCallkeepPlatform.instance;

  /// Initializes the callback used for syncing push notification status (Android only).
  Future<void> initializeCallback(CallKeepPushNotificationSyncStatusHandle onNotificationSync) {
    if (kIsWeb || !Platform.isAndroid) return Future.value();
    return platform.initializePushNotificationCallback(onNotificationSync);
  }

  /// Reports a new incoming call triggered by a push notification.
  ///
  /// Returns a [CallkeepIncomingCallError] if reporting fails.
  ///
  /// [offeredAt] is when the server offered the call: FCM `RemoteMessage.sentTime` for a push, the
  /// moment of receipt for an event the signaling socket delivered. A call offered after the app
  /// ended [callId] before presenting it is a new attempt of the id (a blind transfer repeated
  /// offers the same id again); an older or untimed one is a late copy and is refused.
  Future<CallkeepIncomingCallError?> reportNewIncomingCall(
    String callId,
    CallkeepHandle handle, {
    String? displayName,
    bool hasVideo = false,
    DateTime? offeredAt,
  }) {
    return platform.incomingCallPushNotificationService(callId, handle, displayName, hasVideo, offeredAt: offeredAt);
  }
}
