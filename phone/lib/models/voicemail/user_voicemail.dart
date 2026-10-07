import 'package:webtrit_phone/models/contact.dart';

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
    required this.receiver,
    required this.status,
    required this.size,
    required this.type,
    required this.url,
    this.saved,
    this.forwardedBy,
    this.senderContact,
  });

  final String id;
  final String date;
  final double duration;
  final String sender;
  final String receiver;
  final ReadStatus status;
  final int size;
  final String type;
  final String? url;

  /// How long the recording is, as the mailbox listed it; null when it did not
  /// say.
  ///
  /// The backend may list a message without its length, and such a message is
  /// stored with a zero one. A recording of no length at all is nothing anybody
  /// left, so zero reads as "not known" here, and this is the one place that
  /// reads it that way: the player then shows no time until it has loaded the
  /// recording and measured it.
  Duration? get length => duration > 0 ? Duration(milliseconds: (duration * 1000).round()) : null;

  /// Whether it is known who left the message.
  ///
  /// The backend lists a message whose headers it could not read without a
  /// sender, and a backend too old to list senders does so for every message;
  /// [sender] is then empty. There is nobody to call back and no contact to
  /// open, and the name shown is the app's word for an unknown caller.
  bool get hasSender => sender.isNotEmpty;

  /// The address book's card for whoever left the message, null when [sender]
  /// is nobody the address book knows.
  ///
  /// Carried as the card itself rather than as a name: a contact may have no
  /// name, and a name alone could not tell such a contact from a stranger -
  /// which is what hid "Open contact" for one. It comes with its numbers, which
  /// its title is made of, and is the card as it was when the list was drawn;
  /// the address book may have moved on since.
  final Contact? senderContact;

  /// Whether [sender] is somebody in the address book.
  bool get isFromContact => senderContact != null;

  /// What to call whoever left the message: the title the address book shows
  /// the contact under, the number where there is no contact.
  ///
  /// The title and not the name, so that a contact without a name reads here
  /// as it does in the address book - by its extension or its main number,
  /// which need not be the number this message came from.
  String get displaySender => senderContact?.displayTitle ?? sender;

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
