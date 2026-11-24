// The video of the conference room: the client's part in a room's video
// (protocol sections 18 and 19) - everyone else's cameras in, this client's
// camera out - for the host of a room and for a far end invited to one.
// Used by ConferenceRoom, which hands it the video events and the user's
// camera controls and turns what it asks back into the room's own steps.
//
// It holds the video session and the camera plan, and decides what the
// video does: when to join (the host once in the room, an invited far end on
// conference_video_invite), when to make it again (a session that came back,
// a rejoin), what the camera does in the background, and what a publication
// that was given up says. A screen the owner captured goes to the room in the
// camera's place (shareScreen); it stays out in the background, where the
// camera does not - the person shares what they look at elsewhere. It reads the room and the calls through the
// functions it is given and raises the room's own steps, commands and
// notices; it writes nothing of the owner's state itself.
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';

import 'package:signaling/signaling.dart';

import '../models/active_call.dart';
import '../models/conference_request_result.dart';
import '../models/conference_state.dart';
import '../utils/peer_connection_factory.dart';
import '../utils/user_media_builder.dart';
import 'conference_camera_plan.dart';
import 'conference_room_ports.dart';
import 'conference_video_session.dart';

final _logger = Logger('RoomVideo');

/// What the owner of the room hands the room's video: the user's camera
/// controls, and what happens outside it.
abstract interface class RoomVideoControls {
  /// An event of the room's video ([RoomVideo.isEvent]).
  Future<void> onEvent(Event event);

  /// Publishes the camera to the room, or takes it off.
  Future<void> setCamera(bool enabled);

  /// Switches the camera published to the room between the front and the rear.
  Future<void> switchCamera();

  /// The app went to [state].
  void onAppLifecycleChanged(AppLifecycleState state);

  /// The signalling session came back.
  void onSessionBack();

  /// Whether the room's video can take a shared screen now: this client is
  /// in a room's video - its own or one it was invited to - that has video.
  bool get takesScreen;

  /// Shares [screen] in the room in place of the camera. A share the room
  /// will not take comes back as a [ScreenShareLostNotice].
  void shareScreen(MediaStream screen);

  /// Takes the shared screen off the room; the camera comes back when it is
  /// still wanted. Completes once the room has let the screen go, so that the
  /// capture can be released after it.
  Future<void> stopScreenShare();

  /// The handshake of a session that came back kept the room standing.
  void onRoomKept();

  /// The calls changed: [lines] are the lines of every call now; [hostsRoom]
  /// whether a room of this client's own is up.
  void onCallsChanged(Iterable<int?> lines, {required bool hostsRoom});
}

/// The video of the conference room.
class RoomVideo implements RoomVideoControls {
  RoomVideo({
    required bool enabled,
    required PeerConnectionFactory factory,
    required UserMediaBuilder userMediaBuilder,
    required ConferenceState Function() conference,
    required Iterable<ActiveCall> Function() calls,
    required Future<ConferenceRequestResult> Function(Request request) send,
    required void Function(ConferenceStep step) onStep,
    required void Function(ConferenceCommand command) onCommand,
    required void Function(ConferenceNotice notice) onNotice,
    required void Function(Object error, StackTrace? stack, String context) onError,
  }) : _enabled = enabled,
       _conference = conference,
       _calls = calls,
       _send = send,
       _onStep = onStep,
       _onCommand = onCommand,
       _onNotice = onNotice,
       _onError = onError {
    _session = ConferenceVideoSession(
      factory: factory,
      userMediaBuilder: userMediaBuilder,
      send: _sendRequest,
      onFeedsChanged: (feeds, presenter) => _onStep(VideoFeedsChangedStep(feeds, presenter: presenter)),
      callsWantCamera: _callsWantCamera,
      callsFrontCamera: _callsFrontCamera,
      onScreenLost: _screenLost,
    );
  }

  final bool _enabled;
  final ConferenceState Function() _conference;
  final Iterable<ActiveCall> Function() _calls;
  final Future<ConferenceRequestResult> Function(Request request) _send;
  final void Function(ConferenceStep step) _onStep;
  final void Function(ConferenceCommand command) _onCommand;
  final void Function(ConferenceNotice notice) _onNotice;
  final void Function(Object error, StackTrace? stack, String context) _onError;

  /// Everyone else's cameras in, this client's camera out.
  late final ConferenceVideoSession _session;

  /// What the user asked of the camera, and the line of an invitation to
  /// someone else's room: set by `conference_video_invite`, ended by
  /// `conference_video_terminated` or the end of that call.
  final ConferenceCameraPlan _plan = ConferenceCameraPlan();

