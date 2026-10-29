// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_type.dart';

part 'session_otp_credential.freezed.dart';

part 'session_otp_credential.g.dart';

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SessionOtpCredential with _$SessionOtpCredential {
  const SessionOtpCredential({this.bundleId, required this.type, required this.identifier, required this.userRef});

  final String? bundleId;

  final AppType type;

  final String identifier;

  final String userRef;

  factory SessionOtpCredential.fromJson(Map<String, dynamic> json) => _$SessionOtpCredentialFromJson(json);

  Map<String, dynamic> toJson() => _$SessionOtpCredentialToJson(this);
}
