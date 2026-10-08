part of 'voicemail_cubit.dart';

/// What a voicemail screen shows: the session's mailbox and the screen's own
/// state, read together.
///
/// Built where it is needed and stored nowhere. Every answer here is worked
/// out from the two states it is given, so there is no copy of the mailbox to
/// keep in step and no field that two owners write.
@immutable
class VoicemailView {
  const VoicemailView({required this.mailbox, required this.screen});

  final VoicemailSessionState mailbox;
  final VoicemailState screen;

  VoicemailFilter get filter => screen.filter;
  List<VoicemailFilter> get filters => screen.filters;
  List<String> get selectedVoicemailsIds => screen.selectedVoicemailsIds;
  List<Voicemail> get trashedItems => screen.trashedItems;
  bool get forwardSupported => screen.forwardSupported;
  bool get saveSupported => screen.saveSupported;
  bool get trashSupported => screen.trashSupported;
  bool get isShowingTrash => screen.isShowingTrash;
  bool get isMultipleVoicemailsSelection => screen.isMultipleVoicemailsSelection;

  /// The messages the current filter shows.
  ///
  /// New also shows what was heard by listening to it from New
  /// ([VoicemailState.heardByListening]): the person is going through what is
  /// new, and a list that drops each message as it starts cannot be gone
  /// through at all.
  List<Voicemail> get visibleItems => switch (screen.filter) {
    VoicemailFilter.all => mailbox.items,
    VoicemailFilter.unheard =>
      mailbox.items.where((item) => !item.status.isRead || screen.heardByListening.contains(item.id)).toList(),
    VoicemailFilter.saved => mailbox.items.where((item) => item.saved == true).toList(),
    VoicemailFilter.trash => screen.trashedItems,
  };

  /// What to show for who passed [voicemail] along, or null when nobody did.
  String? forwarderOf(Voicemail voicemail) {
    final forwardedBy = voicemail.forwardedBy;
    if (forwardedBy == null) return null;

    return mailbox.forwarderNames[forwardedBy] ?? forwardedBy;
  }

  /// Where passing [voicemail] on stands, or null when there is nothing to
  /// show about it.
  ///
  /// Nothing in the trash: a message there answers to restoring and deleting
  /// only, and a mark it could not act on would be noise.
  VoicemailForward? forwardOf(Voicemail voicemail) => isShowingTrash ? null : mailbox.forwards[voicemail.id];

  /// How many messages are still unheard, which is counted over the whole
  /// mailbox rather than over the current view - it is what the New filter is
  /// offering, so it has to read the same under every filter.
  int get unheardCount => mailbox.items.where((item) => !item.status.isRead).length;

  /// The read behind the list on screen: the trash's while the trash is
  /// shown, the mailbox's otherwise.
  VoicemailStatus get _readStatus => isShowingTrash ? screen.trashStatus : mailbox.status;

  Object? get _readError => isShowingTrash ? screen.trashError : mailbox.error;

  /// Whether the list on screen is being read, or the screen is in the middle
  /// of something the person asked for.
  bool get isLoading => _readStatus == VoicemailStatus.loading || screen.busy;

  /// Status to show when the user is refreshing or updating the list of voicemails.
  bool get isRefreshing => isLoading && visibleItems.isNotEmpty;

  /// Status to show when the user is loading the list of voicemails.
  bool get isInitializing => isLoading && visibleItems.isEmpty && _readError == null;

  /// Whether the list the current view is cut from holds nothing at all: the
  /// trash while the trash is shown, the whole mailbox otherwise.
  bool get _nothingWasRead => isShowingTrash ? screen.trashedItems.isEmpty : mailbox.items.isEmpty;

  /// Status to show when a read failed and left nothing to show.
  ///
  /// Asked of the list that was read, not of the view over it. A read that
  /// failed over a mailbox with messages in it is said in passing and the
  /// messages stay; a view of that mailbox that happens to match none of them
  /// - nothing kept, nothing new - is an empty view, not a failed read.
  bool get isLoadedWithError => !isLoading && _readError != null && _nothingWasRead;

  /// Status show when feature is not supported, adapter not supported.
  ///
  /// Either read can find it out, and it is true of the account rather than
  /// of the list that happened to be asked for.
  bool get isFeatureNotSupported =>
      mailbox.isFeatureNotSupported || screen.trashStatus == VoicemailStatus.featureNotSupported;

  /// Status to show when there are items available.
  bool get isVoicemailsExists => visibleItems.isNotEmpty;
}
