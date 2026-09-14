import '../models/models.dart';

extension ActiveCallRingback on ActiveCall {
  /// Whether this call still wants the app's own ringback tone.
  ///
  /// The tone belongs to the outgoing ringing phase only: once the remote side
  /// streams audio of its own the bundled tone would play on top of it, and a
  /// call that was answered or ended does not want it either. Incoming calls
  /// never want it - they have their own ringtone.
  bool get shouldPlayLocalRingback => isOutgoing && !earlyMedia && !wasAccepted && !wasHungUp;
}

extension ActiveCallListAutoCompact on List<ActiveCall> {
  /// Whether the call itself allows the controls to auto-compact (auto-hide /
  /// Compact Mode): a connected call with video coming in from the far side.
  ///
  /// Only the far side counts. The controls get out of the way of the picture
  /// of the other person, and that picture is there whether or not the own
  /// camera is on; a one-way video call is watched the same as a two-way one.
  /// Whether the picture actually renders - a far side that announces video
  /// but sends black frames - is not known here; the screen that probes the
  /// frames adds that condition on top.
  bool get shouldAutoCompact {
    if (isEmpty) return false;

    // Consider only the foreground active call (the call currently shown to the user).
    // Keep auto-compact disabled for audio-only foreground calls, even if a call on another line has video.
    final activeCall = current;

    if (activeCall.wasHungUp) return false;
    if (activeCall.processingStatus != CallProcessingStatus.connected) return false;

    return activeCall.remoteVideo;
  }

  /// Whether the call controls may hide themselves after a few idle seconds.
  ///
  /// Never when something demands they stay visible - hidden controls leave the
  /// accessibility tree, so hanging up, muting and going back stop existing,
  /// and all that is left is the screen-wide way of bringing them back. What
  /// counts as such a demand is up to the caller.
  bool shouldAutoHideControls({required bool keepControlsVisible}) => !keepControlsVisible && shouldAutoCompact;
}
