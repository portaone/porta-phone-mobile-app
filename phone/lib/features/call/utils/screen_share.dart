// The screen share of an ordinary call: the person's consent, the foreground service Android asks
// of a screen capture, the capture, and the call's video sender moved from the camera to the
// screen and back. Used by CallBloc, which decides when a share may start and when it has to stop
// and carries the steps that touch the peer connection in its mutation queue; the platform steps
// are behind ScreenCapturer (DefaultScreenCapturer in screen_capturer.dart, built by bootstrap).
//
// Steps: begin (an attempt), capture (consent, service, capture - outside the bloc's queues, the
// consent is a system dialog), attach (the screen onto the call's video sender, the camera let
// go), and stop, which puts the camera back and releases the capture and the service. The far
// end's answer to the offer that gave a call video for the share is read with videoAnswer, a
// refused one with videoOffered. Every change of where a share stands is reported to onChanged,
// which the bloc maps into its state: this is the one place a share's status is kept.
import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/extensions/extensions.dart';

import '../models/screen_share_status.dart';
import 'user_media_builder.dart';

/// Why a screen share stops; the bloc tells the person about the ones that are not their own.
enum ScreenShareStopReason {
  /// The person stopped it in the app.
  user,

  /// It ended outside the app: the notification's Stop, the system ending the capture.
  endedOutside,

  /// The call can no longer share: held, merged into a room, ending or gone.
  callChanged,

  /// The far end refused the video the share made the call carry.
  videoRefused,
}

/// What [ScreenShare.capture] came to.
enum ScreenShareCaptureResult {
  captured,

  /// The person refused the consent; nothing to say.
  refused,

  /// The consent, the service or the capture failed; the person is told.
  failed,

  /// The share was stopped meanwhile, whatever then failed.
  cancelled,
}

/// What [ScreenShare.attach] came to.
enum ScreenShareAttachResult {
  /// The screen is on the call's video sender.
  attached,

  /// The call added a video sender for it: the call is renegotiated, and the far end may still
  /// refuse the video ([ScreenShare.videoAnswer]).
  attachedWithNewVideo,

  /// The share was stopped meanwhile.
  cancelled,

  /// The peer connection refused the track.
  failed,
}

/// Where the far end stands on the video line a share added to a call.
enum ScreenShareVideoAnswer {
  /// No answer covers the line yet: the answer that came was to an offer made before it.
  pending,

  /// The line sends: the screen goes out. Also for a share that waits for no answer.
  sends,

  /// The answer refused the line or left it unable to send.
  refused,
}

/// What [ScreenShare.stop] did to a share it found.
class ScreenShareStopped {
  const ScreenShareStopped({required this.attached, required this.cameraLost});

  /// The screen had reached the call's video sender.
  final bool attached;

  /// The camera the call had before the share could not be opened again.
  final bool cameraLost;
}

/// The platform side of a screen capture.
abstract interface class ScreenCapturer {
  /// Whether this platform can capture the screen in a call at all.
  bool get isSupported;

  /// Asks the person to let the app capture the screen; whether they did.
  Future<bool> requestConsent();

  /// Starts the foreground service a capture needs; throws when the system refused it.
  Future<void> startService();

  /// Stops that service; safe after a [startService] that threw.
  Future<void> stopService();

  /// Captures the screen; a stream with one video track. Called after [startService].
  Future<MediaStream> capture();

  /// Fires when the capture ended outside the app.
  Stream<void> get endedOutside;
}

/// The camera a share took off the call, to be put back by the stop.
class _Camera {
  _Camera(this.stream, {required this.enabled});

  /// The call's local stream the camera was taken from.
  final MediaStream stream;

  /// Whether it was on or soft-muted.
  final bool enabled;
}

class _Share {
  _Share(this.attempt);

  final Object attempt;
  ScreenShareStatus status = ScreenShareStatus.starting;
  bool serviceStarted = false;
  MediaStream? stream;
  RTCRtpSender? sender;

  /// What the sender carried before the screen when it was not the call's own camera.
  MediaStreamTrack? previousTrack;

  /// The call's camera, let go while the screen is out.
  _Camera? camera;

  /// The far end has not yet answered for the video sender this share added.
  bool awaitsVideo = false;

