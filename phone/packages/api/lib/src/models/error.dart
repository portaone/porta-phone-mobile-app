// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'error.freezed.dart';

part 'error.g.dart';

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ErrorResponse with _$ErrorResponse {
  const ErrorResponse({this.code, this.message, this.details});

  @override
  final String? code;

  @override
  final String? message;

  /// The one detail this reads, whichever shape the backend sent.
  ///
  /// Two are in the wild: the adaptee answers with a single object, Core with a
  /// list of them - one per field it refused. Read either way round, because an
  /// error body is not the place to be strict: a shape nobody expected used to
  /// throw out of the parse and take the failure itself with it, leaving the
  /// caller a cast error instead of the status the backend actually sent.
  @override
  @JsonKey(fromJson: _detailFromJson)
  final ErrorDetail? details;

  factory ErrorResponse.fromJson(Map<String, dynamic> json) => _$ErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);
}

/// A list carries what the backend refused first; anything else is not a
/// detail this can read, and says nothing rather than failing.
ErrorDetail? _detailFromJson(Object? json) => switch (json) {
  Map<String, dynamic> detail => ErrorDetail.fromJson(detail),
  [final Map<String, dynamic> first, ...] => ErrorDetail.fromJson(first),
  _ => null,
};

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class ErrorDetail with _$ErrorDetail {
  const ErrorDetail({this.path, required this.reason});

  @override
  final String? path;

  @override
  final String reason;

  factory ErrorDetail.fromJson(Map<String, dynamic> json) => _$ErrorDetailFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorDetailToJson(this);
}
