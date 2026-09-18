import 'package:api/api.dart';

import 'package:webtrit_phone/features/voicemail/models/models.dart';

extension VoicemailActionFailureExt on RequestFailure {
  /// Whether the backend is saying the message is not where the list has it.
  ///
  /// The list is drawn from what was true when it was read, and a mailbox can
  /// move on: deleted from another device or from the IVR, emptied out of the
  /// trash, acted on twice. The backend answers that with 404 or 410 for the
  /// message itself, and that is the one refusal that says something about the
  /// state rather than about the request.
  ///
  /// Two 4xx answers are deliberately not it. A route this deployment does not
  /// have, and a mailbox that was never configured, are both about the
  /// backend's shape rather than about this message - and the first arrives as
  /// a 404 of its own, because these calls are declared optional.
  ///
  /// A backend that failed on its own side is not it either, and does not need
  /// excluding here: it arrives as a [ServerFailureException] carrying its 5xx,
  /// which is a name for "nothing follows from this" rather than a status to
  /// be read.
  bool get isVoicemailGone {
    if (this is EndpointNotSupportedException || this is VoicemailNotConfiguredException) return false;

    return statusCode == HttpStatus.notFound || statusCode == HttpStatus.gone;
  }
}

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
