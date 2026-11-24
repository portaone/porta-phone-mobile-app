// The screen share there is - one at a time, as the screen is one and Android runs one capture: the
// person's consent, the foreground service Android asks of a screen capture, the capture, and the
// destination the screen goes to (screen_share_destinations.dart: a call's video sender, or a
// room's video). Used by CallBloc's coordinator (bloc/screen_share_coordinator.dart), which
// decides where a share goes, when it may start and when it has to stop, and carries the steps
// that touch a connection in the bloc's mutation queue; the platform steps are behind
// ScreenCapturer (DefaultScreenCapturer in screen_capturer.dart, built by bootstrap).
//
// Steps: begin (an attempt for a target), capture (consent, service, capture - outside the bloc's
// queues, the consent is a system dialog), attach (the screen handed to its destination), and
// stop, which has the destination take the screen off and put the camera back before the capture
// and the service are released. Every change of where the share stands is reported to onChanged,
// which the bloc maps into its state: this is the one place a share's status is kept.
import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';

import '../models/screen_share_status.dart';

/// Why a screen share stops; the bloc tells the person about the ones that are not their own.
enum ScreenShareStopReason {
  /// The person stopped it in the app.
  user,

  /// It ended outside the app: the notification's Stop, the system ending the capture.
  endedOutside,

  /// The call or the room can no longer share: held, merged into a room, parked, ending or gone.
  callChanged,

  /// The far end refused the video the share made the call carry.
  videoRefused,

  /// The room would not take the screen, or let it go for good.
  roomLost,
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
  /// The screen went to its destination.
  attached,

  /// The call added a video sender for it: the call is renegotiated, and the far end may still
  /// refuse the video (`CallSenderDestination.videoAnswer`).
  attachedWithNewVideo,

  /// The share was stopped meanwhile.
  cancelled,

  /// The destination refused the screen.
  failed,
}

/// What [ScreenShare.stop] did to a share it found.
class ScreenShareStopped {
  const ScreenShareStopped({required this.attached, required this.cameraLost});

  /// The screen had reached its destination.
  final bool attached;

  /// The camera the destination had before the share could not be opened again.
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

/// Where the captured screen goes: it takes the screen in place of the camera and gives the camera
/// back when the share ends.
abstract interface class ScreenShareDestination {
  /// Takes [screen].
  Future<ScreenShareAttachResult> attach(MediaStream screen);

  /// Takes the screen off and puts the camera back as it was before the share; whether the camera
  /// could not be opened again. The screen is released only after this, so a destination never
  /// sends a released screen.
  Future<bool> detach();
}

class _Share {
  _Share(this.attempt, this.target);

  final Object attempt;
  final ScreenShareTarget target;
  ScreenShareStatus status = ScreenShareStatus.starting;
  bool serviceStarted = false;
  MediaStream? stream;
  ScreenShareDestination? destination;

  /// A stop has been asked for and not yet run.
  bool stopping = false;

  /// The stop runs: the share is over, though [ScreenShare.state] still says it until the camera
  /// is back.
  bool stopped = false;
}

/// The bookkeeping and the steps of the one screen share there is.
///
/// It knows nothing of the calls, the room or signaling: the coordinator says where a share goes
/// and builds its destination, and maps [state] into the bloc's state on every [onChanged].
class ScreenShare {
  ScreenShare({
    required ScreenCapturer capturer,
    required void Function() onEndedOutside,
    required void Function() onChanged,
  }) : _capturer = capturer,
       _onChanged = onChanged {
    _endedSubscription = capturer.endedOutside.listen((_) {
      if (_share != null) onEndedOutside();
    });
  }

  static final _logger = Logger('ScreenShare');

  final ScreenCapturer _capturer;
  final void Function() _onChanged;
  late final StreamSubscription<void> _endedSubscription;
  _Share? _share;
  bool _disposed = false;

  /// Whether this platform can share the screen at all.
  bool get isSupported => _capturer.isSupported;

  /// The share there is, starting or running; `null` without one.
  ScreenShareState? get state => switch (_share) {
    final share? => ScreenShareState(target: share.target, status: share.status),
    null => null,
  };

  /// Where the share there is goes.
  ScreenShareTarget? get target => _share?.target;

  /// Where the screen of the share there is went; `null` before it was attached.
  ScreenShareDestination? get destination => _share?.destination;

  /// Starts a share for [target] and returns its attempt, or `null` while a share runs.
  Object? begin(ScreenShareTarget target) {
    if (_share != null) return null;
    final attempt = Object();
    _share = _Share(attempt, target);
    _changed();
    return attempt;
  }

  /// Whether [attempt] is the share there is and no stop has been asked of it.
  bool _isLive(Object attempt) {
    final share = _share;
    return share != null && identical(share.attempt, attempt) && !share.stopping;
  }

