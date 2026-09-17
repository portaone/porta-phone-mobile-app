/// Which request survives when two features want somebody chosen at once.
///
/// Somebody cannot be choosing for two things at the same time, and the
/// ranking is the feature's own statement about what it is asking for rather
/// than the shell's knowledge of which features exist.
enum DestinationPickPrecedence {
  /// Whatever asked can wait: a message, a document, anything with nobody on
  /// the other end of it right now.
  ordinary,

  /// Somebody is on the line while this is being chosen. A request like this
  /// takes the floor from an ordinary one and cannot be pushed off it.
  live,
}
