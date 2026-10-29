import 'package:freezed_annotation/freezed_annotation.dart';

import 'common.dart';

part 'user_contact.freezed.dart';

part 'user_contact.g.dart';

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserContact with _$UserContact {
  const UserContact({
    this.userId,
    this.sipStatus,
    required this.numbers,
    this.email,
    this.firstName,
    this.lastName,
    this.aliasName,
    this.companyName,
    this.isCurrentUser,
    this.isRegisteredUser,
  });

  final String? userId;

  final SipStatus? sipStatus;

  final Numbers numbers;

  final String? email;

  final String? firstName;

  final String? lastName;

  final String? aliasName;

  final String? companyName;

  final bool? isCurrentUser;

  final bool? isRegisteredUser;

  factory UserContact.fromJson(Map<String, Object?> json) => _$UserContactFromJson(json);

  Map<String, Object?> toJson() => _$UserContactToJson(this);
}

@JsonEnum(fieldRename: FieldRename.snake)
enum SipStatus { registered, notregistered }
