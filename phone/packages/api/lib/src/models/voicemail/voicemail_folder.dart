/// Which side of the trash a voicemail listing asks for.
///
/// These are the only two folders there are, and they never overlap: a trashed
/// message is out of the inbox entirely rather than merely marked. New and Saved
/// are NOT folders - the mailbox has none - so a client builds those from an
/// [VoicemailFolder.inbox] listing itself, which is what the endpoint being
/// unpaginated is there to make reasonable.
enum VoicemailFolder {
  inbox,
  trash;

  /// The wire value, or null for the default the backend assumes when the
  /// parameter is absent.
  String? get queryValue => switch (this) {
    VoicemailFolder.inbox => null,
    VoicemailFolder.trash => 'trash',
  };
}
