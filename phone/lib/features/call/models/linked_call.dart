import 'package:freezed_annotation/freezed_annotation.dart';

part 'linked_call.freezed.dart';

/// What a linked call is placed for.
enum LinkedCallPurpose {
  /// The second call of an attended transfer: the person talks to the new
  /// party first, then hands the anchor call over to them.
  attendedTransfer,
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
/// There is one at a time: a second one needs a second free line and a second
/// conversation to be about, and nothing asks for that.
@freezed
class LinkedCall with _$LinkedCall {
  const LinkedCall({
    required this.callId,
    required this.anchorCallId,
    required this.purpose,
    this.anchorWasLive = false,
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

  /// Why the linked call is ending, once that is known; null while it is
  /// under way.
  @override
  final LinkedCallFailure? failure;
}
