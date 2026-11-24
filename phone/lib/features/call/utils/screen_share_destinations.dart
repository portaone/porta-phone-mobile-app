// Where a captured screen goes (ScreenShareDestination, screen_share.dart): the call's own video
// sender (CallSenderDestination) or the room's video (RoomScreenDestination). Built by CallBloc's
// screen share coordinator when the captured screen is attached, held by ScreenShare until the
// share stops. The camera <-> screen move of a sender is CameraScreenSwap's, shared with the
// room's video session.
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/extensions/extensions.dart';

import '../conference/room_video.dart';
import 'camera_screen_swap.dart';
import 'screen_share.dart';
import 'user_media_builder.dart';

final _logger = Logger('ScreenShareDestination');

/// Where the far end stands on the video line a share added to a call.
enum ScreenShareVideoAnswer {
  /// No answer covers the line yet: the answer that came was to an offer made before it.
  pending,

  /// The line sends: the screen goes out. Also for a share that waits for no answer.
  sends,

  /// The answer refused the line or left it unable to send.
  refused,
}

/// The screen on a call's own video sender, in place of the camera; nothing changes in the
/// protocol. A call without a video sender - an audio call - gets one added for the screen, which
/// renegotiates the call.
///
/// The call's camera, on or soft-muted, is let go while the screen is out
/// ([UserMediaBuilder.releaseVideoTrack]): kept open it would capture for nobody - its indicator
/// on, the battery spent - behind the tile that stands in for its preview. [detach] opens it again
/// as it was, on a connection still usable: a call going away does not get a camera back.
class CallSenderDestination implements ScreenShareDestination {
  CallSenderDestination({
    required this.peerConnection,
    required MediaStream? localStream,
    required UserMediaBuilder userMedia,
    required bool? Function() frontCamera,
  }) : _localStream = localStream,
       _userMedia = userMedia,
       _frontCamera = frontCamera;

  final RTCPeerConnection peerConnection;

  final MediaStream? _localStream;
  final UserMediaBuilder _userMedia;
  final bool? Function() _frontCamera;

  RTCRtpSender? _sender;
  MediaStreamTrack? _screen;

  /// What the sender carried before the screen when it was not the call's own camera.
  MediaStreamTrack? _previousTrack;

  /// Whether the call's camera was on (not soft-muted) when the screen took its place; `null`
  /// when the sender did not carry the call's camera.
  bool? _cameraEnabled;

  /// The far end has not yet answered for the video sender this share added.
  bool get awaitsVideo => _awaitsVideo;
  bool _awaitsVideo = false;

  @override
  Future<ScreenShareAttachResult> attach(MediaStream screen) async {
    final track = screen.getVideoTracks().firstOrNull;
    if (track == null) return ScreenShareAttachResult.failed;
    _screen = track;
    try {
      final sender = await peerConnection.videoSender();
      if (sender == null) {
        _sender = await peerConnection.addTrack(track, _localStream ?? screen);
        _awaitsVideo = true;
        return ScreenShareAttachResult.attachedWithNewVideo;
      }
      final previous = sender.track;
      final localStream = _localStream;
      final carriesCamera = previous != null && localStream != null && _carries(localStream, previous);
      _sender = sender;
      if (carriesCamera) {
        _cameraEnabled = previous.enabled;
      } else {
        _previousTrack = previous;
      }
      await CameraScreenSwap.toScreen(
        sender,
        track,
        letCameraGo: carriesCamera ? () => _userMedia.releaseVideoTrack(localStream) : null,
      );
      return ScreenShareAttachResult.attached;
    } catch (e) {
      _logger.warning('attach: the screen did not go on the call\'s connection: $e');
      return ScreenShareAttachResult.failed;
    }
  }

