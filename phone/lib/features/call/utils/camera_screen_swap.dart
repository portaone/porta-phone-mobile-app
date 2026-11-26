// The one way a video sender moves between the camera and a shared screen: the screen goes on the
// sender and the camera is let go after it - never before, so the far end does not get an empty
// line in between - and back, the camera opened again first and put on the sender in the screen's
// place. Used by a call's screen share (CallSenderDestination in screen_share_destinations.dart)
// and by the room's video (ConferenceVideoSession); how a camera is let go and opened again is
// theirs, as a call's camera is a track of its own stream and the room's a stream of its own.
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';

final _logger = Logger('CameraScreenSwap');

/// Moves [sender] between the camera and a shared screen.
abstract final class CameraScreenSwap {
  /// Puts [screen] on [sender], then lets the camera go with [letCameraGo] - not when nothing of
  /// the camera was on it. Throws when the sender refuses the track; the camera is then kept.
  static Future<void> toScreen(
    RTCRtpSender sender,
    MediaStreamTrack screen, {
    Future<void> Function()? letCameraGo,
  }) async {
    await sender.replaceTrack(screen);
    if (letCameraGo == null) return;
    try {
      await letCameraGo();
    } catch (e) {
      _logger.warning('toScreen: the camera was not let go: $e');
    }
  }

  /// Opens the camera again with [openCamera] and puts it on [sender] in the screen's place, or
  /// puts [fallback] there without a camera to open - or when it does not open. Returns the camera
  /// that went on, `null` when none did.
  static Future<MediaStreamTrack?> toCamera(
    RTCRtpSender sender, {
    Future<MediaStreamTrack?> Function()? openCamera,
    MediaStreamTrack? fallback,
  }) async {
    MediaStreamTrack? camera;
    if (openCamera != null) {
      try {
        camera = await openCamera();
      } catch (e) {
        _logger.warning('toCamera: the camera did not open again: $e');
      }
    }
    try {
      await sender.replaceTrack(camera ?? fallback);
    } catch (e) {
      _logger.warning('toCamera: the video sender was not given back: $e');
    }
    return camera;
  }
}
