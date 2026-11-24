import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import 'package:webtrit_callkeep_platform_interface/webtrit_callkeep_platform_interface.dart';

/// Runs the foreground service a screen capture needs during a call, and says when the capture
/// ended outside the app.
///
/// Since Android 14 an app may capture the screen only while it runs a foreground service of the
/// `mediaProjection` type, and the system starts one only after the person has granted the
/// capture. So the order is: the consent, [start], the capture; and [stop] once the capture is
/// released. This is an Android-only feature; elsewhere every call does nothing.
class CallkeepScreenShare {
  /// The singleton constructor of [CallkeepScreenShare].
  factory CallkeepScreenShare() => _instance;

  CallkeepScreenShare._();

  static final _instance = CallkeepScreenShare._();

  /// The [WebtritCallkeepPlatform] instance used to perform platform specific operations.
  static WebtritCallkeepPlatform get platform => WebtritCallkeepPlatform.instance;

  static bool get _supported => !kIsWeb && Platform.isAndroid;

  /// Puts the service in the foreground. Completes once it is there; throws when the system
  /// refused it, and then the capture must not start.
  Future<void> start() {
    if (!_supported) return Future.value();
    return platform.startScreenShareService();
  }

  /// Stops the service; nothing when it does not run. Safe after a [start] that threw: a service
  /// still on its way to the foreground stops itself once it is there.
  Future<void> stop() {
    if (!_supported) return Future.value();
    return platform.stopScreenShareService();
  }

  /// Sets the delegate told when the capture ends outside the app - the Stop of the service's
  /// notification, or the system ending the capture - or clears it with `null`.
  void setDelegate(CallkeepScreenShareDelegate? delegate) {
    if (!_supported) return;
    platform.setScreenShareDelegate(delegate);
  }
}