  bool _isCurrent(Object attempt) {
    final share = _share;
    return share != null && identical(share.attempt, attempt) && !share.stopped;
  }

  /// The consent, the service and the capture of [attempt]. Whatever it ends in other than
  /// [ScreenShareCaptureResult.captured] leaves no share, no service and no capture behind. A
  /// failure of an attempt stopped meanwhile is [ScreenShareCaptureResult.cancelled]: the person
  /// stopped it, or the call took it away, and nothing went wrong that they should hear of.
  Future<ScreenShareCaptureResult> capture(Object attempt) async {
    final bool consent;
    try {
      consent = await _capturer.requestConsent();
    } catch (e) {
      _logger.warning('capture: the consent failed: $e');
      return _fail(attempt);
    }
    if (!_isCurrent(attempt)) return ScreenShareCaptureResult.cancelled;
    if (!consent) {
      _forget(attempt);
      return ScreenShareCaptureResult.refused;
    }

    // The service first: Android 14 refuses a capture without it, and refuses the service itself
    // before the consent.
    try {
      await _capturer.startService();
    } catch (e) {
      _logger.warning('capture: the screen share service was refused: $e');
      // The start may have failed only on this side, by its timeout, with the service coming up
      // after: asked to stop, it goes once it is up.
      return _fail(attempt, stopService: true);
    }
    final share = _share;
    if (share == null || !identical(share.attempt, attempt)) {
      await _stopServiceIfUnused();
      return ScreenShareCaptureResult.cancelled;
    }
    share.serviceStarted = true;

    final MediaStream stream;
    try {
      stream = await _capturer.capture();
    } catch (e) {
      _logger.warning('capture: the screen could not be captured: $e');
      return _fail(attempt, stopService: true);
    }
    if (!_isCurrent(attempt)) {
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
  Future<ScreenShareCaptureResult> _fail(Object attempt, {bool stopService = false}) async {
    final live = _isLive(attempt);
    _forget(attempt);
    if (stopService) await _stopServiceIfUnused();
    return live ? ScreenShareCaptureResult.failed : ScreenShareCaptureResult.cancelled;
  }

  /// Hands the captured screen of [attempt] to [destination].
  Future<ScreenShareAttachResult> attach(Object attempt, ScreenShareDestination destination) async {
    final share = _share;
    final stream = share?.stream;
    if (share == null || !_isLive(attempt) || stream == null) return ScreenShareAttachResult.cancelled;
    share.destination = destination;
    final result = await destination.attach(stream);
    if (!_isCurrent(attempt)) return ScreenShareAttachResult.cancelled;
    if (result == ScreenShareAttachResult.attached || result == ScreenShareAttachResult.attachedWithNewVideo) {
      share.status = ScreenShareStatus.sharing;
      _changed();
    }
    return result;
  }

  /// Marks the share as being stopped; `false` when there is none or a stop is already on its way,
  /// so a stop is asked for once.
  bool markStopping() {
    final share = _share;
    if (share == null || share.stopping) return false;
    share.stopping = true;
    return true;
  }

  /// Stops the share: its destination takes the screen off and puts the camera back, then the
  /// capture is released and the service stopped. With [attempt], only that attempt is stopped.
  /// `null` when there was no share, or when it is already being stopped. No other share can begin
  /// from the moment the stop starts;
  /// [state] says the share is gone once its destination has put the camera back, so that what
  /// the screen shows next - the camera's preview - finds the camera there.
  Future<ScreenShareStopped?> stop({Object? attempt}) async {
    final share = _share;
    if (share == null || share.stopped || (attempt != null && !identical(share.attempt, attempt))) return null;
    share
      ..stopping = true
      ..stopped = true;
    final attached = share.status == ScreenShareStatus.sharing;
    var cameraLost = false;
    if (share.destination case final destination?) {
      try {
        cameraLost = await destination.detach();
      } catch (e) {
        _logger.warning('stop: the destination did not let the screen go: $e');
      }
    }
    if (identical(_share, share)) _share = null;
    _changed();
    final stream = share.stream;
    if (stream != null) await _release(stream);
    if (share.serviceStarted) await _stopServiceIfUnused();
    return ScreenShareStopped(attached: attached, cameraLost: cameraLost);
  }

  /// Stops the share without telling anyone: the owner is going away.
  Future<void> dispose() async {
    _disposed = true;
    await _endedSubscription.cancel();
    await stop();
  }

  void _changed() {
    if (!_disposed) _onChanged();
  }

  void _forget(Object attempt) {
    if (!_isCurrent(attempt)) return;
    _share = null;
    _changed();
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
    if (_share?.serviceStarted ?? false) return;
    try {
      await _capturer.stopService();
    } catch (e) {
      _logger.warning('the screen share service did not stop: $e');
    }
  }
}
