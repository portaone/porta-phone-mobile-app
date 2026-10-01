import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:webtrit_callkeep_platform_interface/webtrit_callkeep_platform_interface.dart';

/// Manages background push notification call events on Android.
class BackgroundPushNotificationService {
  /// Returns the singleton instance.
  factory BackgroundPushNotificationService() => _instance;

  BackgroundPushNotificationService._();

  static final _instance = BackgroundPushNotificationService._();

  /// The [WebtritCallkeepPlatform] instance used to perform platform specific operations.
  static WebtritCallkeepPlatform get platform => WebtritCallkeepPlatform.instance;

  /// Sets the delegate for handling background push notification events (Android only).
  void setBackgroundServiceDelegate(CallkeepBackgroundServiceDelegate? delegate) {
    if (kIsWeb || !Platform.isAndroid) return;
    platform.setBackgroundServiceDelegate(delegate);
  }

  /// Reports that the call [callId] ended (Android only): the server hung it up, nobody
  /// answered, or it was gone before this session could see it.
  ///
  /// Callkeep ends the call in Telecom, keeps the end so that a replay or a late push cannot
  /// present the call again, and does not ask this session to end the call a second time. Use
  /// [CallkeepEndCallReason.missedWhileConnecting] for a call the app never presented.
  ///
  /// Ends the call, not the session: [IncomingCallService] keeps running, so the session can
  /// still record the missed call and show its notification. The session finishes on its own:
  /// return from the callback, and the plugin stops the service.
  Future<void> reportEndCall(String callId, CallkeepEndCallReason reason) {
    if (kIsWeb || !Platform.isAndroid) return Future.value();
    return platform.reportEndCallBackgroundPushNotificationService(callId, reason);
  }

  /// Ends a background call by [callId] in Telecom as a server-side decline (Android only).
  ///
  /// Nothing else changes: the service and the session keep running, and the end is not
  /// remembered as reported, so the release that follows still reaches the session as
  /// `performEndCall`. For a call the server hung up use [reportEndCall].
  Future<dynamic> endCall(String callId) {
    if (kIsWeb || !Platform.isAndroid) return Future.value();
    return platform.endCallBackgroundPushNotificationService(callId);
  }

  /// Ends all background calls (Android only).
  ///
  /// Deprecated: use [releaseCall] with a specific callId instead.
  /// [endCalls] routes through a teardown path that does not stop
  /// [IncomingCallService], leaving the incoming call notification visible.
  @Deprecated('Use releaseCall(callId) instead')
  Future<dynamic> endCalls() {
    if (kIsWeb || !Platform.isAndroid) return Future.value();
    return platform.endCallsBackgroundPushNotificationService();
  }

  /// Terminates the PhoneConnection and stops IncomingCallService for [callId] (Android only).
  ///
  /// Use for a call the session cannot follow any more (signaling error, a call it never saw
  /// arrive). Sends a decline signal to the ConnectionService which destroys the
  /// PhoneConnection before stopping the service. A call that ended on the server is reported
  /// with [reportEndCall] instead, and the service stops on its own once the session's
  /// callback future completes.
  Future<dynamic> releaseCall(String callId) {
    if (kIsWeb || !Platform.isAndroid) return Future.value();
    return platform.releaseCallBackgroundPushNotificationService(callId);
  }

  /// Stops IncomingCallService for [callId] without terminating the PhoneConnection (Android only).
  ///
  /// The PhoneConnection stays alive so the Activity can adopt it via the
  /// CALL_ID_ALREADY_EXISTS_AND_ANSWERED path in reportNewIncomingCall. Not needed on the
  /// answered path any more: the service stops the same way on its own once the session's
  /// callback future completes.
  Future<dynamic> handoffCall(String callId) {
    if (kIsWeb || !Platform.isAndroid) return Future.value();
    return platform.handoffCallBackgroundPushNotificationService(callId);
  }
}
