import 'package:freezed_annotation/freezed_annotation.dart';

import 'common.dart';

part 'user_info.freezed.dart';

part 'user_info.g.dart';

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserInfo with _$UserInfo {
  const UserInfo({
    this.status,
    this.balance,
    required this.numbers,
    this.email,
    this.firstName,
    this.lastName,
    this.aliasName,
    this.companyName,
    this.timeZone,
  });

  final UserInfoStatus? status;

  final Balance? balance;

  final Numbers numbers;

  final String? email;

  final String? firstName;

  final String? lastName;

  final String? aliasName;

  final String? companyName;

  final String? timeZone;

  factory UserInfo.fromJson(Map<String, Object?> json) => _$UserInfoFromJson(json);

  Map<String, Object?> toJson() => _$UserInfoToJson(this);
}

@JsonEnum(fieldRename: FieldRename.snake)
enum UserInfoStatus { active, limited, blocked }
