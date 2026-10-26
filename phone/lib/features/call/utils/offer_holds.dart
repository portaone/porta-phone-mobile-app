/// What a hold or resume of a call does, given whether the call is held by
/// its own offer (`RTCPeerConnectionOfferHold`).
enum OfferHoldStep {
  /// Send the hold or unhold to the server, as for any call.
  send,

  /// The call is already held by its offer: nothing to send.
  nothing,

  /// Give the microphone back first; the unhold goes once that offer is
  /// answered ([OfferHolds.takeUnhold]).
  resumeFirst,
}

/// Decides how a call restored held after a cold restart is held and resumed.
///
/// Such a call is held by its offer, and the gateway still counts it on hold:
/// a hold has nothing to send, and the gateway would answer one without
/// sending it. A resume renegotiates the microphone first and sends the
/// unhold once that offer is answered: the gateway refuses an update during
/// the re-INVITE of an unhold, which held the audio back for seconds.
///
/// The bloc supplies whether the call is held by its offer and carries out
/// the step; the connection's media stays with the bloc.
class OfferHolds {
  final Set<String> _unholdOnAnswer = {};

  /// The step for a hold ([onHold]) or resume of [callId].
  OfferHoldStep onSetHeld(String callId, {required bool onHold, required bool heldByOffer}) {
    if (!heldByOffer) return OfferHoldStep.send;
    if (onHold) return OfferHoldStep.nothing;
    _unholdOnAnswer.add(callId);
    return OfferHoldStep.resumeFirst;
  }

  /// Whether an answer to an offer of [callId] is the one a resume waits
  /// for, so its unhold is to be sent now. Given out once.
  bool takeUnhold(String callId) => _unholdOnAnswer.remove(callId);

  void callRemoved(String callId) => _unholdOnAnswer.remove(callId);
}
