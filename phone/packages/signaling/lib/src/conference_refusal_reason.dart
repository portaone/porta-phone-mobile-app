/// Why Core refused a conference request.
///
/// Conference refusals arrive as `{"response": "error", "code": 0, "reason": ...}`
/// with the reason as a string; the numeric [SignalingResponseCode] table does
/// not apply to them. Two families carry a diagnostic after a colon, such as
/// `attach_failed: the AudioBridge plugin could not be attached [458: No such
/// plugin]`; they match by prefix, and the caller keeps the raw reason string
/// from the exception when it wants that text. [lineInConference] is the one
/// value that is not a conference refusal: it is the reason of a refused LINE
/// `hold` request on a conferenced line.
enum ConferenceRefusalReason {
  conferenceDisabled('conference_disabled'),
  conferenceAlreadyActive('conference_already_active'),
  notEnoughLines('not_enough_lines'),
  lineWithoutActiveCall('line_without_active_call'),
  noConference('no_conference'),
  lineAlreadyInConference('line_already_in_conference'),
  lineNotInConference('line_not_in_conference'),
  lineNotReady('line_not_ready'),
  invalidMuted('invalid_muted'),
  roomCreateFailed('room_create_failed'),
  attachFailed('attach_failed'),
  lineInConference('line_in_conference'),
  unknown('');

  const ConferenceRefusalReason(this.reason);

  /// The `reason` string as Core sends it.
  final String reason;

  /// The value for [reason], matched exactly or by `<reason>:` prefix, or
  /// [unknown] for anything not in this table.
  static ConferenceRefusalReason fromReason(String reason) => values.firstWhere(
    (value) => reason == value.reason || reason.startsWith('${value.reason}:'),
    orElse: () => unknown,
  );
}
