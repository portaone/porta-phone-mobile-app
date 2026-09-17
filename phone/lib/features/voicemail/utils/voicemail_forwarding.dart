import 'package:logging/logging.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/l10n/app_localizations.g.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/crashlytics_utils.dart';

import '../extensions/extensions.dart';
import '../models/models.dart';

final _logger = Logger('VoicemailForwarding');

/// Passes a message to a colleague and says what came of it.
///
/// It outlives the voicemail screen because it has to: the colleague is chosen
/// two sections away, and by the time the backend answers, the screen that
/// started this is long gone. Nothing of it is kept between forwards, so there
/// is no state to lose - the message and the colleague are the arguments, and
/// the answer goes to the one place that is still on screen.
///
/// The sentences are resolved when the person asks for a forward rather than
/// when the answer arrives, for the same reason: there is no context left to
/// resolve them against by then.
class VoicemailForwarding {
  const VoicemailForwarding({
    required VoicemailRepository repository,
    required DestinationPickingCubit picking,
    required AppLocalizations l10n,
  }) : _repository = repository,
       _picking = picking,
       _l10n = l10n;

  final VoicemailRepository _repository;
  final DestinationPickingCubit _picking;
  final AppLocalizations _l10n;

  Future<void> send(Voicemail message, Contact recipient) async {
    var outcome = VoicemailForwardOutcome.sent;
    try {
      await _repository.forwardVoicemail(message.id, toUserId: recipient.sourceId!);
    } catch (e, s) {
      // Only a refusal from the backend carries a meaning worth telling apart.
      // A socket that died on the way there says nothing about the message or
      // the colleague, so it is the plain failure.
      outcome = e is RequestFailure ? e.voicemailForwardOutcome : VoicemailForwardOutcome.failed;
      // A message too large and a colleague who is full are answers, not
      // faults: the request reached the backend and it said no for a reason
      // the person is about to be told. Only the rest is worth recording.
      if (outcome == VoicemailForwardOutcome.failed || outcome == VoicemailForwardOutcome.unavailable) {
        _logger.severe('Error forwarding voicemail with id ${message.id}: $e', e, s);
        CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailForwarding.send');
      }
    }

    _picking.announce(_report(outcome, message, recipient));
  }

  DestinationPickReport _report(VoicemailForwardOutcome outcome, Voicemail message, Contact recipient) {
    final name = recipient.displayTitle;

    if (outcome == VoicemailForwardOutcome.sent) {
      return DestinationPickReport(message: _l10n.voicemail_Snackbar_forwarded(name));
    }

    return DestinationPickReport(
      message: switch (outcome) {
        VoicemailForwardOutcome.tooLarge => _l10n.voicemail_Snackbar_forwardTooLarge,
        VoicemailForwardOutcome.recipientFull => _l10n.voicemail_Snackbar_forwardRecipientFull(name),
        VoicemailForwardOutcome.unavailable => _l10n.voicemail_Snackbar_forwardUnavailable,
        _ => _l10n.voicemail_Snackbar_forwardFailed,
      },
      isFailure: true,
      // Offered only where trying again could end differently. A recording
      // that is too big stays too big, and a colleague who is full stays full.
      // The colleague is not asked for again: the person already chose, and
      // the refusal was not about who they chose.
      retryLabel: outcome.isRetryable ? _l10n.voicemail_Label_retry : null,
      onRetry: outcome.isRetryable ? () => send(message, recipient) : null,
    );
  }
}
