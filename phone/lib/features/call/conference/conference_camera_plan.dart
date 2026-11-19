/// What this client means to do with its camera in a room's video, and through
/// which call it takes part when the room is someone else's.
///
/// Used by `RoomVideo` next to `ConferenceVideoSession`: the session knows the
/// protocol and what is published now; this knows what the user asked for, which
/// outlives the app going to the background and coming back. Each method says
/// what the session is to do; the caller does it.
///
/// - [start]: the room's video begins - the host's own room, or an invitation
///   through the call on [invitedLine].
/// - [setCamera]: the camera button of the room.
/// - [pause] / [resume]: the app leaves the foreground and returns; the camera
///   is taken off the room meanwhile and put back if it was wanted.
/// - [end]: the room's video is over for this client.
class ConferenceCameraPlan {
  int? _invitedLine;
  bool _wanted = false;
  bool _paused = false;

  /// The line of the call through which this client takes part in somebody
  /// else's room (protocol section 19); `null` while it does not.
  int? get invitedLine => _invitedLine;

  /// Whether the user means the camera to be in the room.
  bool get cameraWanted => _wanted;

  /// Whether the camera is held back until the app returns to the foreground.
  bool get cameraPaused => _paused;

  /// The room's video begins with the camera on or off as [camera] says.
  /// Returns whether to publish now: not in the background, where the camera
  /// waits for [resume].
  bool start({required bool camera, required bool inBackground, int? invitedLine}) {
    _invitedLine = invitedLine;
    return setCamera(camera, inBackground: inBackground);
  }

  /// The user turned the room's camera on or off. Returns whether to publish
  /// now; when it returns false for [enabled], the camera waits for [resume].
  bool setCamera(bool enabled, {required bool inBackground}) {
    _wanted = enabled;
    _paused = enabled && inBackground;
    return enabled && !inBackground;
  }

  /// The app went to the background. Returns whether to unpublish: only a
  /// camera that is published, or on its way to it, has anything to take off.
  bool pause({required bool publishing}) {
    if (!publishing || !_wanted) return false;
    _paused = true;
    return true;
  }

  /// The app came back. Returns whether to publish again.
  bool resume() {
    if (!_paused) return false;
    _paused = false;
    return _wanted;
  }

  /// The room's video is over: nothing is wanted and nothing waits.
  void end() {
    _invitedLine = null;
    _wanted = false;
    _paused = false;
  }
}