  /// A stop has been asked for and not yet run.
  bool stopping = false;

  MediaStreamTrack? get track => stream?.getVideoTracks().firstOrNull;
}

/// The bookkeeping and the steps of a screen share, one call at a time: the screen is one, and
/// Android runs one capture.
///
/// It knows nothing of the call's state or of signaling. The bloc asks whether a share may start
/// and stop, carries the peer connection steps in its queue and maps [statusOf] into the state on
/// every [onChanged].
class ScreenShare {
  ScreenShare({
    required ScreenCapturer capturer,
    required UserMediaBuilder userMedia,
    required void Function(String callId) onEndedOutside,
    required void Function(String callId) onChanged,
  }) : _capturer = capturer,
       _userMedia = userMedia,
       _onChanged = onChanged {
    _endedSubscription = capturer.endedOutside.listen((_) {
      for (final callId in _shares.keys.toList()) {
        onEndedOutside(callId);
      }
    });
  }

  static final _logger = Logger('ScreenShare');

  final ScreenCapturer _capturer;
  final UserMediaBuilder _userMedia;
  final void Function(String callId) _onChanged;
  late final StreamSubscription<void> _endedSubscription;
  final Map<String, _Share> _shares = {};
  bool _disposed = false;

  /// Whether this platform can share the screen at all.
  bool get isSupported => _capturer.isSupported;

  /// The calls with a share, starting or running.
  Iterable<String> get callIds => _shares.keys;

  ScreenShareStatus? statusOf(String callId) => _shares[callId]?.status;

  /// Starts a share of [callId] and returns its attempt, or `null` while any share runs.
  Object? begin(String callId) {
    if (_shares.isNotEmpty) return null;
    final attempt = Object();
    _shares[callId] = _Share(attempt);
    _changed(callId);
    return attempt;
  }

  /// Whether [attempt] is the share of [callId] and no stop has been asked of it.
  bool _isLive(String callId, Object attempt) {
    final share = _shares[callId];
    return share != null && identical(share.attempt, attempt) && !share.stopping;
  }

  bool _isCurrent(String callId, Object attempt) => identical(_shares[callId]?.attempt, attempt);

  /// The consent, the service and the capture of [attempt]. Whatever it ends in other than
  /// [ScreenShareCaptureResult.captured] leaves no share, no service and no capture behind. A
  /// failure of an attempt stopped meanwhile is [ScreenShareCaptureResult.cancelled]: the person
  /// stopped it, or the call took it away, and nothing went wrong that they should hear of.
  Future<ScreenShareCaptureResult> capture(String callId, Object attempt) async {
    final bool consent;
    try {
      consent = await _capturer.requestConsent();
    } catch (e) {
      _logger.warning('capture: the consent of $callId failed: $e');
      return _fail(callId, attempt);
    }
    if (!_isCurrent(callId, attempt)) return ScreenShareCaptureResult.cancelled;
    if (!consent) {
      _forget(callId, attempt);
      return ScreenShareCaptureResult.refused;
    }

    // The service first: Android 14 refuses a capture without it, and refuses the service itself
    // before the consent.
    try {
      await _capturer.startService();
    } catch (e) {
      _logger.warning('capture: the screen share service of $callId was refused: $e');
      // The start may have failed only on this side, by its timeout, with the service coming up
      // after: asked to stop, it goes once it is up.
      return _fail(callId, attempt, stopService: true);
    }
    final share = _shares[callId];
    if (share == null || !identical(share.attempt, attempt)) {
      await _stopServiceIfUnused();
      return ScreenShareCaptureResult.cancelled;
    }
    share.serviceStarted = true;

    final MediaStream stream;
    try {
      stream = await _capturer.capture();
    } catch (e) {
      _logger.warning('capture: the screen of $callId could not be captured: $e');
      return _fail(callId, attempt, stopService: true);
    }
    if (!_isCurrent(callId, attempt)) {
      // Stopped while the capture started: the stop found nothing to release yet.
      await _release(stream);
      await _stopServiceIfUnused();
      return ScreenShareCaptureResult.cancelled;
    }
    share.stream = stream;
    return ScreenShareCaptureResult.captured;
  }

