import 'package:api/api.dart';

import 'package:webtrit_phone/features/voicemail/models/models.dart';

extension VoicemailForwardFailureExt on RequestFailure {
  /// What this refusal means for a forward that was in flight.
  ///
  /// Three of the backend's answers change what the person can do next and so
  /// are worth telling apart; the rest do not, and become one outcome rather
  /// than a sentence per status code.
  VoicemailForwardOutcome get voicemailForwardOutcome => switch (this) {
    VoicemailForwardAttachmentTooLargeException() => VoicemailForwardOutcome.tooLarge,
    VoicemailForwardLimitReachedException() => VoicemailForwardOutcome.recipientFull,
    EndpointNotSupportedException() => VoicemailForwardOutcome.unavailable,
    VoicemailNotConfiguredException() => VoicemailForwardOutcome.unavailable,
    _ => VoicemailForwardOutcome.failed,
  };
}
