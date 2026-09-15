/// Represents the synchronization or read status of the voicemail.
enum ReadStatus {
  read,
  unread,
  unknown;

  bool get isRead => this == ReadStatus.read;

  bool get isUnread => this == ReadStatus.unread;

  bool get isUnknown => this == ReadStatus.unknown;
}

class Voicemail {
  Voicemail({
    required this.id,
    required this.date,
    required this.duration,
    required this.sender,
    required this.displaySender,
    required this.receiver,
    required this.status,
    required this.size,
    required this.type,
    required this.url,
    this.saved,
    this.forwardedBy,
  });

  final String id;
  final String date;
  final double duration;
  final String sender;
  final String displaySender;
  final String receiver;
  final ReadStatus status;
  final int size;
  final String type;
  final String? url;

  /// Whether the user is keeping this message.
  ///
  /// Null means the mailbox behind this backend cannot hold the flag at all,
  /// which is not the same as `false`: the control does not apply, so it is
  /// hidden rather than offered switched off.
  final bool? saved;

  /// The id of the colleague who forwarded this message on, null unless it
  /// arrived that way. [sender] stays the original caller either way.
  final String? forwardedBy;

  /// Whether this message reached the mailbox by being forwarded.
  bool get isForwarded => forwardedBy != null;
}
