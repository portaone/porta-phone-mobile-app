// The platform side of a screen share. On Android: the consent and the capture through
// flutter_webrtc, the foreground service and the ends outside the app through callkeep. On iOS: the
// capture through flutter_webrtc's broadcast extension mode, with the screen share extension of the
// app (ios/ScreenShare) saying when the broadcast starts and stops (screen_broadcast.dart). Built
// once for the process by bootstrap and handed to every CallBloc for its ScreenShare
// (screen_share.dart); tests hand the bloc a fake ScreenCapturer.
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/common/disposable.dart';

import 'screen_broadcast.dart';
import 'screen_share.dart';

/// Opens a display capture; `navigator.mediaDevices.getDisplayMedia` outside tests.
typedef DisplayMediaOpener = Future<MediaStream> Function(Map<String, dynamic> constraints);

/// [ScreenCapturer] on Android, and on iOS in a build with the screen share extension; elsewhere
/// [isSupported] is `false` and nothing is asked of it.
///
/// Android: the order is the one Android 14 demands: the consent ([Helper.requestCapturePermission]),
/// the `mediaProjection` foreground service callkeep runs, then the capture. The WebRTC plugin keeps
/// the consent it got and `getDisplayMedia` uses it without asking again; asking again before
/// every share replaces it, as Android 14 lets one consent serve one capture only.
///
/// iOS: the whole screen goes out through the broadcast upload extension, as an app may record only
/// itself otherwise. `getDisplayMedia` with the device `broadcast` opens the socket the extension
/// writes to and shows the system picker; the picker is the consent, and there is no service. The
/// capture counts once the extension says the broadcast started; a picker the person dismissed says
/// nothing, so the capture gives up after [broadcastStartTimeout]. The app stopping the capture
/// closes the socket, and the extension then ends the broadcast; the broadcast ending otherwise -
/// the red status bar or Control Center - is an end outside the app.
///
/// One for the process: the plugin reports the end of a capture to one delegate, and a call bloc
/// made again for the same sign-in listens to the same capturer as the one it replaces.
class DefaultScreenCapturer implements ScreenCapturer, CallkeepScreenShareDelegate, Disposable {
  DefaultScreenCapturer({
    CallkeepScreenShare? service,
    ScreenBroadcast? broadcast,
    DisplayMediaOpener? displayMedia,
    this.broadcastStartTimeout = const Duration(seconds: 30),
  }) : _service = service ?? AndroidCallkeepUtils.screenShare,
       _broadcast = broadcast,
       _displayMedia = displayMedia ?? navigator.mediaDevices.getDisplayMedia {
    if (_isAndroid) _service.setDelegate(this);
    if (_isIos) _broadcastEvents = broadcast!.events.listen(_onBroadcastEvent);
  }

  final CallkeepScreenShare _service;
  final ScreenBroadcast? _broadcast;
  final DisplayMediaOpener _displayMedia;
  final _endedOutside = StreamController<void>.broadcast();
  StreamSubscription<ScreenBroadcastEvent>? _broadcastEvents;

  /// How long the iOS capture waits for the person to start the broadcast in the system picker.
  final Duration broadcastStartTimeout;

  /// The iOS capture waiting for the extension to start; completed with an error when it will not.
  Completer<void>? _broadcastStart;

  /// The iOS broadcast carries a capture of this app, so its stop is an end outside the app.
  bool _broadcasting = false;

  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// iOS with the screen share extension in the build ([ScreenBroadcast.ofThisBuild]).
  bool get _isIos => _broadcast != null && !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Android, and iOS in a build that carries the screen share extension.
  @override
  bool get isSupported => _isAndroid || _isIos;

  /// Android: the person picks the whole screen or, from Android 14, one app. A single app that
  /// the person leaves stops giving new frames, so the far end keeps its last picture until the
  /// person comes back to it. iOS: the system picker of the capture is the consent.
  @override
  Future<bool> requestConsent() => _isIos ? Future.value(true) : Helper.requestCapturePermission();

  @override
  Future<void> startService() => _isIos ? Future.value() : _service.start();

  /// iOS has no service; stopping it ends a capture still waiting for the broadcast, and makes the
  /// broadcast's coming stop the app's own rather than an end outside it.
  @override
  Future<void> stopService() {
    if (!_isIos) return _service.stop();
    _broadcasting = false;
    _broadcastStart?.completeError(StateError('the screen share was stopped before the broadcast started'));
    _broadcastStart = null;
    return Future.value();
  }

  @override
  Future<MediaStream> capture() {
    if (_isIos) return _captureBroadcast();
    return _displayMedia(<String, dynamic>{'audio': false, 'video': true});
  }

  Future<MediaStream> _captureBroadcast() async {
    final start = Completer<void>();
    // A stop may fail it before anything awaits it; that error is not an unhandled one.
    start.future.ignore();
    _broadcastStart = start;
    final MediaStream stream;
    try {
      stream = await _displayMedia(<String, dynamic>{
        'audio': false,
        'video': {'deviceId': 'broadcast'},
      });
    } catch (_) {
      if (identical(_broadcastStart, start)) _broadcastStart = null;
      rethrow;
    }
    try {
      await start.future.timeout(broadcastStartTimeout);
    } catch (_) {
      if (identical(_broadcastStart, start)) _broadcastStart = null;
      // Closes the socket: an extension that starts after all finds nobody and ends its broadcast.
      await _release(stream);
      rethrow;
    }
    _broadcasting = true;
    return stream;
  }

  void _onBroadcastEvent(ScreenBroadcastEvent event) {
    switch (event) {
      case ScreenBroadcastEvent.started:
        final start = _broadcastStart;
        _broadcastStart = null;
        if (start != null && !start.isCompleted) start.complete();
      case ScreenBroadcastEvent.stopped:
        final start = _broadcastStart;
        if (start != null) {
          _broadcastStart = null;
          if (!start.isCompleted) start.completeError(StateError('the broadcast stopped before it started'));
        } else if (_broadcasting) {
          _broadcasting = false;
          _notifyEndedOutside();
        }
    }
  }

  Future<void> _release(MediaStream stream) async {
    try {
      for (final track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
    } catch (_) {
      // The capture is being given up; a track that would not stop has nothing more to send.
    }
  }

  @override
  Stream<void> get endedOutside => _endedOutside.stream;

  @override
  void didEndScreenShare() => _notifyEndedOutside();

  void _notifyEndedOutside() {
    if (!_endedOutside.isClosed) _endedOutside.add(null);
  }

  @override
  Future<void> dispose() async {
    if (_isAndroid) _service.setDelegate(null);
    await _broadcastEvents?.cancel();
    await _endedOutside.close();
  }
}
