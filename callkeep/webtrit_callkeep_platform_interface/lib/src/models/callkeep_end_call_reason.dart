enum CallkeepEndCallReason {
  failed,
  remoteEnded,
  unanswered,
  answeredElsewhere,
  declinedElsewhere,
  missed,

  /// The call was ended while it was never presented in the Flutter app state - the remote party
  /// hung up an incoming call before it was registered in CallBloc (e.g. a push->foreground handoff
  /// where the caller gives up while signaling is still connecting). Distinct from [remoteEnded]:
  /// it signals that the app never knew about this call, so a later re-presentation of the same
  /// callId is a stale ghost (NOT a transfer-back, which always reuses a call the app did know).
  missedWhileConnecting,

  /// The user declined the incoming call on this device (the call screen, the system UI, a headset
  /// button), and the app knows it from its own decline request, not from the call's absence.
  /// Distinct from [missedWhileConnecting], which is inferred: the app never held the call. The
  /// platforms treat it as [missedWhileConnecting] for now, so the end of a declined call that the
  /// app held no longer in its state is kept as before; it is a separate value so that whoever
  /// reads an end can tell a decline from a call the app never saw.
  declinedByUser,
}

/// The behaviour the reasons share.
extension CallkeepEndCallReasonKeep on CallkeepEndCallReason {
  /// Whether the end is of a call the app no longer holds in its state - one it never held
  /// ([CallkeepEndCallReason.missedWhileConnecting]) or one the user declined
  /// ([CallkeepEndCallReason.declinedByUser]). The platforms keep such an end so that a late
  /// presentation of the same callId is dropped; the two reasons share that behaviour until what
  /// follows from a decline is decided on its own.
  bool get keepsEndWithoutAppState =>
      this == CallkeepEndCallReason.missedWhileConnecting || this == CallkeepEndCallReason.declinedByUser;
}
