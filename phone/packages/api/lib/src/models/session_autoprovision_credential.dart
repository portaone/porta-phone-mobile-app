// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_type.dart';

part 'session_autoprovision_credential.freezed.dart';

part 'session_autoprovision_credential.g.dart';

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SessionAutoProvisionCredential with _$SessionAutoProvisionCredential {
  const SessionAutoProvisionCredential({
    this.bundleId,
    required this.type,
    required this.identifier,
    required this.configToken,
  });

  final String? bundleId;

  final AppType type;

  final String identifier;

  final String configToken;

  factory SessionAutoProvisionCredential.fromJson(Map<String, dynamic> json) =>
      _$SessionAutoProvisionCredentialFromJson(json);

  Map<String, dynamic> toJson() => _$SessionAutoProvisionCredentialToJson(this);
}
