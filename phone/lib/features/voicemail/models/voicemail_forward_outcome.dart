/// What came of sending a copy of a voicemail to a colleague.
///
/// The screen needs to say something different for each of these, and it should
/// not have to know the backend's error codes to work out which. The cubit
/// translates once, here, and the widget picks a sentence.
enum VoicemailForwardOutcome {
  /// The copy is in the recipient's mailbox.
  sent,

  /// The recording is bigger than forwarding allows. Retrying sends the same
  /// recording, so it is not offered.
  tooLarge,

  /// The recipient has as many forwarded messages as they are allowed. Also
  /// not worth retrying: nothing on this side can change it.
  recipientFull,

  /// The backend does not offer forwarding, or could not be reached at all.
  unavailable,

  /// Anything else, including a recipient who is no longer there.
  ///
  /// One sentence rather than one per code: past the three above, the
  /// difference does not change what the person can do about it, and a
  /// specific message for a case nobody can act on only reads as noise.
  failed;

  /// Whether trying again could plausibly end differently.
  bool get isRetryable => this == unavailable || this == failed;
}