  /// Whether the app is in the background, where the camera is not published.
  bool _inBackground = false;

  /// Whether the owner is closing: a publication given up then says nothing.
  bool _disposed = false;

  static const _videoDisabled = 'video_disabled';

  /// Whether [event] belongs to the room's video, for [onEvent].
  static bool isEvent(Event event) =>
      event is ConferenceVideoInviteEvent ||
      event is ConferenceVideoTerminatedEvent ||
      event is ConferenceVideoOfferEvent ||
      event is ConferenceVideoPublisherAnswerEvent ||
      event is ConferenceVideoIceTrickleEvent ||
      event is ConferenceVideoUpdatedEvent ||
      event is ConferenceVideoFailedEvent;

  /// The line of the call an invitation to somebody else's room came
  /// through; `null` without one.
  int? get invitedLine => _plan.invitedLine;

  /// This client's camera as it is published; `null` while it is not.
  MediaStream? get camera => _session.camera;

  /// Whether this client takes part in a room's video: its own, or one it was
  /// invited to.
  bool get _inVideo => _conference().isPresent || _plan.invitedLine != null;

  @override
  Future<void> onEvent(Event event) async {
    switch (event) {
      case ConferenceVideoInviteEvent(:final line):
        _acceptInvite(line);
        return;
      case ConferenceVideoTerminatedEvent():
        if (_plan.invitedLine != null && !_conference().isPresent) {
          unawaited(endInvitation('the video room of line ${_plan.invitedLine} is over'));
        }
        return;
    }
    if (!_inVideo) {
      _logger.info('onEvent: no room here, ${event.runtimeType} dropped');
      return;
    }
    if (event case ConferenceVideoFailedEvent(request: _?, reason: _videoDisabled)) {
      _onStep(const VideoDisabledStep());
    }
    final Future<void> work = switch (event) {
      ConferenceVideoOfferEvent(:final jsep) => _session.handleOffer(jsep),
      ConferenceVideoPublisherAnswerEvent(:final jsep) => _session.handlePublisherAnswer(jsep),
      ConferenceVideoIceTrickleEvent(:final pc?, :final candidate) => _session.handleRemoteCandidate(pc, candidate),
      final ConferenceVideoUpdatedEvent updated => _session.handleUpdated(updated),
      ConferenceVideoFailedEvent(:final pc?, :final code) => _session.handleFailed(pc, code: code),
      ConferenceVideoFailedEvent(:final request?, :final reason) => _session.handleRefused(request, reason: reason),
      _ => Future<void>.value(),
    };
    // Not awaited: the session runs its own queue, and a media round trip
    // must not hold the owner's.
    unawaited(work.catchError(_failed('${event.runtimeType}')));
  }

  /// The camera is opened once and shared, so the calls of the room that send
  /// video turn theirs on and off with it: their video is not forwarded in the
  /// room, and a call left alone when the room is gone goes on as the camera
  /// was. A participant sees the host by the video of its call with him, so a
  /// leg of the host's own room that is a voice call is given the camera when
  /// it is turned on - its call renegotiated with video, as a call's camera
  /// button does; a far end that refuses the video stays a voice call.
  ///
  /// While the host shares his screen the legs carry it, and a camera turned
  /// on then reaches them after the share ([stopScreenShare]).
  @override
  Future<void> setCamera(bool enabled) async {
    if (!_enabled || !_inVideo || _conference().videoDisabled) return;
    final inVideo = _callsInVideo.toList();
    if (!enabled || !_session.isSharingScreen) _setLegsCamera(enabled);
    if (!enabled) {
      // The track the legs just turned off is the one camera every call
      // shares: a video call outside the room that has its camera on keeps
      // it, turned on again after them.
      final ids = inVideo.map((call) => call.callId).toSet();
      for (final call in _calls()) {
        if (ids.contains(call.callId) || !call.video || !call.hasLocalVideoTrack) continue;
        _onCommand(SetLegCameraCommand(call.callId, true));
      }
    }
    if (_plan.setCamera(enabled, inBackground: _inBackground)) {
      _publish();
    } else if (!enabled) {
      unawaited(_session.unpublish().catchError(_failed('unpublish')));
    }
  }

  @override
  bool get takesScreen => _enabled && _inVideo && !_conference().videoDisabled;

  /// Not awaited: the session runs its own queue, and a signalling round trip
  /// must not hold the owner's queue. What the room refuses comes back
  /// through the session's `onScreenLost`.
  @override
  void shareScreen(MediaStream screen) {
    if (!takesScreen) {
      _onNotice(const ScreenShareLostNotice());
      return;
    }
    unawaited(
      _session.shareScreen(screen).then<void>((_) {}).catchError((Object error, StackTrace stackTrace) {
        _reportFailure('shareScreen', error, stackTrace);
        _onNotice(const ScreenShareLostNotice());
      }),
    );
  }

