/// Which messages the voicemail screen is showing.
///
/// Three of the four are views of one list. The mailbox is fetched whole, and
/// [all], [unheard] and [saved] are that same list with a condition applied, so
/// switching between them costs nothing and works with no network at all.
///
/// [trash] is the exception: it is a second list on the server, fetched when it
/// is asked for and never stored. That is the reason this is one control rather
/// than two - a person picking what to look at should not have to know which of
/// their choices happens to be a folder.
enum VoicemailFilter {
  /// Everything in the mailbox, which is what the screen opens on.
  all,

  /// The messages not yet heard.
  unheard,

  /// The messages kept, which the backend calls saved.
  saved,

  /// The messages moved to the trash and not yet removed for good.
  trash;

  /// Whether this view is served by a fetch of its own rather than by the
  /// stored mailbox.
  bool get isRemote => this == VoicemailFilter.trash;
}
