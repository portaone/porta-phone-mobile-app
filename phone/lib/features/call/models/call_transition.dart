/// An operation on one call that the server has not answered yet.
///
/// Each of these was a marker of its own - one a flag on the call, one a set
/// beside the bloc - set on a single path and cleared on two or three others,
/// with every rule that reads what a call carries having to know about both. A
/// call is only ever in one of them, and they are the same shape: one call,
/// waiting for one acknowledgement. So they are one value, and the rules read
/// the state instead of asking around.
enum CallTransition {
  /// The server dropped this leg from the room and it is on its way to being
  /// an ordinary held call: the hold has been asked for and not answered yet.
  ///
  /// `held` would be a lie until it is - the call is live meanwhile - and the
  /// room must not stand aside for a call that is on its way out of it, or a
  /// leg leaving would silence the room for everybody still in it.
  leavingRoom,

  /// This leg left the room while the host was on a call outside it - the
  /// room was given up, or the server dropped the leg from it - and came back
  /// as an ordinary call. It stays silent both ways until a resume the server
  /// acknowledged: a hold can be delayed or refused, and giving the audio back
  /// on the strength of a request alone would re-open the leak the room's
  /// parking exists to close.
  releasedFromRoom,
}
