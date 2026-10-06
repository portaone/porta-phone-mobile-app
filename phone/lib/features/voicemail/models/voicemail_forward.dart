import 'package:equatable/equatable.dart';

import 'package:webtrit_phone/models/models.dart';

import 'voicemail_forward_outcome.dart';

/// Where passing one message to a colleague stands, for as long as that is
/// worth showing on the message.
///
/// A forward that went through is not one of these: it is said once and
/// leaves nothing behind. What stays is the forward still out, and the one
/// that did not go through - a quiet mark on the message, there for as long
/// as the message has not reached anybody.
sealed class VoicemailForward extends Equatable {
  const VoicemailForward();
}

/// The request is out and the backend has not answered.
final class VoicemailForwardSending extends VoicemailForward {
  const VoicemailForwardSending();

  @override
  List<Object?> get props => const [];
}

/// The backend refused, or was never reached.
final class VoicemailForwardFailed extends VoicemailForward {
  const VoicemailForwardFailed({required this.outcome, required this.recipient});

  final VoicemailForwardOutcome outcome;

  /// Who it was meant for, kept so that trying again does not ask the person
  /// to choose a second time: they already chose, and the refusal was not
  /// about who.
  final Contact recipient;

  @override
  List<Object?> get props => [outcome, recipient];
}
