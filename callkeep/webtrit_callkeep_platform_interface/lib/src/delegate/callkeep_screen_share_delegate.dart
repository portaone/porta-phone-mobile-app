/// Told about a screen share the app runs during a call (Android only).
abstract class CallkeepScreenShareDelegate {
  /// The share ended outside the app: the Stop action of its notification, or the system ending
  /// the capture. The foreground service of the share has stopped already; the app takes the
  /// capture off the call.
  void didEndScreenShare();
}
