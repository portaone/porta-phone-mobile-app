import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/l10n/app_localizations.g.dart';
import 'package:webtrit_phone/models/models.dart';

import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../models/models.dart';

/// Passes a message to a colleague and says what came of it.
///
/// The request itself, and the mark a message carries while it is out or
/// after it was refused, belong to [VoicemailSessionCubit], which lives as
/// long as the session does. This is the part that cannot live there: the
/// sentences. They are resolved when the person asks for the forward rather
/// than when the answer arrives, because the colleague is chosen two sections
/// away and by then the screen that started this, and its context, can be
/// gone. The answer goes to the one place that is still on screen.
///
/// A refusal is said once, with a way to try again at hand. The sentence
/// passes; what stays is the mark on the message, and trying again later is
/// in the message's own menu.
class VoicemailForwarding {
  const VoicemailForwarding({
    required DestinationPickingCubit picking,
    required VoicemailSessionCubit session,
    required AppLocalizations l10n,
  }) : _picking = picking,
       _session = session,
       _l10n = l10n;

  final DestinationPickingCubit _picking;
  final VoicemailSessionCubit _session;
  final AppLocalizations _l10n;

  Future<void> send(Voicemail message, Contact recipient) async {
    _closeChoiceFor(message);

    final outcome = await _session.forward(message, recipient);
    // A forward of this message was already out, so nothing was sent and
    // there is nothing to say: the one that is out will be said when it lands.
    if (outcome == null) return;

    // The session can end while the request is out, and a closed cubit
    // refuses an emit.
    if (_picking.isClosed) return;

    _picking.announce(_report(outcome, message, recipient));
  }

  /// Takes back a request for somebody to be chosen for [message], if one is
  /// still standing.
  ///
  /// The message is being sent now - by a choice, which closes its own
  /// request anyway, or by trying again to whoever it was for. A request left
  /// standing through the second would keep the lists offering to forward a
  /// message that is already on its way, and a pick made there would be
  /// answered with nothing.
  void _closeChoiceFor(Voicemail message) {
    if (_picking.isClosed) return;

    final purpose = _picking.state.purpose;
    if (purpose is ForwardVoicemailPurpose && purpose.messageId == message.id) {
      _picking.withdraw<ForwardVoicemailPurpose>();
    }
  }

  DestinationPickReport _report(VoicemailForwardOutcome outcome, Voicemail message, Contact recipient) {
    final name = recipient.displayTitle;

    if (outcome == VoicemailForwardOutcome.sent) {
      return DestinationPickReport(message: _l10n.voicemail_Snackbar_forwarded(name));
    }

    return DestinationPickReport(
      message: outcome.failureText(_l10n, name),
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
