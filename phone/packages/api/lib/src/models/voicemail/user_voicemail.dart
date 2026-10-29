import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_voicemail.freezed.dart';

part 'user_voicemail.g.dart';

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserVoicemail with _$UserVoicemail {
  const UserVoicemail({
    required this.id,
    required this.date,
    required this.duration,
    required this.sender,
    required this.receiver,
    required this.seen,
    required this.size,
    required this.type,
    required this.attachments,
    this.saved,
    this.forwardedBy,
  });

  final String id;

  final String date;

  final double duration;

  final String sender;

  final String receiver;

  final bool seen;

  final int size;

  final String type;

  final List<UserVoicemailAttachment> attachments;

  /// Whether the user is keeping this message; null when the backend omitted the
  /// field, which means the control does not apply. See [UserVoicemailSummary.saved].
  final bool? saved;

  /// The id of the user who forwarded this message on; null unless it arrived
  /// that way. See [UserVoicemailSummary.forwardedBy].
  final String? forwardedBy;

  factory UserVoicemail.fromJson(Map<String, dynamic> json) => _$UserVoicemailFromJson(json);

  Map<String, dynamic> toJson() => _$UserVoicemailToJson(this);
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserVoicemailAttachment with _$UserVoicemailAttachment {
  const UserVoicemailAttachment({
    required this.filename,
    required this.size,
    required this.type,
    required this.subtype,
  });

  final String filename;

  final int size;

  final String type;

  final String subtype;

  factory UserVoicemailAttachment.fromJson(Map<String, dynamic> json) => _$UserVoicemailAttachmentFromJson(json);

  Map<String, dynamic> toJson() => _$UserVoicemailAttachmentToJson(this);
}
