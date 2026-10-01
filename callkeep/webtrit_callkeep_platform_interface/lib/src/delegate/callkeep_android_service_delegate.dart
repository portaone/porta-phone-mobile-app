/// What callkeep tells a push session about the call it presented (Android only).
///
/// The session is the Dart callback a push starts; the plugin keeps the
/// incoming-call service up until that callback's future completes.
abstract class CallkeepBackgroundServiceDelegate {
  /// The user answered [callId] from the push notification, or Telecom
  /// reported the answer. The session remembers the answer and leaves the
  /// live connection to the Activity, which adopts it; callkeep confirms the
  /// handoff with [performHandoff] once the app's delegate has the call.
  void performAnswerCall(String callId);

  /// The ringing phase of [callId] ended with an end nobody reported yet:
  /// the user declined from the notification, or Telecom ended the call. The
  /// session declines it on the server, records it and finishes; the service
  /// stops on its future. Not sent for an end the app reported itself - that
  /// arrives as [performHandoff].
  void performEndCall(String callId);

  /// Callkeep no longer needs this session for [callId]: the app holds the
  /// call now, or it ended through another handler. The session finishes the
  /// work it started and returns from its callback; nothing is sent to the
  /// server. Only this confirmation, not an Activity on screen or a connected
  /// WebSocket, says that the call's events reach the app.
  void performHandoff(String callId);
}