  /// Ends [attempt] after a step of [capture] failed: a share stopped meanwhile was cancelled, not
  /// failed - the stop itself may be what failed the step, by taking the service away from it.
  Future<ScreenShareCaptureResult> _fail(String callId, Object attempt, {bool stopService = false}) async {
    final live = _isLive(callId, attempt);
    _forget(callId, attempt);
    if (stopService) await _stopServiceIfUnused();
    return live ? ScreenShareCaptureResult.failed : ScreenShareCaptureResult.cancelled;
  }

  /// Puts the captured screen of [attempt] on the call's video sender; without a video sender,
  /// adds one, which renegotiates the call.
  ///
  /// The call's camera, on or soft-muted, is let go while the screen is out ([UserMediaBuilder.
  /// releaseVideoTrack]): kept open it would capture for nobody - its indicator on, the battery
  /// spent - behind the tile that stands in for its preview. [stop] opens it again.
  Future<ScreenShareAttachResult> attach(
    String callId,
    Object attempt, {
    required RTCPeerConnection peerConnection,
    required MediaStream? localStream,
  }) async {
    final share = _shares[callId];
    final track = share?.track;
    if (share == null || !identical(share.attempt, attempt) || track == null) {
      return ScreenShareAttachResult.cancelled;
    }
    try {
      final sender = await peerConnection.videoSender();
      if (!_isCurrent(callId, attempt)) return ScreenShareAttachResult.cancelled;
      if (sender != null) {
        final previous = sender.track;
        share.sender = sender;
        share.previousTrack = previous;
        await sender.replaceTrack(track);
        if (previous != null && localStream != null && _carries(localStream, previous)) {
          share.previousTrack = null;
          share.camera = _Camera(localStream, enabled: previous.enabled);
          await _releaseCamera(callId, localStream);
        }
      } else {
        share.sender = await peerConnection.addTrack(track, localStream ?? share.stream!);
        share.awaitsVideo = true;
      }
    } catch (e) {
      _logger.warning('attach: the screen of $callId did not go on its connection: $e');
      return ScreenShareAttachResult.failed;
    }
    share.status = ScreenShareStatus.sharing;
    _changed(callId);
    return share.awaitsVideo ? ScreenShareAttachResult.attachedWithNewVideo : ScreenShareAttachResult.attached;
  }

  static bool _carries(MediaStream stream, MediaStreamTrack track) =>
      stream.getVideoTracks().any((candidate) => candidate.id == track.id);

  Future<void> _releaseCamera(String callId, MediaStream localStream) async {
    try {
      await _userMedia.releaseVideoTrack(localStream);
    } catch (e) {
      _logger.warning('attach: the camera of $callId was not let go: $e');
    }
  }

  /// Marks the share of [callId] as being stopped; `false` when there is none or a stop is
  /// already on its way, so a stop is asked for once.
  bool markStopping(String callId) {
    final share = _shares[callId];
    if (share == null || share.stopping) return false;
    share.stopping = true;
    return true;
  }

  /// Whether the far end has yet to answer for the video sender the share of [callId] added.
  bool awaitsVideo(String callId) => _shares[callId]?.awaitsVideo ?? false;

  /// What the far end's answers so far say about the video line the share of [callId] added.
  ///
  /// The answer that came may be to an offer made before the line: an offer already out when the
  /// share added its sender (an ICE restart, a hold, a codec move) leaves the line out, and its
  /// answer says nothing of it. Such a line has no negotiated direction yet, and the share waits
  /// for the answer to its own offer, which the connection asks for once the earlier one is done.
  Future<ScreenShareVideoAnswer> videoAnswer(String callId, RTCPeerConnection peerConnection) async {
    final share = _shares[callId];
    if (share == null || !share.awaitsVideo) return ScreenShareVideoAnswer.sends;
    final transceiver = await _transceiverOf(share, peerConnection);
    if (transceiver == null) return ScreenShareVideoAnswer.pending;
    final direction = await transceiver.getCurrentDirection();
    if (direction == null) return ScreenShareVideoAnswer.pending;
    final sends = direction == TransceiverDirection.SendRecv || direction == TransceiverDirection.SendOnly;
    if (sends && identical(_shares[callId], share)) share.awaitsVideo = false;
    return sends ? ScreenShareVideoAnswer.sends : ScreenShareVideoAnswer.refused;
  }

