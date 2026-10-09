import 'package:equatable/equatable.dart';

/// What became of a conference request.
enum ConferenceRequestOutcome {
  /// The server acknowledged it.
  taken,

  /// The server answered with a refusal.
  refused,

  /// It never reached the server, or the session went before an answer.
  notSent,

  /// It was sent and nothing came back in time: it may have been taken.
  unanswered,
}

/// The outcome of a conference request, with the server's reason when it
/// refused.
///
/// A refusal is the server's answer; the other three are what the transport
/// did, and they are told apart because they are not the same news: a request
/// that was not sent decides nothing, one that went unanswered may have been
/// taken all the same.
class ConferenceRequestResult extends Equatable {
  const ConferenceRequestResult.taken() : outcome = ConferenceRequestOutcome.taken, reason = null;

  const ConferenceRequestResult.refused(String this.reason) : outcome = ConferenceRequestOutcome.refused;

  const ConferenceRequestResult.notSent() : outcome = ConferenceRequestOutcome.notSent, reason = null;

  const ConferenceRequestResult.unanswered() : outcome = ConferenceRequestOutcome.unanswered, reason = null;

  final ConferenceRequestOutcome outcome;

  /// The `reason` string of the refusal as the server sent it; `null` otherwise.
  final String? reason;

  @override
  List<Object?> get props => [outcome, reason];

  @override
  String toString() => 'ConferenceRequestResult(${outcome.name}${reason == null ? '' : ': $reason'})';
}