  @override
  Future<bool> detach() async {
    final sender = _sender;
    if (sender == null || !peerConnection.isUsable) return false;
    final cameraEnabled = _cameraEnabled;
    final localStream = _localStream;
    final camera = await CameraScreenSwap.toCamera(
      sender,
      openCamera: cameraEnabled == null || localStream == null
          ? null
          : () async {
              final track = await _userMedia.ensureVideoTrack(localStream, frontCamera: _frontCamera());
              track?.enabled = cameraEnabled;
              return track;
            },
      fallback: _previousTrack,
    );
    return cameraEnabled != null && camera == null;
  }

  /// What the far end's answers so far say about the video line the share added.
  ///
  /// The answer that came may be to an offer made before the line: an offer already out when the
  /// share added its sender (an ICE restart, a hold, a codec move) leaves the line out, and its
  /// answer says nothing of it. Such a line has no negotiated direction yet, and the share waits
  /// for the answer to its own offer, which the connection asks for once the earlier one is done.
  Future<ScreenShareVideoAnswer> videoAnswer() async {
    if (!_awaitsVideo) return ScreenShareVideoAnswer.sends;
    final transceiver = await _transceiver();
    if (transceiver == null) return ScreenShareVideoAnswer.pending;
    final direction = await transceiver.getCurrentDirection();
    if (direction == null) return ScreenShareVideoAnswer.pending;
    final sends = direction == TransceiverDirection.SendRecv || direction == TransceiverDirection.SendOnly;
    if (sends) _awaitsVideo = false;
    return sends ? ScreenShareVideoAnswer.sends : ScreenShareVideoAnswer.refused;
  }

  /// Whether the offer out now carries the video line the share added and waits for its answer:
  /// the line has a place (`mid`) in an offer and no negotiated direction. A refusal of an offer
  /// without the line says nothing of the share.
  Future<bool> videoOffered() async {
    if (!_awaitsVideo) return false;
    final transceiver = await _transceiver();
    if (transceiver == null || transceiver.mid.isEmpty) return false;
    return await transceiver.getCurrentDirection() == null;
  }

  Future<RTCRtpTransceiver?> _transceiver() async {
    final track = _screen;
    if (track == null) return null;
    final transceivers = await peerConnection.getTransceivers();
    return transceivers.firstWhereOrNull((t) => t.sender.track?.id == track.id);
  }

  static bool _carries(MediaStream stream, MediaStreamTrack track) =>
      stream.getVideoTracks().any((candidate) => candidate.id == track.id);
}

/// The screen on the room's video, in place of the camera ([RoomVideoControls.shareScreen]): the
/// room publishes it on its own queue, and what it refuses comes back as a `ScreenShareLostNotice`.
/// The room lets its own camera go and puts it back; a camera that does not open again is the
/// room's to tell.
///
/// The host's [legs] get it too: a participant sees the host by the video of its call with him,
/// not by the room's, so each leg's video sender carries the screen in the camera's place, as a
/// call's share does, and its camera back after it. A leg that is a voice call is given a video
/// sender for the screen, its call renegotiated, and keeps it empty after; a far end that refuses
/// the video stays a voice call, and the share goes on for the others.
class RoomScreenDestination implements ScreenShareDestination {
  RoomScreenDestination(this._room, {List<CallSenderDestination> legs = const []}) : _legs = legs;

  final RoomVideoControls _room;
  final List<CallSenderDestination> _legs;

  @override
  Future<ScreenShareAttachResult> attach(MediaStream screen) async {
    if (!_room.takesScreen) return ScreenShareAttachResult.failed;
    _room.shareScreen(screen);
    for (final leg in _legs) {
      // A leg that does not take it keeps its camera; the room and the other legs share on.
      if (await leg.attach(screen) == ScreenShareAttachResult.failed) {
        _logger.warning('attach: a leg of the room did not take the screen');
      }
    }
    return ScreenShareAttachResult.attached;
  }

  /// The legs first: a camera the room puts back on them after the share must not be taken off
  /// by their own detach.
  @override
  Future<bool> detach() async {
    for (final leg in _legs) {
      await leg.detach();
    }
    await _room.stopScreenShare();
    return false;
  }
}