  /// Whether the offer out now carries the video line the share of [callId] added and waits for
  /// its answer: the line has a place (`mid`) in an offer and no negotiated direction. A refusal
  /// of an offer without the line says nothing of the share.
  Future<bool> videoOffered(String callId, RTCPeerConnection peerConnection) async {
    final share = _shares[callId];
    if (share == null || !share.awaitsVideo) return false;
    final transceiver = await _transceiverOf(share, peerConnection);
    if (transceiver == null || transceiver.mid.isEmpty) return false;
    return await transceiver.getCurrentDirection() == null;
  }

  Future<RTCRtpTransceiver?> _transceiverOf(_Share share, RTCPeerConnection peerConnection) async {
    final track = share.track;
    if (track == null) return null;
    final transceivers = await peerConnection.getTransceivers();
    return transceivers.firstWhereOrNull((t) => t.sender.track?.id == track.id);
  }

  /// Stops the share of [callId]: the sender gets back what it carried before - the call's camera,
  /// opened again with [frontCamera], or nothing - the capture is released and the service
  /// stopped. With [attempt], only that attempt is stopped. `null` when there was no share.
  ///
  /// The camera is opened again only on a usable [peerConnection]: a call going away does not get
  /// a camera back. The change is reported once the sender has its camera back, so that what the
  /// screen shows next - the camera's preview - finds the camera there.
  Future<ScreenShareStopped?> stop(
    String callId, {
    RTCPeerConnection? peerConnection,
    Object? attempt,
    bool? frontCamera,
  }) async {
    final share = _shares[callId];
    if (share == null || (attempt != null && !identical(share.attempt, attempt))) return null;
    _shares.remove(callId);
    final attached = share.status == ScreenShareStatus.sharing;
    var cameraLost = false;
    final sender = share.sender;
    if (sender != null && peerConnection != null && peerConnection.isUsable) {
      var back = share.previousTrack;
      if (share.camera case final camera?) {
        back = await _reopenCamera(callId, camera, frontCamera: frontCamera);
        cameraLost = back == null;
      }
      try {
        await sender.replaceTrack(back);
      } catch (e) {
        _logger.warning('stop: the video sender of $callId was not given back: $e');
      }
    }
    _changed(callId);
    final stream = share.stream;
    if (stream != null) await _release(stream);
    if (share.serviceStarted) await _stopServiceIfUnused();
    return ScreenShareStopped(attached: attached, cameraLost: cameraLost);
  }

  Future<MediaStreamTrack?> _reopenCamera(String callId, _Camera camera, {bool? frontCamera}) async {
    try {
      final track = await _userMedia.ensureVideoTrack(camera.stream, frontCamera: frontCamera);
      track?.enabled = camera.enabled;
      return track;
    } catch (e) {
      _logger.warning('stop: the camera of $callId did not open again: $e');
      return null;
    }
  }

  /// Stops every share without touching a connection or telling anyone: the owner is going away.
  Future<void> dispose() async {
    _disposed = true;
    await _endedSubscription.cancel();
    for (final callId in _shares.keys.toList()) {
      await stop(callId);
    }
  }

  void _changed(String callId) {
    if (!_disposed) _onChanged(callId);
  }

  void _forget(String callId, Object attempt) {
    if (!_isCurrent(callId, attempt)) return;
    _shares.remove(callId);
    _changed(callId);
  }

  Future<void> _release(MediaStream stream) async {
    try {
      for (final track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
    } catch (e) {
      _logger.warning('the screen capture was not released: $e');
    }
  }

  /// Stops the service unless a newer share has started it again meanwhile: an attempt that was
  /// stopped while it waited must not take the service from the one that followed it.
  Future<void> _stopServiceIfUnused() async {
    if (_shares.values.any((share) => share.serviceStarted)) return;
    await _stopService();
  }

  Future<void> _stopService() async {
    try {
      await _capturer.stopService();
    } catch (e) {
      _logger.warning('the screen share service did not stop: $e');
    }
  }
}
