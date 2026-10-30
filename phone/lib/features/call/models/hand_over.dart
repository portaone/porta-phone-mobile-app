import 'active_call.dart';

/// The attended transfers the transfer menu offers: one entry per call it
/// lists, each naming the two calls a pick of it connects.
///
/// Read from the state as a whole (see `CallState.handOverFor`) rather than
/// assembled by the menu, so the entries shown and the submit they lead to
/// rest on the same rule the bloc applies before it sends the transfer.
class HandOver {
  const HandOver(this.entries);

  /// The entries in the order of the calls; never empty.
  final List<HandOverEntry> entries;

  /// The calls the menu lists, one per entry.
  List<ActiveCall> get listedCalls => [for (final entry in entries) entry.listedCall];

  /// The entry of [listedCall], or null when the menu does not list it.
  HandOverEntry? entryOf(ActiveCall listedCall) {
    for (final entry in entries) {
      if (entry.listedCall.callId == listedCall.callId) return entry;
    }
    return null;
  }
}

/// One entry of the transfer menu: the call it names, and the transfer a pick
/// of it sends - [referorCall] handed over to [replaceCall]. The named call is
/// the other one of the pair, never the call on screen.
class HandOverEntry {
  const HandOverEntry({required this.listedCall, required this.referorCall, required this.replaceCall});

  final ActiveCall listedCall;
  final ActiveCall referorCall;
  final ActiveCall replaceCall;
}
