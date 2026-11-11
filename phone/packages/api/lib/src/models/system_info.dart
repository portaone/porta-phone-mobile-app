import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pub_semver/pub_semver.dart';

import 'converters/converters.dart';

part 'system_info.freezed.dart';

part 'system_info.g.dart';

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SystemInfo with _$SystemInfo {
  const SystemInfo({
    required this.core,
    required this.postgres,
    this.adapter,
    this.janus,
    this.gorush,
    this.minSupportedAppVersion,
    this.bundleVersion,
  });

  final CoreInfo core;

  final PostgresInfo postgres;

  final AdapterInfo? adapter;

  final JanusInfo? janus;

  final GorushInfo? gorush;

  /// Optional minimum app version the backend declares it supports, as a raw
  /// semver string (JSON key `min_supported_app_version`). `null` = not
  /// enforced. Kept as a `String?` here so the API layer stays a dumb
  /// transport; the domain mapper parses it into a [Version].
  final String? minSupportedAppVersion;

  /// Optional version of the deployment bundle (JSON key `bundle_version`),
  /// e.g. the Add-on Mart package version. `null` = not configured on the
  /// backend. Kept as a raw string: the bundle version format is not
  /// guaranteed to be semver.
  final String? bundleVersion;

  factory SystemInfo.fromJson(Map<String, Object?> json) => _$SystemInfoFromJson(json);

  Map<String, Object?> toJson() => _$SystemInfoToJson(this);
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CoreInfo with _$CoreInfo {
  const CoreInfo({
    @VersionConverter() required this.version,
    this.iceServersConfigured,
    this.notificationDeletedRetentionDays,
    this.mobileRemoteLogging,
  });

  @VersionConverter()
  final Version version;

  /// Whether the deployment bundles its own STUN/TURN servers, served by
  /// `GET /api/v1/user/ice-servers` (JSON key `ice_servers_configured`).
  /// `null` = the core does not report the capability, i.e. it has none.
  final bool? iceServersConfigured;

  /// For how many days the core reports a deleted notification in the
  /// notification updates (JSON key `notification_deleted_retention_days`):
  /// the deployment's notification retention, `0` = without limit. A copy of
  /// the notifications not brought up to date for longer may hold some that
  /// were deleted since. `null` = the core does not report deleted
  /// notifications at all.
  final int? notificationDeletedRetentionDays;

  /// Whether and how the app sends its logs to the core (JSON key
  /// `mobile_remote_logging`). `null` = the core does not offer remote
  /// logging, which the app treats as disabled.
  final MobileRemoteLoggingInfo? mobileRemoteLogging;

  factory CoreInfo.fromJson(Map<String, Object?> json) => _$CoreInfoFromJson(json);

  Map<String, Object?> toJson() => _$CoreInfoToJson(this);
}

/// The remote logging settings the core hands out to the app.
///
/// Every field is nullable so that a core sending only part of the block is
/// still read; the app decides what a missing field means.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class MobileRemoteLoggingInfo {
  const MobileRemoteLoggingInfo({
    this.available,
    this.enabled,
    this.level,
    this.anonymization,
    this.expiresAt,
    this.path,
  });

  /// Whether the deployment has a log receiver at all.
  final bool? available;

  /// Whether the app should send its logs now; already the effective value
  /// the core computed from its own settings.
  final bool? enabled;

  /// The lowest level to send, a `package:logging` level name (`INFO`, `FINE`, ...).
  final String? level;

  /// Whether personal data must be masked before a record leaves the device.
  final bool? anonymization;

  /// When the app must stop sending, even if it does not hear from the core again.
  final DateTime? expiresAt;

  /// Where the logs go, relative to the tenant URL of the core (`/mobile-logs`).
  final String? path;

  factory MobileRemoteLoggingInfo.fromJson(Map<String, Object?> json) => _$MobileRemoteLoggingInfoFromJson(json);

  Map<String, Object?> toJson() => _$MobileRemoteLoggingInfoToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MobileRemoteLoggingInfo &&
          other.available == available &&
          other.enabled == enabled &&
          other.level == level &&
          other.anonymization == anonymization &&
          other.expiresAt == expiresAt &&
          other.path == path;

  @override
  int get hashCode => Object.hash(available, enabled, level, anonymization, expiresAt, path);

  @override
  String toString() =>
      'MobileRemoteLoggingInfo(available: $available, enabled: $enabled, level: $level, '
      'anonymization: $anonymization, expiresAt: $expiresAt, path: $path)';
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class PostgresInfo with _$PostgresInfo {
  const PostgresInfo({this.version});

  final String? version;

  factory PostgresInfo.fromJson(Map<String, Object?> json) => _$PostgresInfoFromJson(json);

  Map<String, Object?> toJson() => _$PostgresInfoToJson(this);
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AdapterInfo with _$AdapterInfo {
  const AdapterInfo({this.name, this.version, this.supported, this.custom});

  final String? name;

  final String? version;

  final List<String>? supported;

  final Map<String, dynamic>? custom;

  factory AdapterInfo.fromJson(Map<String, Object?> json) => _$AdapterInfoFromJson(json);

  Map<String, Object?> toJson() => _$AdapterInfoToJson(this);
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class JanusInfo with _$JanusInfo {
  const JanusInfo({this.plugins, this.transports, this.version});

  final Plugins? plugins;

  final Transports? transports;

  final String? version;

  factory JanusInfo.fromJson(Map<String, Object?> json) => _$JanusInfoFromJson(json);

  Map<String, Object?> toJson() => _$JanusInfoToJson(this);
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class GorushInfo with _$GorushInfo {
  const GorushInfo({this.version});

  final String? version;

  factory GorushInfo.fromJson(Map<String, Object?> json) => _$GorushInfoFromJson(json);

  Map<String, Object?> toJson() => _$GorushInfoToJson(this);
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Transports with _$Transports {
  const Transports({this.websocket});

  final Websocket? websocket;

  factory Transports.fromJson(Map<String, Object?> json) => _$TransportsFromJson(json);

  Map<String, Object?> toJson() => _$TransportsToJson(this);
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Websocket with _$Websocket {
  const Websocket({this.version});

  final String? version;

  factory Websocket.fromJson(Map<String, Object?> json) => _$WebsocketFromJson(json);

  Map<String, Object?> toJson() => _$WebsocketToJson(this);
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Plugins with _$Plugins {
  const Plugins({this.sip});

  final SipVersion? sip;

  factory Plugins.fromJson(Map<String, Object?> json) => _$PluginsFromJson(json);

  Map<String, Object?> toJson() => _$PluginsToJson(this);
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class SipVersion with _$SipVersion {
  const SipVersion({this.version});

  final String? version;

  factory SipVersion.fromJson(Map<String, Object?> json) => _$SipVersionFromJson(json);

  Map<String, Object?> toJson() => _$SipVersionToJson(this);
}
