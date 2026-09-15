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
}
