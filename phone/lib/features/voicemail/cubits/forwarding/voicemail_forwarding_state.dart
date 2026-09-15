part of 'voicemail_forwarding_cubit.dart';

class VoicemailForwardingState extends Equatable {
  const VoicemailForwardingState({this.pending, this.report});

  /// The message looking for somebody to go to, or null when none is.
  final Voicemail? pending;

  /// What came of the last send, until it has been said once.
  final VoicemailForwardReport? report;

  /// Whether the address book is currently being browsed for a colleague.
  bool get isForwarding => pending != null;

  @override
  List<Object?> get props => [pending?.id, report];
}

/// What came of one send, and everything needed to say so or try again.
class VoicemailForwardReport extends Equatable {
  const VoicemailForwardReport(this.outcome, {required this.message, required this.recipient});

  final VoicemailForwardOutcome outcome;
  final Voicemail message;
  final Contact recipient;

  String get recipientName => recipient.displayTitle;

  @override
  List<Object?> get props => [outcome, message.id, recipient.id];
}
