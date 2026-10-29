// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_type.dart';

part 'session_login_credential.freezed.dart';

part 'session_login_credential.g.dart';

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SessionLoginCredential with _$SessionLoginCredential {
  const SessionLoginCredential({
    this.bundleId,
    required this.type,
    required this.identifier,
    required this.login,
    required this.password,
  });

  final String? bundleId;

  final AppType type;

  final String identifier;

  final String login;

  final String password;

  factory SessionLoginCredential.fromJson(Map<String, dynamic> json) => _$SessionLoginCredentialFromJson(json);

  Map<String, dynamic> toJson() => _$SessionLoginCredentialToJson(this);
}
