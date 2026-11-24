// The platform side of a screen share on Android: the consent and the capture through
// flutter_webrtc, the foreground service and the ends outside the app through callkeep. Built once
// for the process by bootstrap and handed to every CallBloc for its ScreenShare (screen_share.dart);
// tests hand the bloc a fake ScreenCapturer.
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/common/disposable.dart';

import 'screen_share.dart';

/// [ScreenCapturer] on Android; elsewhere [isSupported] is `false` and nothing is asked of it.
///
/// The order is the one Android 14 demands: the consent ([Helper.requestCapturePermission]), the
/// `mediaProjection` foreground service callkeep runs, then the capture. The WebRTC plugin keeps
/// the consent it got and `getDisplayMedia` uses it without asking again; asking again before
/// every share replaces it, as Android 14 lets one consent serve one capture only.
///
/// One for the process: the plugin reports the end of a capture to one delegate, and a call bloc
/// made again for the same sign-in listens to the same capturer as the one it replaces.
class DefaultScreenCapturer implements ScreenCapturer, CallkeepScreenShareDelegate, Disposable {
  DefaultScreenCapturer({CallkeepScreenShare? service}) : _service = service ?? AndroidCallkeepUtils.screenShare {
    if (isSupported) _service.setDelegate(this);
  }

  final CallkeepScreenShare _service;
  final _endedOutside = StreamController<void>.broadcast();

  /// The capture and the foreground service it needs are Android's.
  @override
  bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// The person picks the whole screen or, from Android 14, one app. A single app that the
  /// person leaves stops giving new frames, so the far end keeps its last picture until the
  /// person comes back to it.
  @override
  Future<bool> requestConsent() => Helper.requestCapturePermission();

  @override
  Future<void> startService() => _service.start();

  @override
  Future<void> stopService() => _service.stop();

  @override
  Future<MediaStream> capture() =>
      navigator.mediaDevices.getDisplayMedia(<String, dynamic>{'audio': false, 'video': true});

  @override
  Stream<void> get endedOutside => _endedOutside.stream;

  @override
  void didEndScreenShare() {
    if (!_endedOutside.isClosed) _endedOutside.add(null);
  }

  @override
  Future<void> dispose() async {
    if (isSupported) _service.setDelegate(null);
    await _endedOutside.close();
  }
}
