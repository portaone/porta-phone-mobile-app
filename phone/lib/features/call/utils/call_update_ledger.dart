import 'package:signaling/signaling.dart';

/// How an attempt to answer an update ended.
enum CallUpdateAnswer {
  /// The server did not take an answer: the update was dropped, it carried
  /// no offer, the signaling was lost before the server replied, or handling
  /// failed on the way.
  notSent,

  /// The server replied to the client's answer with an error. The update is
  /// left as by [notSent]; the call's own renegotiation is then up to the
  /// retry the refusal schedules.
  refused,

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

  bool _answered = false;

  /// The update as a handshake showed it unanswered while this attempt was
  /// still open, see [CallUpdateLedger.askAgain].
  UpdatingCallEvent? _askedAgain;

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
///   next handshake that still shows it unanswered hands it over once more -
///   or the attempt hands it back itself, when such a handshake came while it
///   was still open;
/// - another update of the same call is another number, whatever it offers;
/// - a call that is over is forgotten with everything taken in for it.
class CallUpdateLedger {
  final Map<String, _CallUpdates> _calls = {};

  _CallUpdates _call(String callId) => _calls.putIfAbsent(callId, _CallUpdates.new);

  /// A handshake's log shows [count] updates of the call so far.
  void setObservedUpdateCount(String callId, int count) => _call(callId).observed = count;

  /// An update was heard live: the number it has in its call.
  int nextLiveUpdateOrdinal(String callId) => ++_call(callId).observed;

  /// Starts an attempt to handle the update. Null when the update is being
  /// handled at this moment or was answered: it must not be handled again.
  CallUpdateAttempt? begin(String callId, int ordinal) {
    final attempts = _call(callId).attempts;
    if (attempts.containsKey(ordinal)) return null;
    return attempts[ordinal] = CallUpdateAttempt._(callId, ordinal);
  }

  /// A handshake shows the update unanswered while an attempt of it is still
  /// open - an answer waiting for its reply on a session that is gone. Should
  /// that attempt end without an answer, [finish] hands [update] back: by then
  /// no handshake is left to hand it over.
  void askAgain(String callId, int ordinal, UpdatingCallEvent update) {
    final attempt = _calls[callId]?.attempts[ordinal];
    if (attempt != null && !attempt._answered) attempt._askedAgain = update;
  }

  /// Ends [attempt]. Answered, the update is never taken in again; otherwise
  /// it is free for another attempt, and the update a handshake asked for
  /// meanwhile ([askAgain]) is returned to be handed over again. An attempt
  /// of a call that was forgotten in the meantime leaves nothing behind.
  UpdatingCallEvent? finish(CallUpdateAttempt attempt, CallUpdateAnswer answer) {
    final attempts = _calls[attempt.callId]?.attempts;
    if (attempts == null || !identical(attempts[attempt.ordinal], attempt) || attempt._answered) return null;
    if (answer == CallUpdateAnswer.acknowledged) {
      attempt._answered = true;
      return null;
    }
    attempts.remove(attempt.ordinal);
    return attempt._askedAgain;
  }

  /// The call is over.
  void forget(String callId) => _calls.remove(callId);

  void clear() => _calls.clear();
}

/// What the ledger keeps for one call: how many updates it has counted, and
/// the attempt of each update taken in, open or answered.
class _CallUpdates {
  int observed = 0;
  final Map<int, CallUpdateAttempt> attempts = {};
}
