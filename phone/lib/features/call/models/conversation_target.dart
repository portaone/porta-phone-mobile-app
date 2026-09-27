import 'package:equatable/equatable.dart';

/// One of the two conversations the screen of a room shows: the room itself, or
/// a single call standing outside it.
///
/// It names what was asked for, which is not what the state says yet. The hold
/// or unhold that carries a switch between the two takes a round trip to the
/// server, and until it comes back the wanted conversation is recorded nowhere
/// else - the calls still read the way they did before the tap.
///
/// A value type, so the tap that asked for a switch already under way is
/// recognised as the same request by [==] rather than by comparing a pair of
/// fields wherever that question comes up.
class ConversationTarget extends Equatable {
  /// The room, whichever of its legs was tapped: the legs are one conversation.
  const ConversationTarget.room() : callId = null;

  /// The call [callId], which stands outside the room.
  const ConversationTarget.outside(String this.callId);

  /// The call this names, or `null` when it names the room.
  final String? callId;

  /// Whether the room is meant rather than a call outside it.
  bool get isRoom => callId == null;

  @override
  List<Object?> get props => [callId];
}
