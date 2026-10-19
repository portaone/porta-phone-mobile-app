/// Whether the control that calls somebody into the conversation is shown, and
/// whether it acts.
enum AddParticipantAvailability {
  /// The server cannot build a room, so there is nothing to bring anybody into.
  hidden,

  /// Shown but inert: the conversation cannot take somebody now.
  unavailable,

  /// Shown but inert, and it says why: every main line is taken.
  noFreeLine,

  available;

  bool get shown => this != hidden;

  bool get enabled => this == available;
}