  /// The room would not take the screen: the share is to stop, and the camera
  /// the screen stood in for comes back when the person still wants it.
  void _screenLost() {
    _onNotice(const ScreenShareLostNotice());
    if (_inVideo && _plan.cameraWanted && !_plan.cameraPaused) _publish();
  }

  @override
  Future<void> stopScreenShare() async {
    if (!_session.isSharingScreen) return;
    try {
      _published(await _session.stopScreen());
    } catch (error, stackTrace) {
      _reportFailure('stopScreen', error, stackTrace);
    }
    // A camera turned on while the screen was out reaches the legs now.
    if (_plan.cameraWanted && !_plan.cameraPaused) _setLegsCamera(true);
  }

  /// Turns the camera of the calls in the room's video on or off with the room's.
  void _setLegsCamera(bool enabled) {
    final conference = _conference();
    for (final call in _callsInVideo) {
      if (call.video == enabled) continue;
      final upgrade = enabled && conference.isLeg(call.callId);
      if (call.hasLocalVideoTrack || upgrade) _onCommand(SetLegCameraCommand(call.callId, enabled));
    }
  }

  /// Not awaited: the session runs its own queue, and a signalling round trip
  /// ahead of the switch must not hold the owner's controls behind it.
  @override
  Future<void> switchCamera() async {
    if (!_inVideo) return;
    final trackId = _session.cameraTrack?.id;
    if (trackId == null) return;
    unawaited(
      _session.switchCamera().then((front) => _cameraSwitched(front, trackId), onError: _failed('switchCamera')),
    );
  }

