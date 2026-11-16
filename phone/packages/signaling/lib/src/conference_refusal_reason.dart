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
///
/// The conference video requests answer from the same table. A video refusal
/// relayed to an invited far end arrives as the `reason` of
/// `conference_video_failed`; [fromReason] reads it too.
enum ConferenceRefusalReason {
  conferenceDisabled('conference_disabled'),
  conferenceAlreadyActive('conference_already_active'),
  notEnoughLines('not_enough_lines'),
  lineWithoutActiveCall('line_without_active_call'),
  noConference('no_conference'),
  conferenceNotEstablished('conference_not_established'),
  lineAlreadyInConference('line_already_in_conference'),
  lineNotInConference('line_not_in_conference'),
  lineNotReady('line_not_ready'),
  invalidMuted('invalid_muted'),
  roomCreateFailed('room_create_failed'),
  attachFailed('attach_failed'),
  lineInConference('line_in_conference'),

  // Video, from the host and an invited far end.
  videoDisabled('video_disabled'),
  noConferenceVideo('no_conference_video'),
  notInConference('not_in_conference'),
  invalidDescriptions('invalid_descriptions'),
  notPublishing('not_publishing'),
  notSubscribed('not_subscribed'),
  noPeerConnection('no_peer_connection'),
  invalidRequest('invalid_request'),

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
