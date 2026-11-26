// The iOS screen share extension as Dart sees it: whether this build carries it, and when a
// broadcast it runs starts and stops. The channel is the app's own (ScreenBroadcastChannel in
// ios/Runner), which relays the Darwin notifications the extension (ios/ScreenShare) posts.
// Asked once by bootstrap and handed to DefaultScreenCapturer (screen_capturer.dart); tests hand
// the capturer a fake.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:webtrit_phone/environment_config.dart';

/// What the screen share extension reports about its broadcast.
enum ScreenBroadcastEvent {
  /// The person started the broadcast and the extension reached the app's capture.
  started,

  /// The broadcast is over, whoever ended it.
  stopped,
}

/// The screen share extension of the iOS app.
class ScreenBroadcast {
  const ScreenBroadcast();

  static const _methods = MethodChannel('com.webtrit.phone/screen_broadcast');
  static const _events = EventChannel('com.webtrit.phone/screen_broadcast/events');

  /// The extension of this build, or `null` off iOS and in a brand build without it (the dart
  /// define [EnvironmentConfig.IOS_SCREEN_SHARE_APP_GROUP] left empty). A group named is not
  /// taken on trust: the native side still says whether the extension is in the bundle.
  static Future<ScreenBroadcast?> ofThisBuild() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return null;
    if (EnvironmentConfig.IOS_SCREEN_SHARE_APP_GROUP.isEmpty) return null;
    try {
      final available = await _methods.invokeMethod<bool>('isAvailable');
      return (available ?? false) ? const ScreenBroadcast() : null;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// The starts and stops of the extension's broadcast.
  Stream<ScreenBroadcastEvent> get events => _events.receiveBroadcastStream().map(
    (event) => event == 'started' ? ScreenBroadcastEvent.started : ScreenBroadcastEvent.stopped,
  );
}
