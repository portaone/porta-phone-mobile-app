import 'package:equatable/equatable.dart';

/// Where a screen share stands, for the screen; see `ScreenShare`.
enum ScreenShareStatus {
  /// Asked for: the consent, the service or the capture is under way, nothing is sent yet.
  starting,

  /// The screen goes to the far end, or to the room, in place of the camera.
  sharing,
}

/// Where the screen of a share goes; fixed when the share begins.
sealed class ScreenShareTarget extends Equatable {
  const ScreenShareTarget();
}

/// The call's own video sender: an ordinary call.
final class CallScreenShareTarget extends ScreenShareTarget {
  const CallScreenShareTarget(this.callId);

  final String callId;

  @override
  List<Object?> get props => [callId];
}

/// The room's video: the room this client hosts ([invitedCallId] `null`, whichever leg asked), or
/// the room the far end of [invitedCallId] invited this client to.
final class RoomScreenShareTarget extends ScreenShareTarget {
  const RoomScreenShareTarget({this.invitedCallId});

  final String? invitedCallId;

  /// Whether it is the room this client hosts.
  bool get hosted => invitedCallId == null;

  @override
  List<Object?> get props => [invitedCallId];
}

/// The one screen share there is, as the state knows it: where it goes and where it stands.
class ScreenShareState extends Equatable {
  const ScreenShareState({required this.target, required this.status});

  final ScreenShareTarget target;
  final ScreenShareStatus status;

  /// Whether it goes to a room's video rather than to a call's sender.
  bool get toRoom => target is RoomScreenShareTarget;

  @override
  List<Object?> get props => [target, status];
}
