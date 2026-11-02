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
  /// `update` request carrying an answer closes the update before it, an
  /// [UpdatingCallEvent] reached first is open. Offers the client sent itself
  /// and the events they produced say nothing - while an update is unanswered
  /// the server holds those back.
  ///
  /// An open update is the newest one, so its number is [count].
  late final PendingCallUpdate? pending = _findPending();

  PendingCallUpdate? _findPending() {
    for (final log in _logs) {
      if (log is CallRequestLog) {
        final request = log.callRequest;
        if (request is UpdateRequest && request.jsep['type'] == 'answer') return null;
      } else if (log is CallEventLog) {
        final event = log.callEvent;
        if (event is UpdatingCallEvent) return PendingCallUpdate(event: event, ordinal: count);
      }
    }
    return null;
  }
}