  /// In the background the camera leaves the room - the others see the avatar
  /// - and comes back with the app; the audio stays.
  @override
  void onAppLifecycleChanged(AppLifecycleState state) {
    _inBackground = switch (state) {
      AppLifecycleState.paused || AppLifecycleState.detached || AppLifecycleState.hidden => true,
      _ => false,
    };
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _pauseCamera();
    } else if (state == AppLifecycleState.resumed) {
      _resumeCamera();
    }
  }

  /// Events of the room's video sent while the socket was down are lost and
  /// are not in the handshake (protocol section 18.7): an invitation that
  /// stands makes its video again; a room of this client's own does so when
  /// the handshake keeps it ([onRoomKept]).
  @override
  void onSessionBack() {
    if (_plan.invitedLine != null && !_conference().isPresent) {
      _remake('the signalling session came back with an invitation standing');
    }
  }

  @override
  void onRoomKept() => _remake('the signalling session came back with the room standing');

  /// The call an invitation came through is gone, whether or not
  /// `conference_video_terminated` arrived for it: the video goes with it, or
  /// the camera would stay captured for a call nobody has.
  @override
  void onCallsChanged(Iterable<int?> lines, {required bool hostsRoom}) {
    final line = _plan.invitedLine;
    if (line == null || hostsRoom || lines.contains(line)) return;
    unawaited(endInvitation('the call on line $line ended'));
  }

  /// Joins the room's video once the host is in the room: everyone else's
  /// cameras, and his own when one of the merged calls was a video call. After
  /// a rejoin the video is remade over the new signalling session.
  void start({required bool rejoined}) {
    if (!_enabled || _conference().videoDisabled) return;
    if (rejoined && (_session.isSubscribed || _session.isPublishing || _session.isSharingScreen)) {
      _remake('the host is back in the room');
      return;
    }
    if (_session.isSubscribed) return;
    unawaited(_session.subscribe().catchError(_failed('subscribe')));
    final conference = _conference();
    final camera = _calls().any((call) => conference.isLeg(call.callId) && call.video);
    if (_plan.start(camera: camera, inBackground: _inBackground)) _publish();
  }

  /// The room's video is over with the room: closed, the camera plan ended.
  Future<void> close() {
    _plan.end();
    return _session.teardown();
  }

  /// Ends this client's part in somebody else's room; with [leave] the room
  /// is told, where it is this client that goes and the room that stays.
  /// Nothing without an invitation.
  Future<void> endInvitation(String why, {bool leave = false}) async {
    if (_plan.invitedLine == null) return;
    _logger.info('endInvitation: $why');
    _plan.end();
    // The teardown reports the streams gone only when there were some.
    _onStep(const VideoFeedsChangedStep([]));
    try {
      await (leave ? _session.leave() : _session.teardown());
    } catch (error, stackTrace) {
      _onError(error, stackTrace, 'RoomVideo teardown error');
    }
  }

  /// The room has no video at all: the camera is not wanted any more.
  void dropCamera() => _plan.setCamera(false, inBackground: _inBackground);

  /// The calls whose camera is the track [trackId]: the legs of the room and
  /// the call an invitation came through.
  Iterable<String> callsShowing(String trackId) => _callsInVideo
      .where((call) => call.localStream?.getVideoTracks().firstOrNull?.id == trackId)
      .map((call) => call.callId);

  /// The owner is closing.
  void dispose() => _disposed = true;

  /// The calls the room's video stands on: the legs of the host's room, or
  /// the call an invitation came through.
  Iterable<ActiveCall> get _callsInVideo {
    final conference = _conference();
    final invitedLine = _plan.invitedLine;
    return _calls().where((call) => conference.isLeg(call.callId) || (invitedLine != null && call.line == invitedLine));
  }

  /// The camera track is shared with the calls: when the room lets it go it
  /// stays on only for a call whose own camera the user has on.
  bool _callsWantCamera() => _calls().any((call) => call.video && call.hasLocalVideoTrack);

  /// Which camera the calls in the room's video show: a camera switch in the room tells them.
  bool? _callsFrontCamera() => _callsInVideo.firstWhereOrNull((call) => call.frontCamera != null)?.frontCamera;

  /// Takes part in the video of the room the far end of [line] hosts: this
  /// client's camera goes to it when that call is a video call, and everyone
  /// else's comes back (protocol section 19). Ignored without a call there, or
  /// while this client hosts a room of its own.
  void _acceptInvite(int line) {
    if (!_enabled || _conference().isPresent) return;
    final call = _calls().firstWhereOrNull((call) => call.line == line);
    if (call == null) {
      _logger.info('_acceptInvite: no call on line $line, ignoring');
      return;
    }
    _logger.info('_acceptInvite: line $line, video ${call.video}');
    unawaited(_session.subscribe().catchError(_failed('subscribe')));
    final publish = _plan.start(camera: call.video, inBackground: _inBackground, invitedLine: line);
    // The invitation is in the owner's state from now on, cameras or not:
    // the camera control of that call is the room's from here.
    _onStep(const VideoFeedsChangedStep([]));
    if (publish) _publish();
  }

  /// Makes the video again over the signalling session that is up now: the
  /// subscription from scratch, the publisher with an ICE restart.
  void _remake(String why) {
    if (!_enabled) return;
    if (!_session.isSubscribed && !_session.isPublishing && !_session.isSharingScreen) return;
    _logger.info('_remake: $why');
    unawaited(_session.reconnected().catchError(_failed('reconnected')));
  }

  /// Sends a request of the room's video, and says when the room has no
  /// video at all.
  Future<ConferenceRequestResult> _sendRequest(Request request) async {
    final result = await _send(request);
    if (result.outcome == ConferenceRequestOutcome.refused && result.reason == _videoDisabled) {
      _onStep(const VideoDisabledStep());
    }
    return result;
  }

  void _publish() => unawaited(_session.publish().then(_published, onError: _failed('publish')));

  /// A publication that was given up - the camera could not be opened, or the
  /// room refused it - is said to the user, and the camera is taken for
  /// unwanted so that the control shows what is.
  void _published(CameraPublication publication) {
    if (publication.published || _disposed || _session.isPublishing) return;
    // Taken off by the user or by the background meanwhile: not a failure.
    if (!_plan.cameraWanted || _plan.cameraPaused) return;
    _plan.setCamera(false, inBackground: _inBackground);
    switch (publication) {
      case CameraUnavailable():
        _onNotice(const CameraUnavailableNotice());
      case CameraRefused(:final reason?) when reason != _videoDisabled:
        _onNotice(RoomRefusedNotice(reason));
      default:
    }
  }

  void _cameraSwitched(bool? frontCamera, String trackId) {
    if (frontCamera != null) _onStep(CameraSwitchedStep(frontCamera: frontCamera, trackId: trackId));
  }

  void _pauseCamera() {
    if (!_inVideo || !_plan.pause(publishing: _session.isPublishing)) return;
    unawaited(_session.unpublish().catchError(_failed('unpublish')));
  }

  void _resumeCamera() {
    if (_plan.resume() && _inVideo) _publish();
  }

  /// Reports an error of [step] and lets the future it came from go on.
  bool Function(Object, StackTrace) _failed(String step) =>
      (error, stackTrace) => _reportFailure(step, error, stackTrace);

  bool _reportFailure(String step, Object error, StackTrace stackTrace) {
    _onError(error, stackTrace, 'RoomVideo $step error');
    return false;
  }
}
