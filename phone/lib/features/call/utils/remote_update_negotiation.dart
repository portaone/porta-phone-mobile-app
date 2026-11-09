import 'package:signaling/signaling.dart';

/// How an attempt to answer an update of the far end ended.
enum CallUpdateAnswer {
  /// The server did not take an answer: the update was dropped, it carried
  /// no offer, the signaling was lost before the server replied, or handling
  /// failed on the way.
  notSent,

  /// The server replied to the client's answer with an error. The call's own
  /// renegotiation is then up to the retry the refusal schedules.
  refused,

  /// The answer was lost with the signaling session that carried it, before
  /// the handshake of the next one came. That handshake decides: it shows
  /// the update again if the server never got the answer, and the reconnect
  /// renegotiates the call from it in any case.
  lost,

  /// The server replied to the client's answer (`updated`, or an interim
  /// `updating`): it took it, and from here on its own log shows the update
  /// as answered.
  acknowledged,
}

/// One attempt to answer one update of the far end.
///
/// Handed out by [RemoteUpdateNegotiation] and carried by the events of both
/// stages of the bloc's handler, so the stage that ends the attempt reports
/// on this very one and not on "the oldest of its call".
final class CallUpdateAttempt {
  CallUpdateAttempt._(this.callId, this.ordinal);

  final String callId;

  /// Which update of its call this is, counted from the call's start.
  final int ordinal;

  /// The update as a handshake showed it unanswered while this attempt was
  /// still open: handed over again should this attempt end unanswered.
  UpdatingCallEvent? _askedAgain;

  @override
  String toString() => 'update $ordinal of call $callId';
}

/// What the bloc does next for the far end's updates of a call.
sealed class RemoteUpdateStep {
  const RemoteUpdateStep();
}

/// Queue [update] for the handler, carrying [attempt].
final class AnswerUpdate extends RemoteUpdateStep {
  const AnswerUpdate(this.update, this.attempt);

  final UpdatingCallEvent update;
  final CallUpdateAttempt attempt;
}

/// Make the call's own offer, which was put off behind the far end's update.
final class OfferOwn extends RemoteUpdateStep {
  const OfferOwn(this.callId, this.lineId);

  final String callId;
  final int? lineId;
}

/// The far end's updates of every call, and the client's own offers that
/// wait behind them. A pure rule: the bloc tells it what happened and does
/// the step it returns; it sends nothing itself.
///
/// The protocol gives an update no id, and two ways bring the same one: live
/// while the socket is up, and from a handshake's log, which shows an update
/// the client did not answer. A handshake reports a call as the server saw
/// it when the socket connected, so it cannot tell an update the client is
/// answering, or has answered since, from one nobody answered. An update is
/// therefore named here by its call and its number among the call's updates
/// (see [CallUpdateHistory]), counted the way the log counts: the updates a
/// handshake's log shows, then one more for each heard live.
///
/// The rules, per call:
/// - an update is answered once: one being answered or answered already is
///   not handed over again, whether it comes live or from a log;
/// - an attempt that ends without an answer leaves the update free, and the
///   next handshake that still shows it hands it over once more - or the
///   attempt hands it back itself ([AnswerUpdate]) when such a handshake
///   came while it was still open;
/// - while an update is open, no offer of the client's own goes out: the
///   media server holds such an offer back behind the update, and nothing
///   answers it. A wanted offer is put off and made ([OfferOwn]) once the
///   call has no open update - unless the server refused the answer, when
///   the refusal's own randomized retry renegotiates the call, or the answer
///   was lost with its session, when the next handshake decides;
/// - a call restored with an update it missed answers that update rather
///   than making an offer, and makes its own offer only if the update is not
///   answered after all;
/// - another update of the same call is another number, whatever it offers;
/// - a call that is over is forgotten with everything about it, and so is
///   one a handshake no longer shows.
class RemoteUpdateNegotiation {
  final Map<String, _CallUpdates> _calls = {};

  _CallUpdates _call(String callId) => _calls.putIfAbsent(callId, _CallUpdates.new);

  /// A handshake shows the server's calls, with how many updates the log of
  /// each holds so far; those heard live after it are counted on top. A call
  /// it does not show is over on the server and is forgotten. A count below
  /// the one kept - a log entry that did not parse - keeps the higher one: a
  /// number already used is never given to a new update.
  void handshakeShows(Map<String, int> updateCounts) {
    _calls.removeWhere((callId, _) => !updateCounts.containsKey(callId));
    for (final MapEntry(key: callId, value: count) in updateCounts.entries) {
      final call = _call(callId);
      if (count > call.observed) call.observed = count;
    }
  }

