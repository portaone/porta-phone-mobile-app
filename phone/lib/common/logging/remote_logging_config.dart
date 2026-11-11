import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/models/models.dart';

/// The remote logging settings in effect: what the core last said, bound to
/// the address of that core.
///
/// Kept apart from the cached system info on purpose: the system info is
/// cleared on logout, while the logging settings must outlive it so that a
/// logged-out app keeps logging where the core asked it to.
class RemoteLoggingConfig extends Equatable {
  const RemoteLoggingConfig({
    required this.enabled,
    required this.anonymization,
    this.level,
    this.expiresAt,
    this.endpoint,
  });

  /// Remote logging off. What an absent `mobile_remote_logging` block means.
  static const disabled = RemoteLoggingConfig(enabled: false, anonymization: true);

  /// Builds the settings from the block of a core that answered at [tenantUrl].
  ///
  /// A missing block, a disabled one, or one without a path all turn remote
  /// logging off.
  factory RemoteLoggingConfig.fromCore(MobileRemoteLoggingInfo? info, Uri tenantUrl) {
    final path = info?.path;
    if (info == null || !info.enabled || path == null || !isValidPath(path)) {
      return disabled;
    }

    return RemoteLoggingConfig(
      enabled: true,
      anonymization: info.anonymization,
      level: _parseLevel(info.level),
      expiresAt: info.expiresAt?.toUtc(),
      endpoint: buildEndpoint(tenantUrl, path),
    );
  }

  /// Whether the core asked for logs. Use [isActiveAt] to also honour [expiresAt].
  final bool enabled;

  /// Whether personal data is masked before a record is sent.
  final bool anonymization;

  /// The lowest level to send; null leaves the choice to the app.
  final Level? level;

  /// When sending stops without a word from the core; null for no end.
  final DateTime? expiresAt;

  /// Where the records are posted.
  final Uri? endpoint;

  /// Whether records are to be sent at [now]: enabled, with an endpoint, and
  /// not past [expiresAt]. The check runs on the device so that logging stops
  /// on time even when the core cannot be reached to say so.
  bool isActiveAt(DateTime now) {
    if (!enabled || endpoint == null) return false;
    final expiresAt = this.expiresAt;
    return expiresAt == null || now.isBefore(expiresAt);
  }

  /// Whether [path] may follow the tenant URL: a plain path only. A path with
  /// a scheme or a host of its own would send the logs to another server, and
  /// a query or a fragment has no place in it.
  static bool isValidPath(String path) {
    if (path.trim().isEmpty || path.contains('?') || path.contains('#')) return false;
    final uri = Uri.tryParse(path);
    return uri != null && !uri.hasScheme && !uri.hasAuthority;
  }

  /// The address logs are posted to: the tenant URL of the core followed by
  /// [path]. The query of [tenantUrl] is dropped, because the log sender
  /// appends a query of its own to the address, and so are credentials in it,
  /// which must not travel with the logs or show in them.
  ///
  /// The result is parsed back from its text so that it is the same kind of
  /// [Uri] as the one read from storage: the two are equal by `==`, but
  /// [Equatable] also compares their runtime types.
  static Uri buildEndpoint(Uri tenantUrl, String path) {
    final endpoint = Uri(
      scheme: tenantUrl.scheme,
      host: tenantUrl.host,
      port: tenantUrl.hasPort ? tenantUrl.port : null,
      pathSegments: [
        ...tenantUrl.pathSegments.where((segment) => segment.isNotEmpty),
        ...path.split('/').where((segment) => segment.isNotEmpty),
      ],
    );
    return Uri.parse(endpoint.toString());
  }

  static Level? _parseLevel(String? name) {
    if (name == null) return null;
    final upper = name.toUpperCase();
    for (final level in Level.LEVELS) {
      if (level.name == upper) return level;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'anonymization': anonymization,
    'level': level?.name,
    'expires_at': expiresAt?.toUtc().toIso8601String(),
    'endpoint': endpoint?.toString(),
  };

  /// Reads what [toJson] wrote; null for anything it cannot read.
  static RemoteLoggingConfig? tryFromJson(String source) {
    try {
      final map = jsonDecode(source);
      if (map is! Map<String, dynamic>) return null;
      final expiresAt = map['expires_at'] as String?;
      final endpoint = map['endpoint'] as String?;
      return RemoteLoggingConfig(
        enabled: map['enabled'] == true,
        anonymization: map['anonymization'] != false,
        level: _parseLevel(map['level'] as String?),
        expiresAt: expiresAt != null ? DateTime.tryParse(expiresAt) : null,
        endpoint: endpoint != null ? Uri.tryParse(endpoint) : null,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [enabled, anonymization, level, expiresAt, endpoint];

  @override
  bool get stringify => true;
}
