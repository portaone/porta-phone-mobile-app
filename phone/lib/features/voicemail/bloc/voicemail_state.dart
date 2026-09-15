part of 'voicemail_cubit.dart';

enum VoicemailStatus { loading, loaded, featureNotSupported }

// TODO(Serdun): DiagnosticableTreeMixin is required only because `foundation.dart`
// is imported transitively through DefaultErrorNotification (via material.dart).
// Remove this mixin once that indirect dependency is eliminated.
@freezed
class VoicemailState with _$VoicemailState, DiagnosticableTreeMixin {
  const VoicemailState({
    this.status = VoicemailStatus.loading,
    this.items = const [],
    this.trashedItems = const [],
    this.selectedVoicemailsIds = const [],
    this.filter = VoicemailFilter.all,
    this.filters = const [VoicemailFilter.all, VoicemailFilter.unheard],
    this.error,
  });

  @override
  final VoicemailStatus status;

  /// The mailbox as it is stored, which is every message that is not in the
  /// trash. Three of the four filters are this list with a condition applied.
  @override
  final List<Voicemail> items;

  /// The trash as the last fetch of it found it, empty whenever the screen is
  /// not showing the trash.
  ///
  /// Separate from [items] rather than mixed into it: the trash is fetched on
  /// demand and never stored, so anything reading the mailbox - the unheard
  /// count, the badge, a refresh - would otherwise have to remember to exclude
  /// it, and would be wrong the one time it forgot.
  @override
  final List<Voicemail> trashedItems;

  @override
  final List<String> selectedVoicemailsIds;

  /// Which view is on.
  @override
  final VoicemailFilter filter;

  /// Which views this mailbox offers, decided once from what the backend
  /// supports. A filter the backend cannot serve is absent rather than
  /// disabled, so nothing offers to show a list that cannot exist.
  @override
  final List<VoicemailFilter> filters;

  @override
  final Object? error;

  /// The messages the current filter shows.
  List<Voicemail> get visibleItems => switch (filter) {
    VoicemailFilter.all => items,
    VoicemailFilter.unheard => items.where((item) => !item.status.isRead).toList(),
    VoicemailFilter.saved => items.where((item) => item.saved == true).toList(),
    VoicemailFilter.trash => trashedItems,
  };

  /// How many messages are still unheard, which is counted over the whole
  /// mailbox rather than over the current view - it is what the New filter is
  /// offering, so it has to read the same under every filter.
  int get unheardCount => items.where((item) => !item.status.isRead).length;

  /// Status to show when the user is refreshing or updating the list of voicemails.
  bool get isRefreshing => status == VoicemailStatus.loading && visibleItems.isNotEmpty;

  /// Status to show when the user is loading the list of voicemails.
  bool get isInitializing => status == VoicemailStatus.loading && visibleItems.isEmpty && error == null;

  /// Status to show when the user is loading the list of voicemails and there are no items available.
  bool get isLoadedWithEmptyResult => status == VoicemailStatus.loaded && visibleItems.isEmpty && error == null;

  /// Status to show when the user is loading the list of voicemails and there is an error.
  bool get isLoadedWithError => status == VoicemailStatus.loaded && error != null && visibleItems.isEmpty;

  /// Status show when feature is not supported, adapter not supported.
  bool get isFeatureNotSupported => status == VoicemailStatus.featureNotSupported;

  /// Status to show when the user is loading the list of voicemails and there are items available.
  bool get isVoicemailsExists => visibleItems.isNotEmpty;

  bool get isMultipleVoicemailsSelection => selectedVoicemailsIds.isNotEmpty;
}
