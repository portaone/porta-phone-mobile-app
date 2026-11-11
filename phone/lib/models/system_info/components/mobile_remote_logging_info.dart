import 'package:equatable/equatable.dart';

/// What the core says about sending the app's logs to it.
///
/// Absent from [CoreInfo] of a core that does not offer remote logging, which
/// means the same as [enabled] false.
class MobileRemoteLoggingInfo with EquatableMixin {
  MobileRemoteLoggingInfo({
    this.available = false,
    this.enabled = false,
    this.level,
    this.anonymization = true,
    this.expiresAt,
    this.path,
  });

  /// Whether the deployment has a log receiver at all.
  final bool available;

  /// Whether the app should send its logs now. The core has already combined
  /// its own switches into this value.
  final bool enabled;

  /// The lowest level to send, a `package:logging` level name; null leaves the
  /// choice to the app.
  final String? level;

  /// Whether personal data must be masked before a record leaves the device.
  /// True when the core does not say: masking too much is the safe mistake.
  final bool anonymization;

  /// When the app must stop sending even if it does not hear from the core
  /// again; null for no end.
  final DateTime? expiresAt;

  /// Where the logs go, relative to the tenant URL of the core.
  final String? path;

  @override
  List<Object?> get props => [available, enabled, level, anonymization, expiresAt, path];

  @override
  bool get stringify => true;
}
