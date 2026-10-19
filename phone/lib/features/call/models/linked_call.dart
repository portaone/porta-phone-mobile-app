import 'package:freezed_annotation/freezed_annotation.dart';

import 'active_call.dart';

part 'linked_call.freezed.dart';

/// What a linked call is placed for.
enum LinkedCallPurpose {
  /// The second call of an attended transfer: the person talks to the new
  /// party first, then hands the anchor call over to them.
  attendedTransfer,

  /// A call that brings somebody into the conversation: once answered it is
  /// merged with the anchor call, or added to the room the anchor is a leg of.
  join,
}

/// Why a linked call ended without doing what it was placed for.
///
/// Recorded where the reason is known - a hangup carries a code, a cancel is
/// the person's own - and read once the linked call is gone, which is the one
/// moment every way of failing shares.
enum LinkedCallFailure {
  /// The person gave up on it.
  cancelled,

  /// The other party was busy.
  busy,

  /// The other party declined.
  declined,

  /// Nobody answered.
  unanswered,

  /// Anything else: the call could not be placed, its media failed, the
  /// server refused it. Whatever said so has already told the person.
  failed;

  /// What a hangup of the linked call before it was answered says about it,
  /// from the hangup code: busy (486, 600), declined (603), or not answered -
  /// the switch gave up ringing (480, 408) or the ringing was stopped (487).
  static LinkedCallFailure fromHangup(int code) => switch (code) {
    486 || 600 => busy,
    603 => declined,
    480 || 408 || 487 => unanswered,
    _ => failed,
  };
}

/// A call placed on behalf of a conversation that is already up - the anchor
/// call - and tied to it for as long as it is being placed.
///
/// The link is the one thing that says what the new call is for. Without it a
/// call placed from the call screen is an ordinary outgoing call: nothing
/// knows which call it was placed for, and when it fails the anchor is left on
/// hold with nothing to take it off.
///
/// The anchor can be a leg of the room when the call joins it ([intoRoom]):
/// the room is addressed through its legs everywhere else too, and the leg
/// then stands for the room rather than for the one person on it.
///
/// There is one at a time: a second one needs a second free line and a second
/// conversation to be about, and nothing asks for that.
@freezed
class LinkedCall with _$LinkedCall {
  const LinkedCall({
    required this.callId,
    required this.anchorCallId,
    required this.purpose,
    this.anchorWasLive = false,
    this.intoRoom = false,
    this.awaitingRoom = false,
    this.failure,
  });

  /// The call that was placed.
  @override
  final String callId;

  /// The call it was placed for.
  @override
  final String anchorCallId;

  @override
  final LinkedCallPurpose purpose;

  /// Whether the anchor was live, not on hold, when the linked call was
  /// placed. Placing a call holds the anchor, and only a hold the link put on
  /// is the link's to take off when the call fails.
  @override
  final bool anchorWasLive;

  /// Whether the call joins the room the anchor was a leg of when it was
  /// placed, rather than the anchor call alone. Read from the moment of
  /// placing: the leg may leave the room while the call rings, and the room is
  /// still what the call was placed for.
  ///
  /// The room is not held for the call, it stands aside while a call outside
  /// it is up and comes back by itself once there is none, so a failed call
  /// has nothing of it to give back.
  @override
  final bool intoRoom;

  /// Whether the call was answered while the room it joins could not take a
  /// call - still assembling, or rejoining after a lost connection. It joins
  /// once the room is up again.
  @override
  final bool awaitingRoom;

  /// Why the linked call is ending, once that is known; null while it is
  /// under way.
  @override
  final LinkedCallFailure? failure;

  /// The linked call among [calls], once it has been answered; null before
  /// that, or when it is not an attended transfer's second call.
  ///
  /// This is the call an attended transfer hands the anchor over to, and the
  /// one rule for it: a menu that offered the hand-over on one reading and a
  /// submit that refused it on another would leave a dead entry.
  ActiveCall? answeredTransferCallIn(Iterable<ActiveCall> calls) {
    if (purpose != LinkedCallPurpose.attendedTransfer) return null;
    for (final call in calls) {
      if (call.callId == callId) return call.wasAccepted ? call : null;
    }
    return null;
  }
}
