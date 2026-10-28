enum QueuedTerminationRequestType { hangup, decline }

class QueuedTerminationRequest {
  const QueuedTerminationRequest({
    required this.type,
    required this.callId,
    required this.line,
    this.declinedByUser = false,
  });

  final QueuedTerminationRequestType type;
  final String callId;
  final int? line;

  /// A decline the user made on this device - the platform's performEndCall said a person ended
  /// the call (the system call UI, the notification, the app's own call screen) - not one the app
  /// or the platform made on its own (a call refused by the app, a media failure, a ring
  /// timeout). The end that follows is reported to callkeep as
  /// `CallkeepEndCallReason.declinedByUser` rather than inferred from the call's absence.
  final bool declinedByUser;

  String get key => '${type.name}:$callId';
}
