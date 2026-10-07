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

  /// Whether it is known who left the message.
  ///
  /// The backend lists a message whose headers it could not read without a
  /// sender, and a backend too old to list senders does so for every message;
  /// [sender] is then empty. There is nobody to call back and no contact to
  /// open, and the name shown is the app's word for an unknown caller.
  bool get hasSender => sender.isNotEmpty;

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
