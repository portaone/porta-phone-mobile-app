/// Who ended a call: carried by `performEndCall` so the app does not have to guess the
/// initiator, and passed to `endCall` so an end the app asks for on the user's behalf comes
/// back as the user's.
enum CallkeepEndedBy {
  /// A person ended the call on this device: the system call UI (Android Telecom `onReject`,
  /// a hang-up of an active call by a headset, Bluetooth device or the system UI, which Telecom
  /// delivers as a disconnect with no cause), the Decline action of the incoming-call
  /// notification, or the end button of the iOS CallKit UI. Also an end the app asked for on
  /// the user's behalf (`endCall` with [user]), such as a tap on the app's own call screen.
  user,

  /// The app asked for the end on its own (`endCall` with the default [app]): a teardown, a
  /// queued call dropped, a call released by the app.
  app,

  /// The platform ended the call - a ring timeout, Telecom refusing or failing the connection,
  /// a connection that could not be found, a hang-up the plugin synthesized - or the initiator
  /// is not known.
  system,
}
