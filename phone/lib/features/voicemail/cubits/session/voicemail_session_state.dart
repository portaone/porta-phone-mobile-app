part of 'voicemail_session_cubit.dart';

// TODO(Serdun): DiagnosticableTreeMixin is required only because `foundation.dart`
// is imported. Remove this mixin once that dependency is eliminated.
@freezed
class VoicemailSessionState with _$VoicemailSessionState, DiagnosticableTreeMixin {
  const VoicemailSessionState({
    this.status = VoicemailStatus.loading,
    this.items = const [],
    this.unreadCount = 0,
    this.forwarderNames = const {},
    this.error,
  });

  /// Where the last read of the mailbox stands.
  @override
  final VoicemailStatus status;

  /// The mailbox as it is stored, which is every message that is not in the
  /// trash.
  @override
  final List<Voicemail> items;

  /// How many messages are waiting, as the repository counts them.
  @override
  final int unreadCount;

  /// Names for the colleagues who forwarded messages on, by their user id.
  ///
  /// Only the ones the address book knows. An id with nobody behind it stays
  /// out, and the tile shows the id: it is a poor name but a true one, and
  /// saying nothing would hide that the message was forwarded at all.
  @override
  final Map<String, String> forwarderNames;

  /// Why the last read of the mailbox did not go through, or null when it did.
  @override
  final Object? error;

  bool get isFeatureNotSupported => status == VoicemailStatus.featureNotSupported;
}
