import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';

import '../models/participant_camera.dart';

final _logger = Logger('ParticipantVideo');

/// A participant's camera over a [placeholder]: the camera is seen once it has
/// drawn a frame, and after a new track for it (a subscription made again)
/// once that one has; until then - and for as long as none comes - the
/// placeholder is what is seen, not an empty frame. The placeholder stays in
/// its place whatever the camera does, so what is under it is not made again.
///
/// The renderer is this widget's own: made when a [camera] arrives, given the
/// camera's own track, released when the camera goes or the widget does. The
/// caller gives the shape: it fills what it is given. [identifier] names the
/// camera for a case only while it is seen.
class ParticipantVideo extends StatefulWidget {
  const ParticipantVideo({
    super.key,
    required this.camera,
    required this.placeholder,
    this.fit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    this.mirror = false,
    this.identifier,
  });

  /// The camera; `null` shows the placeholder alone.
  final ParticipantCamera? camera;

  /// What is seen without a camera frame.
  final Widget placeholder;

  /// How the camera fills the space.
  final RTCVideoViewObjectFit fit;

  /// Whether the picture is mirrored: this client's own front camera is, as
  /// its local preview is.
  final bool mirror;

  /// The automation id of the camera, while it is seen.
  final String? identifier;

  @override
  State<ParticipantVideo> createState() => _ParticipantVideoState();
}

class _ParticipantVideoState extends State<ParticipantVideo> {
  RTCVideoRenderer? _renderer;
  bool _opening = false;
  bool _hasFrame = false;

  @override
  void initState() {
    super.initState();
    if (widget.camera != null) unawaited(_open());
  }

  @override
  void didUpdateWidget(ParticipantVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only a change of the camera is a change for the renderer: the screen
    // rebuilds on every change of the call's state.
    final camera = widget.camera;
    if (camera == oldWidget.camera) return;
    if (camera == null) {
      _close();
      return;
    }
    final renderer = _renderer;
    if (renderer == null) {
      if (!_opening) unawaited(_open());
      return;
    }
    // A new track - a subscription made again, a new connection - has drawn
    // nothing yet: the placeholder is what is seen until it has. A renegotiation
    // hands the same track over in a new stream object; it is given to the
    // renderer again - the first time may have come before the platform had
    // the track - but is not waited for: the platform reports a first frame
    // only for a new track.
    final old = oldWidget.camera;
    if (old == null || !camera.isSameTrackAs(old)) _hasFrame = false;
    unawaited(_show(renderer, camera));
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  /// Makes the renderer and hands it the camera. A widget that went, or lost
  /// its camera, while the renderer was being made releases it here: a
  /// renderer released before it is made keeps its texture for good.
  Future<void> _open() async {
    _opening = true;
    final renderer = RTCVideoRenderer();
    try {
      await renderer.initialize();
    } catch (error, stackTrace) {
      _opening = false;
      _logger.warning('the renderer could not be made; the placeholder stays', error, stackTrace);
      return;
    }
    _opening = false;
    final camera = widget.camera;
    if (!mounted || camera == null) {
      _release(renderer);
      return;
    }
    renderer.onFirstFrameRendered = _onFirstFrame;
    setState(() => _renderer = renderer);
    await _show(renderer, camera);
  }

  /// Shows [camera]'s own track on [renderer]: a stream id alone may stand for
  /// every participant's track.
  Future<void> _show(RTCVideoRenderer renderer, ParticipantCamera camera) async {
    try {
      await renderer.setSrcObject(stream: camera.stream, trackId: camera.trackId);
    } catch (error, stackTrace) {
      _logger.warning('the camera could not be shown; the placeholder stays', error, stackTrace);
    }
  }

  void _onFirstFrame() {
    if (mounted && !_hasFrame) setState(() => _hasFrame = true);
  }

  void _close() {
    final renderer = _renderer;
    _renderer = null;
    _hasFrame = false;
    if (renderer != null) _release(renderer);
  }

  void _release(RTCVideoRenderer renderer) {
    renderer.onFirstFrameRendered = null;
    unawaited(
      renderer.dispose().catchError(
        (Object error, StackTrace stackTrace) =>
            _logger.warning('the renderer could not be released', error, stackTrace),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final renderer = _renderer;
    final seen = renderer != null && _hasFrame;
    return Semantics(
      identifier: seen ? widget.identifier : null,
      container: seen && widget.identifier != null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: widget.placeholder),
          if (renderer != null)
            Opacity(
              opacity: seen ? 1 : 0,
              child: RTCVideoView(renderer, objectFit: widget.fit, mirror: widget.mirror),
            ),
        ],
      ),
    );
  }
}

/// The picture of one participant on their row of the conference: their
/// [avatar], and their camera over it once it has drawn a frame - round and of
/// the avatar's own size, so a row does not change its size or move when a
/// camera comes or goes. See [ParticipantVideo].
class ConferenceParticipantCamera extends StatelessWidget {
  const ConferenceParticipantCamera({
    super.key,
    required this.camera,
    required this.diameter,
    required this.avatar,
    required this.identifier,
  });

  /// The participant's camera; `null` shows the avatar alone.
  final ParticipantCamera? camera;

  /// The size of the picture: the avatar's own.
  final double diameter;

  /// What is seen without a camera frame.
  final Widget avatar;

  /// The automation id of the camera, while it is seen.
  final String identifier;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: diameter,
      child: ClipOval(
        clipBehavior: camera == null ? Clip.none : Clip.antiAlias,
        child: ParticipantVideo(camera: camera, placeholder: avatar, identifier: identifier),
      ),
    );
  }
}
