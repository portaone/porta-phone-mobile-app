/// What came of an action over one message.
///
/// Three answers rather than a bool, because a refusal is not one thing. A
/// backend that says the message is not where the list had it has told us
/// something about the state and the list can be put right; one that fails for
/// any other reason has told us nothing, and guessing at the state after it
/// would be inventing an answer the backend did not give.
enum VoicemailActionOutcome {
  /// The backend did what was asked.
  done,

  /// The message is no longer where the list thinks it is - deleted from
  /// another device, emptied from the trash, acted on twice. The list has been
  /// re-read by the time this is returned.
  gone,

  /// The backend refused for some other reason, and what is on the server now
  /// is unknown. Nothing here was touched.
  failed,
}
