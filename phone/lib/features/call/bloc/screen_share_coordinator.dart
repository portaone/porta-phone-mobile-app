// Where a screen share goes and whether it may start or go on: the one place that decides it, for
// a call and for a room alike. CallBloc owns one and asks it from its handlers; CallState asks its
// policy (targetFor, canStart, stands, statusShownFor) for the screen's controls. The share's
// steps and its status are ScreenShare's (utils/screen_share.dart); the destinations it builds
// are in utils/screen_share_destinations.dart.
//
// A leg of the room this client hosts shares to the room's video, one share of the room whichever
// leg asked for it; a call whose far end invited this client to its room shares to that room's
// video, shown on that call; any other call shares on its own video sender. A share stays where it
// began: one that cannot go on there - its call held, ending, merged, invited, the room parked for
// a call outside it, the room or the invitation over - is stopped.
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../conference/room_video.dart';
import '../models/models.dart';
import '../utils/screen_share.dart';
import '../utils/screen_share_destinations.dart';
import '../utils/user_media_builder.dart';
import 'call_bloc.dart';

class ScreenShareCoordinator {
  ScreenShareCoordinator({
    required ScreenCapturer capturer,
    required UserMediaBuilder userMedia,
    required RoomVideoControls Function() room,
    required void Function() onChanged,
    required void Function() onEndedOutside,
  }) : _userMedia = userMedia,
       _room = room,
       _share = ScreenShare(capturer: capturer, onChanged: onChanged, onEndedOutside: onEndedOutside);

  final UserMediaBuilder _userMedia;
  final RoomVideoControls Function() _room;
  final ScreenShare _share;

  // --- Policy ---------------------------------------------------------------------------------

  /// Where a share [callId] starts goes: the room's video for a leg of the room this client hosts
  /// and for a call an invitation to a room came through, else the call's own sender.
  static ScreenShareTarget targetFor(CallState state, String callId) {
    if (state.isConferenced(callId)) return const RoomScreenShareTarget();
    if (state.isInvitedToRoom(callId)) return RoomScreenShareTarget(invitedCallId: callId);
    return CallScreenShareTarget(callId);
  }

  /// Whether a share can start from [callId] now: on a phone that can share, with no share
  /// running, where its target can take a screen. A leg needs the room up, with video, not
  /// parked; any other call answered, connected, not held, not on its way out, no transfer under
  /// way (the picker being open is not one) and no room being put together.
  static bool canStart(CallState state, String callId) {
    if (!state.screenShareSupported || state.screenShare != null) return false;
    return switch (targetFor(state, callId)) {
      RoomScreenShareTarget(hosted: true) => state.conference.phase == ConferencePhase.active && _roomStands(state),
      final target => stands(state, target),
    };
  }

  /// Whether a share to [target] may go on in [state]. The room's survives the host's way back in
  /// (rejoining) - its video is made again with the screen - but not a room parked for a call
  /// outside it: the person is talking to somebody else then.
  static bool stands(CallState state, ScreenShareTarget target) {
    if (!state.screenShareSupported) return false;
    switch (target) {
      case RoomScreenShareTarget(invitedCallId: null):
        return _roomStands(state);
      case RoomScreenShareTarget(:final invitedCallId?):
        return _callUp(state, invitedCallId) && state.isInvitedToRoom(invitedCallId);
      case CallScreenShareTarget(:final callId):
        return _callUp(state, callId) &&
            !state.conference.awaitsOffer &&
            !state.isConferenced(callId) &&
            !state.isInvitedToRoom(callId);
    }
  }

  static bool _roomStands(CallState state) =>
      state.conference.isPresent && state.roomTakesVideo && !state.conferenceMustPark;

  static bool _callUp(CallState state, String callId) {
    final call = state.retrieveActiveCall(callId);
    return call != null &&
        call.wasAccepted &&
        !call.wasHungUp &&
        !call.held &&
        call.processingStatus == CallProcessingStatus.connected &&
        !(call.transfer?.isUnderWay ?? false);
  }