  /// An update heard live, numbered as the next of its call. Null when it is
  /// being answered or was answered already: nothing is to be queued.
  CallUpdateAttempt? heardLive(UpdatingCallEvent update) {
    final call = _call(update.callId);
    return _begin(update.callId, ++call.observed);
  }

  /// A handshake's log shows [update], number [ordinal] of its call,
  /// unanswered. Null when it is being answered or was answered: then, if
  /// an answer to it is still waiting for its reply - on the session that is
  /// gone - the update is kept and handed back should that answer fail.
  CallUpdateAttempt? foundUnanswered(UpdatingCallEvent update, int ordinal) {
    final attempt = _begin(update.callId, ordinal);
    if (attempt != null) return attempt;
    _calls[update.callId]?.open[ordinal]?._askedAgain = update;
    return null;
  }

  /// A call restored after the app was gone, with [update] it missed. Its
  /// answer negotiates the new connection, so no offer of its own goes now;
  /// should the update end unanswered, nothing else would negotiate it, and
  /// the call's own offer on [lineId] goes then. Null when the update is
  /// handled already: the call then asks for its offer as any other.
  CallUpdateAttempt? restoredWith(UpdatingCallEvent update, int ordinal, int? lineId) {
    final attempt = foundUnanswered(update, ordinal);
    if (attempt != null) _call(update.callId).putOff ??= (lineId: lineId, unlessAnswered: true);
    return attempt;
  }

  /// The client wants an offer of its own for the call. True when it is put
  /// off behind an open update and is to be made by [ended]; false when it
  /// can go now, which also settles any offer put off before.
  bool putOffOffer(String callId, int? lineId) {
    final call = _calls[callId];
    if (call == null) return false;
    if (call.open.isEmpty) {
      call.putOff = null;
      return false;
    }
    call.putOff = (lineId: lineId, unlessAnswered: false);
    return true;
  }

  /// [attempt] ended with [answer]. Says what follows: the update handed
  /// back to be answered again, or the call's own offer that waited behind
  /// its updates. An attempt of a call forgotten meanwhile, or one ended
  /// already, gives nothing.
  List<RemoteUpdateStep> ended(CallUpdateAttempt attempt, CallUpdateAnswer answer) {
    final call = _calls[attempt.callId];
    if (call == null || !identical(call.open[attempt.ordinal], attempt)) return const [];
    call.open.remove(attempt.ordinal);
    if (answer == CallUpdateAnswer.acknowledged) {
      call.answered.add(attempt.ordinal);
    } else if (attempt._askedAgain case final update?) {
      return [AnswerUpdate(update, _begin(attempt.callId, attempt.ordinal)!)];
    }
    // A lost answer leaves the put-off offer to the next handshake: it opens
    // the update again, or the reconnect's own offer settles it.
    if (call.open.isNotEmpty || answer == CallUpdateAnswer.lost) return const [];
    final putOff = call.putOff;
    call.putOff = null;
    if (putOff == null) return const [];
    final make = switch (answer) {
      CallUpdateAnswer.acknowledged => !putOff.unlessAnswered,
      CallUpdateAnswer.notSent => true,
      CallUpdateAnswer.refused || CallUpdateAnswer.lost => false,
    };
    return make ? [OfferOwn(attempt.callId, putOff.lineId)] : const [];
  }

  /// The call is over.
  void forget(String callId) => _calls.remove(callId);

  void clear() => _calls.clear();

  CallUpdateAttempt? _begin(String callId, int ordinal) {
    final call = _call(callId);
    if (call.open.containsKey(ordinal) || call.answered.contains(ordinal)) return null;
    return call.open[ordinal] = CallUpdateAttempt._(callId, ordinal);
  }
}

/// What is kept for one call: how many updates it has counted, the attempts
/// still open, the updates answered, and the client's own offer put off
/// behind the open ones.
class _CallUpdates {
  int observed = 0;
  final Map<int, CallUpdateAttempt> open = {};
  final Set<int> answered = {};
  ({int? lineId, bool unlessAnswered})? putOff;
}
