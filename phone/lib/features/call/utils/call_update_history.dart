import 'package:signaling/signaling.dart';

/// An update of the far end the client still owes an answer to, as the log of
/// its call shows it.
final class PendingCallUpdate {
  const PendingCallUpdate({required this.event, required this.ordinal});

  final UpdatingCallEvent event;

  /// Which update of its call this is, counted from the call's start.
  final int ordinal;
}

/// The far end's updates in the log of one call.
///
/// An update has no id in the protocol, but it has a place: the server's log
/// of a call only grows until the call ends, so "the third update of this
/// call" is the same update in every handshake, however the entry is parsed
/// and whatever it offers. Everything that numbers updates reads the log
/// through here, so there is one rule for counting them.
///
/// The log is newest first.
final class CallUpdateHistory {
  CallUpdateHistory(this._logs);

  final List<CallLog> _logs;

  /// How many updates of the far end the log holds.
  late final int count = _logs.where((log) => log is CallEventLog && log.callEvent is UpdatingCallEvent).length;

  /// The update the client still owes an answer to, if the log has one.
  ///
  /// Of everything in the log only two entries decide: the client's own
  /// `update` request closes the update before it, an [UpdatingCallEvent]
  /// reached first is open. Which request closes which update is said by what
  /// the update carries: an update that carries an offer is answered with an
  /// answer, and one that carries no offer is answered with the offer the far
  /// end asked for. Requests the client sent for another reason - its own
  /// renegotiations - say nothing, and while an update is unanswered the
  /// server holds those back.
  ///
  /// An open update is the newest one, so its number is [count].
  late final PendingCallUpdate? pending = _findPending();

  PendingCallUpdate? _findPending() {
    // The client's own requests, newest first: only the one that came after
    // the update closes it.
    UpdateRequest? newestAnswer;
    UpdateRequest? newestOffer;
    for (final log in _logs) {
      if (log is CallRequestLog) {
        final request = log.callRequest;
        if (request is! UpdateRequest) continue;
        if (request.jsep['type'] == 'answer') {
          newestAnswer ??= request;
        } else if (request.jsep['type'] == 'offer') {
          newestOffer ??= request;
        }
      } else if (log is CallEventLog) {
        final event = log.callEvent;
        if (event is UpdatingCallEvent) {
          final closed = event.jsep == null ? newestOffer != null : newestAnswer != null;
          return closed ? null : PendingCallUpdate(event: event, ordinal: count);
        }
      }
    }
    return null;
  }
}
