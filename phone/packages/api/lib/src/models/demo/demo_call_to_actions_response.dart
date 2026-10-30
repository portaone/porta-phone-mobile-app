// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'demo_call_to_actions_response.freezed.dart';

part 'demo_call_to_actions_response.g.dart';

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DemoCallToActionsResponse with _$DemoCallToActionsResponse {
  const DemoCallToActionsResponse({required this.actions});

  final List<DemoCallToActionsResponseActions> actions;

  factory DemoCallToActionsResponse.fromJson(Map<String, dynamic> json) => _$DemoCallToActionsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DemoCallToActionsResponseToJson(this);
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DemoCallToActionsResponseActions with _$DemoCallToActionsResponseActions {
  const DemoCallToActionsResponseActions({
    this.title,
    this.description,
    required this.url,
    @JsonKey(name: 'extra_data') required this.extraData,
  });

  final String? title;

  final String? description;

  final String url;

  final DemoCallToActionsResponseActionsExtraData extraData;

  factory DemoCallToActionsResponseActions.fromJson(Map<String, dynamic> json) =>
      _$DemoCallToActionsResponseActionsFromJson(json);

  Map<String, dynamic> toJson() => _$DemoCallToActionsResponseActionsToJson(this);
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class DemoCallToActionsResponseActionsExtraData with _$DemoCallToActionsResponseActionsExtraData {
  const DemoCallToActionsResponseActionsExtraData({
    @JsonKey(name: 'api_token') required this.apiToken,
    @JsonKey(name: 'token_expires') required this.tokenExpires,
  });

  final String apiToken;

  final String tokenExpires;

  factory DemoCallToActionsResponseActionsExtraData.fromJson(Map<String, dynamic> json) =>
      _$DemoCallToActionsResponseActionsExtraDataFromJson(json);

  Map<String, dynamic> toJson() => _$DemoCallToActionsResponseActionsExtraDataToJson(this);
}
