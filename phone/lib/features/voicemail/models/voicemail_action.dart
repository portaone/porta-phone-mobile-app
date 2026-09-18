/// Everything that differs between the five per-message actions, declared
/// rather than passed in at each call.
///
/// What they have in common - the screen showing work, the reading of a
/// refusal, what may be concluded from it - is written once and reads the same
/// for all of them; only these two columns are per action.
enum VoicemailAction {
  remove('removeVoicemail'),
  restore('restoreVoicemail', rereadsTrash: true),
  removePermanently('removeVoicemailPermanently', rereadsTrash: true),
  toggleSeen('toggleSeenStatus'),
  toggleSaved('toggleSavedStatus');

  const VoicemailAction(this.name, {this.rereadsTrash = false});

  /// What a log line and a crash report are filed under.
  final String name;

  /// Whether it changes what the trash holds.
  ///
  /// The trash keeps no stored copy that could be corrected in place, so while
  /// it is what is on screen it is read again rather than adjusted.
  final bool rereadsTrash;
}
