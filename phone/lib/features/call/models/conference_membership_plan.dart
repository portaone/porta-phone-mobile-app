import 'package:equatable/equatable.dart';

/// What the server's participant list means for the room this client holds.
///
/// The list is the server's account of the room and arrives on every update
/// and on every handshake; this is the difference between it and what the
/// client has, counted in one place and carried out in another. Counting and
/// doing used to be the same loop, and the order things are done in is a rule
/// of its own - the group is declared before any hold - so the two are worth
/// keeping apart: this says what changed, the caller decides in what order to
/// act on it.
class ConferenceMembershipPlan extends Equatable {
  const ConferenceMembershipPlan({
    required this.legs,
    required this.adopted,
    required this.vanished,
    required this.unheld,
    required this.muteChanges,
  });

  /// The room's membership after the list: every listed participant this
  /// client still has a call for, by line.
  final Map<String, int> legs;

  /// Legs the server counts that this client did not record itself - an add
  /// whose acknowledgement was lost, or a list after a reconnect. Their own
  /// connections must go quiet: membership and where the audio actually goes
  /// cannot disagree.
  final List<String> adopted;

  /// Legs this client recorded that the list no longer names. They are calls
  /// again, and the room is what the host hears, so each is held - after the
  /// group has been re-declared, which is what lets one leave it.
  final List<String> vanished;

  /// Listed calls this client still shows as held. The server un-holds a leg
  /// as it joins and sends no event for it, so the flag follows the list.
  final List<String> unheld;

  /// What each leg is to be told about its own room-wide mute, and only where
  /// that changed - the list is re-declared often, and repeating an unchanged
  /// mute to every participant each time would be chatter.
  final Map<String, bool> muteChanges;

  @override
  List<Object?> get props => [legs, adopted, vanished, unheld, muteChanges];
}
