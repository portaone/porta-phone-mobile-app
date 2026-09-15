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
  final List<UserVoicemailItem> items;

  factory UserVoicemailListResponse.fromJson(Map<String, dynamic> json) => _$UserVoicemailListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserVoicemailListResponseToJson(this);
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserVoicemailItem with _$UserVoicemailItem {
  const UserVoicemailItem({
    required this.id,
    required this.date,
    required this.duration,
    required this.seen,
    required this.size,
    required this.type,
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

  factory UserVoicemailItem.fromJson(Map<String, dynamic> json) => _$UserVoicemailItemFromJson(json);

  Map<String, dynamic> toJson() => _$UserVoicemailItemToJson(this);
}
