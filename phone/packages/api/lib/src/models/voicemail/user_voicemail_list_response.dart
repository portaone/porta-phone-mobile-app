import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_voicemail_list_response.freezed.dart';

part 'user_voicemail_list_response.g.dart';

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserVoicemailListResponse with _$UserVoicemailListResponse {
  const UserVoicemailListResponse({required this.hasNewMessages, required this.items});

  @override
  final bool hasNewMessages;

  @override
  final List<UserVoicemailSummary> items;

  factory UserVoicemailListResponse.fromJson(Map<String, dynamic> json) => _$UserVoicemailListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserVoicemailListResponseToJson(this);
}

/// One message as the LIST reports it, which is less than the message has.
///
/// There is no sender, no receiver and no attachment description here, so
/// anything needing those asks for the message itself - see [UserVoicemail].
/// The two are separate types rather than one with optional fields precisely so
/// that a sender read off [UserVoicemail] is known to be there.
@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserVoicemailSummary with _$UserVoicemailSummary {
  const UserVoicemailSummary({
    required this.id,
    required this.date,
    required this.duration,
    required this.seen,
    required this.size,
    required this.type,
    this.saved,
    this.forwardedBy,
  });

  @override
  final String id;

  @override
  final String date;

  @override
  final double duration;

  @override
  final bool seen;

  @override
  final int size;

  @override
  final String type;

  /// Whether the user is keeping this message.
  ///
  /// Null when the backend did not report the field at all, which it omits when
  /// the mailbox behind it cannot persist the flag. That is not the same as
  /// `false`: it means the control does not apply to this message, so a client
  /// hides it rather than offering to save something that will not stay saved.
  @override
  final bool? saved;

  /// The id of the user who forwarded this message on, present only on a message
  /// that reached this mailbox by being forwarded.
  ///
  /// The sender stays the original caller, so this is the only field naming the
  /// colleague who passed it along.
  @override
  final String? forwardedBy;

  factory UserVoicemailSummary.fromJson(Map<String, dynamic> json) => _$UserVoicemailSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$UserVoicemailSummaryToJson(this);
}
