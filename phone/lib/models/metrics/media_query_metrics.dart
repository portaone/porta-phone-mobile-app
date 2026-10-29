import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_query_metrics.freezed.dart';

part 'media_query_metrics.g.dart';

@freezed
@JsonSerializable()
class MediaQueryMetrics with _$MediaQueryMetrics {
  const MediaQueryMetrics({
    required this.brightness,
    required this.devicePixelRatio,
    required this.topSafeInset,
    required this.bottomSafeInset,
  });

  final String brightness;

  final double devicePixelRatio;

  final int topSafeInset;

  final int bottomSafeInset;

  factory MediaQueryMetrics.fromJson(Map<String, dynamic> json) => _$MediaQueryMetricsFromJson(json);

  Map<String, Object?> toJson() => _$MediaQueryMetricsToJson(this);
}
