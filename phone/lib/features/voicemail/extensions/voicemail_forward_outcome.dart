import 'package:webtrit_phone/l10n/app_localizations.g.dart';

import '../models/voicemail_forward_outcome.dart';

extension VoicemailForwardOutcomeL10n on VoicemailForwardOutcome {
  /// What to say about a forward to [name] that did not go through.
  String failureText(AppLocalizations l10n, String name) => switch (this) {
    VoicemailForwardOutcome.tooLarge => l10n.voicemail_Snackbar_forwardTooLarge,
    VoicemailForwardOutcome.recipientFull => l10n.voicemail_Snackbar_forwardRecipientFull(name),
    VoicemailForwardOutcome.unavailable => l10n.voicemail_Snackbar_forwardUnavailable,
    VoicemailForwardOutcome.sent || VoicemailForwardOutcome.failed => l10n.voicemail_Snackbar_forwardFailed(name),
  };
}
