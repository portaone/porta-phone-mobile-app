import 'package:flutter/widgets.dart';

import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/l10n/l10n.dart';

/// What the server's refusal of a merge means, in words the user can act on.
///
/// The wire carries a code, and some of the codes carry a diagnostic after a
/// colon; neither is something to put in front of a person. Where the reason
/// says nothing a user could do anything about, the text says only that the
/// calls could not be merged.
extension ConferenceRefusalReasonL10n on ConferenceRefusalReason {
  String l10n(BuildContext context) {
    switch (this) {
      case ConferenceRefusalReason.conferenceDisabled:
        return context.l10n.conferenceRefusal_conferenceDisabled;
      case ConferenceRefusalReason.conferenceAlreadyActive:
        return context.l10n.conferenceRefusal_conferenceAlreadyActive;
      case ConferenceRefusalReason.lineAlreadyInConference:
        return context.l10n.conferenceRefusal_lineAlreadyInConference;
      case ConferenceRefusalReason.notEnoughLines:
      case ConferenceRefusalReason.lineWithoutActiveCall:
      case ConferenceRefusalReason.noConference:
      case ConferenceRefusalReason.lineNotInConference:
        return context.l10n.conferenceRefusal_callsAreGone;
      case ConferenceRefusalReason.lineNotReady:
        return context.l10n.conferenceRefusal_lineNotReady;
      case ConferenceRefusalReason.roomCreateFailed:
      case ConferenceRefusalReason.attachFailed:
      case ConferenceRefusalReason.invalidMuted:
      case ConferenceRefusalReason.lineInConference:
      case ConferenceRefusalReason.unknown:
        return context.l10n.conferenceRefusal_unavailable;
    }
  }
}
