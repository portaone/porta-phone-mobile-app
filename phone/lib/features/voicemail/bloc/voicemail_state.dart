part of 'voicemail_cubit.dart';

// TODO(Serdun): DiagnosticableTreeMixin is required only because `foundation.dart`
// is imported transitively through DefaultErrorNotification (via material.dart).
// Remove this mixin once that indirect dependency is eliminated.
/// What one voicemail screen holds for itself.
///
/// The mailbox is not here: it is the session's, in `VoicemailSessionState`.
/// What a widget shows is the two read together - see [VoicemailView].
@freezed
class VoicemailState with _$VoicemailState, DiagnosticableTreeMixin {
  const VoicemailState({
    this.filter = VoicemailFilter.all,
    this.filters = const [VoicemailFilter.all, VoicemailFilter.unheard],
    this.forwardSupported = false,
    this.selectedVoicemailsIds = const [],
    this.trashedItems = const [],
    this.trashStatus = VoicemailStatus.initial,
    this.trashError,
    this.busy = false,
  });

  /// Which view is on.
  @override
  final VoicemailFilter filter;

  /// Which views this mailbox offers, decided once from what the backend
  /// supports. A filter the backend cannot serve is absent rather than
  /// disabled, so nothing offers to show a list that cannot exist.
  @override
  final List<VoicemailFilter> filters;

  /// Whether a message can be passed on to a colleague.
  ///
  /// Carried rather than derived: unlike keeping and the trash, forwarding
  /// adds no view of its own, so there is no filter whose presence could
  /// stand in for it.
  @override
  final bool forwardSupported;

  @override
  final List<String> selectedVoicemailsIds;

  /// The trash as the last fetch of it found it, empty whenever the screen is
  /// not showing the trash.
  ///
  /// The screen's rather than the session's: the trash is fetched on demand
  /// and never stored, and it is read only while somebody is looking at it.
  @override
  final List<Voicemail> trashedItems;

  /// Where the last read of the trash stands; [VoicemailStatus.initial] while
  /// the trash is not being looked at. Apart from how the read of the mailbox
  /// stands, which is the session's: they are two reads of two lists.
  @override
  final VoicemailStatus trashStatus;

  /// Why the last read of the trash did not go through, or null when it did.
  @override
  final Object? trashError;

  /// Whether this screen is in the middle of something the person asked for -
  /// deleting, restoring, keeping, marking.
  @override
  final bool busy;

  /// Whether this mailbox can keep a message.
  ///
  /// The same fact as the Saved view being offered - that view exists because
  /// the flag does - so it is read off the one place the answer is stored
  /// rather than carried twice and allowed to disagree.
  bool get saveSupported => filters.contains(VoicemailFilter.saved);

  /// Whether this mailbox has a trash, which is the same fact as the Trash
  /// view being offered. See [saveSupported].
  bool get trashSupported => filters.contains(VoicemailFilter.trash);

  /// Whether the screen is showing the trash, where a message answers to a
  /// different pair of actions than anywhere else.
  bool get isShowingTrash => filter == VoicemailFilter.trash;

  bool get isMultipleVoicemailsSelection => selectedVoicemailsIds.isNotEmpty;
}
