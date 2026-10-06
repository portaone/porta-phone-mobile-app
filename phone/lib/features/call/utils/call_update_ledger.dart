/// How an attempt to answer an update ended.
enum CallUpdateAnswer {
  /// The server did not take an answer: the update was dropped, it carried
  /// no offer, the signaling was lost before the server replied, the server
  /// refused it, or handling failed on the way.
  notSent,

  /// The server replied to the client's answer (`updated`, or an interim
  /// `updating`): it took it, and from here on its own log shows the update
  /// as answered.
  acknowledged,
}

/// One attempt to handle one update of the far end.
///
/// Handed out by [CallUpdateLedger.begin] and carried by the events of both
/// stages of the handler, so the stage that ends the attempt reports on this
/// very one and not on "the oldest of its call".
final class CallUpdateAttempt {
  CallUpdateAttempt._(this.callId, this.ordinal);

  final String callId;

  /// Which update of its call this is, counted from the call's start.
  final int ordinal;

  @override
  String toString() => 'update $ordinal of call $callId';
}

/// Which updates of the far end the client has taken in, per call, and how
/// the attempt to answer each ended.
///
/// A handshake reports a call as the server saw it when the socket
/// connected, and the session the client keeps beside it holds the events
/// heard since but not the client's own requests. So a plan made from either
/// cannot tell an update the client is answering, or has answered since,
/// from one nobody answered. This ledger tells them apart.
///
/// An update is named by its call and its number among the call's updates
/// (see [CallUpdateHistory]). The client counts the way the log does: the
/// updates a handshake's log shows, then one more for each heard live. So:
/// - an update being handled or answered is not taken in again, whether it
///   comes live or from a log;
/// - an attempt that ended without an answer leaves the update free, and the
///   next handshake that still shows it unanswered hands it over once more;
/// - another update of the same call is another number, whatever it offers;
/// - a call that is over is forgotten with everything taken in for it.
class CallUpdateLedger {
  final Map<String, int> _observedCount = {};
  final Set<CallUpdateAttempt> _open = {};
  final Map<String, Set<int>> _answered = {};

  /// A handshake's log shows [count] updates of the call so far.
  void setObservedUpdateCount(String callId, int count) => _observedCount[callId] = count;

  /// An update was heard live: the number it has in its call.
  int nextLiveUpdateOrdinal(String callId) => _observedCount[callId] = (_observedCount[callId] ?? 0) + 1;

  /// Starts an attempt to handle the update. Null when the update is being
  /// handled at this moment or was answered: it must not be handled again.
  CallUpdateAttempt? begin(String callId, int ordinal) {
    if (_isBeingHandled(callId, ordinal) || (_answered[callId]?.contains(ordinal) ?? false)) return null;
    final attempt = CallUpdateAttempt._(callId, ordinal);
    _open.add(attempt);
    return attempt;
  }

  /// Ends [attempt]. Answered, the update is never taken in again; otherwise
  /// it is free for another attempt. An attempt of a call that was forgotten
  /// in the meantime leaves nothing behind.
  void finish(CallUpdateAttempt attempt, CallUpdateAnswer answer) {
    if (!_open.remove(attempt)) return;
    if (answer == CallUpdateAnswer.acknowledged) {
      _answered.putIfAbsent(attempt.callId, () => {}).add(attempt.ordinal);
    }
  }

  bool _isBeingHandled(String callId, int ordinal) =>
      _open.any((attempt) => attempt.callId == callId && attempt.ordinal == ordinal);

  /// The call is over.
  void forget(String callId) {
    _observedCount.remove(callId);
    _open.removeWhere((attempt) => attempt.callId == callId);
    _answered.remove(callId);
  }

  void clear() {
    _observedCount.clear();
    _open.clear();
    _answered.clear();
  }
}