  /// Where the share [callId] shows stands: the room's for a leg of the room this client hosts,
  /// the call's own share or the share to the room it was invited through for any other call.
  static ScreenShareStatus? statusShownFor(CallState state, String callId) {
    final share = state.screenShare;
    if (share == null) return null;
    final shown = switch (share.target) {
      RoomScreenShareTarget(invitedCallId: null) => state.isConferenced(callId),
      RoomScreenShareTarget(:final invitedCallId?) => invitedCallId == callId,
      CallScreenShareTarget(callId: final target) => target == callId,
    };
    return shown ? share.status : null;
  }

  // --- The share ------------------------------------------------------------------------------

  /// Whether this platform can share the screen at all.
  bool get isSupported => _share.isSupported;

  /// The share there is, for the state.
  ScreenShareState? get state => _share.state;

  /// Starts a share from [callId] in [state]; its attempt, or `null` when none can start.
  Object? begin(CallState state, String callId) {
    if (!canStart(state, callId)) return null;
    return _share.begin(targetFor(state, callId));
  }

  /// The consent, the service and the capture of [attempt].
  Future<ScreenShareCaptureResult> capture(Object attempt) => _share.capture(attempt);

  /// Hands the captured screen of [attempt] to its destination if the share can still go there in
  /// [state]; [connectionOf] gives a call's connection. A share that cannot is stopped, as one the
  /// destination refused.
  Future<ScreenShareAttachResult> attach(
    Object attempt,
    CallState state, {
    required Future<RTCPeerConnection?> Function(String callId) connectionOf,
  }) async {
    final target = _share.target;
    if (target == null) return ScreenShareAttachResult.cancelled;
    final destination = await _destinationFor(target, state, connectionOf);
    if (destination == null) {
      await _share.stop(attempt: attempt);
      return ScreenShareAttachResult.failed;
    }
    final result = await _share.attach(attempt, destination);
    if (result == ScreenShareAttachResult.failed) await _share.stop(attempt: attempt);
    return result;
  }

  Future<ScreenShareDestination?> _destinationFor(
    ScreenShareTarget target,
    CallState state,
    Future<RTCPeerConnection?> Function(String callId) connectionOf,
  ) async {
    if (!stands(state, target)) return null;
    switch (target) {
      case RoomScreenShareTarget(:final invitedCallId):
        final room = _room();
        if (!room.takesScreen) return null;
        // The host's own room: its participants see him by their calls with him.
        final legs = <CallSenderDestination>[];
        if (invitedCallId == null) {
          for (final callId in state.conference.legs.keys) {
            final peerConnection = await connectionOf(callId);
            final call = state.retrieveActiveCall(callId);
            if (peerConnection == null || call == null) continue;
            legs.add(
              CallSenderDestination(
                peerConnection: peerConnection,
                localStream: call.localStream,
                userMedia: _userMedia,
                frontCamera: () => call.frontCamera,
              ),
            );
          }
        }
        return RoomScreenDestination(room, legs: legs);
      case CallScreenShareTarget(:final callId):
        final peerConnection = await connectionOf(callId);
        final call = state.retrieveActiveCall(callId);
        if (peerConnection == null || call == null) return null;
        return CallSenderDestination(
          peerConnection: peerConnection,
          localStream: call.localStream,
          userMedia: _userMedia,
          // Read at the stop: the camera opens again facing the way the call shows then.
          frontCamera: () => call.frontCamera,
        );
    }
  }

  /// Whether the share must stop in [next]; asked on every change of the state.
  bool mustStopIn(CallState next) {
    final target = _share.target;
    return target != null && !stands(next, target);
  }

  /// Whether the share there is goes to [callId]'s own video sender: its camera control is then
  /// the screen's to hold.
  bool holdsCallSender(String callId) => _share.target == CallScreenShareTarget(callId);

  /// The call sender the share there is went to on [callId], to read the far end's answers.
  CallSenderDestination? callSenderOf(String callId) =>
      holdsCallSender(callId) ? _share.destination as CallSenderDestination? : null;

  /// Whether the share there is goes to a room's video.
  bool get inRoom => _share.target is RoomScreenShareTarget;

  /// Marks the share as being stopped; `false` when there is none or a stop is on its way.
  bool markStopping() => _share.markStopping();

  /// Stops the share: its destination takes the screen off, then the capture is released.
  Future<ScreenShareStopped?> stop({Object? attempt}) => _share.stop(attempt: attempt);

  Future<void> dispose() => _share.dispose();
}
