/// Where a screen share of a call stands, for the screen; see `ScreenShare`.
enum ScreenShareStatus {
  /// Asked for: the consent, the service or the capture is under way, nothing is sent yet.
  starting,

  /// The screen goes to the far end in place of the camera.
  sharing,
}
