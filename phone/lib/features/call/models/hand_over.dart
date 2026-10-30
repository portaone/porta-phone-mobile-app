import 'active_call.dart';

/// The attended transfer the transfer menu offers: the held calls it lists,
/// any one of which the person can pick, and the one call each of them would
/// be handed over to.
///
/// Read from the state as a whole (see `CallState.handOverFor`) rather than
/// assembled by the menu, so the entries shown and the submit they lead to
/// rest on the same rule the bloc applies before it sends the transfer.
class HandOver {
  const HandOver({required this.replaceCall, required this.referorCalls});

  /// The call each listed call is connected with.
  final ActiveCall replaceCall;

  /// The held calls the menu lists, in the order of the calls; never empty.
  final List<ActiveCall> referorCalls;
}
