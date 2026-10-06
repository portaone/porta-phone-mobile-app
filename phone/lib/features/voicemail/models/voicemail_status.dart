/// Where a read of a list of voice messages stands.
enum VoicemailStatus {
  /// Nobody has asked for the list yet. Not the same as [loaded] with nothing
  /// in it: that is an answer, and this is the absence of a question.
  initial,
  loading,
  loaded,
  featureNotSupported,
}
