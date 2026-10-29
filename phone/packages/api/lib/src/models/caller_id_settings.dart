import 'package:freezed_annotation/freezed_annotation.dart';

part 'caller_id_settings.freezed.dart';
part 'caller_id_settings.g.dart';

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class PrefixMatcher with _$PrefixMatcher {
  const PrefixMatcher({required this.prefix, required this.number, this.country});

  final String prefix;

  final String number;

  /// ISO 3166-1 alpha-2 code of the country picked for [prefix], for display
  /// only. Left out of the request when unknown: the backend then keeps the
  /// country it already has for the same prefix.
  @JsonKey(includeIfNull: false)
  final String? country;

  factory PrefixMatcher.fromJson(Map<String, Object?> json) => _$PrefixMatcherFromJson(json);

  Map<String, Object?> toJson() => _$PrefixMatcherToJson(this);
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CallerIdSettings with _$CallerIdSettings {
  const CallerIdSettings({
    this.defaultNumber,
    required this.prefixMatchers,
    required this.version,
    required this.modifiedAt,
  });

  final String? defaultNumber;

  final List<PrefixMatcher> prefixMatchers;

  final int version;

  final DateTime modifiedAt;

  factory CallerIdSettings.fromJson(Map<String, Object?> json) => _$CallerIdSettingsFromJson(json);

  Map<String, Object?> toJson() => _$CallerIdSettingsToJson(this);
}
