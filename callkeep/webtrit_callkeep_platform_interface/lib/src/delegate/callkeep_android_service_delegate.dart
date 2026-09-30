/// Callkeep background call delegate
abstract class CallkeepBackgroundServiceDelegate {
  /// Perform background answer
  void performAnswerCall(String callId);

  /// Perform background call end
  void performEndCall(String callId);

  /// Callkeep no longer needs this session for [callId]: the app holds the
  /// call now, or it ended through another handler. The session finishes the
  /// work it started and returns from its callback; nothing is sent to the
  /// server. Only this confirmation, not an Activity on screen or a connected
  /// WebSocket, says that the call's events reach the app.
  void performHandoff(String callId);
}
