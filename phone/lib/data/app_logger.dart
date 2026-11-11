import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';

import 'package:webtrit_phone/common/common.dart';
import 'package:webtrit_phone/models/models.dart';

final _logger = Logger('AppLogger');

class AppLogger implements Disposable {
  static Future<AppLogger> init(
    LoggingConfig config,
    RemoteLoggingService? remoteLoggingService,
    Map<String, String> Function() getLabels,
  ) async {
    hierarchicalLoggingEnabled = true;

    Logger.root.clearListeners();

    // Anonymization is intentionally applied only to remote logs.
    // Console output is not anonymized to preserve full detail for local debugging.
    final console = _ConsoleAppender(level: config.logLevel)..attachToLogger(Logger.root);

    final instance = AppLogger._(remoteLoggingService, getLabels, console);
    remoteLoggingService?.onMinLevelChanged = instance._applyLevels;
    instance.updateRemoteLabels();
    instance.applyConfig(config);

    return instance;
  }

  AppLogger._(this._remoteLoggingService, this._getLabels, this._console);

  final RemoteLoggingService? _remoteLoggingService;
  final Map<String, String> Function() _getLabels;
  final _ConsoleAppender _console;
  LoggingConfig? _config;

  void applyConfig(LoggingConfig config) {
    _config = config;
    _applyLevels();
    _logger.info('AppLogger log level applied: ${config.logLevel}');
  }

  /// Sets the root logger to the lower of the configured level and the level
  /// remote logging sends from: a record the root logger drops reaches no
  /// appender, so a core that asks for FINE would otherwise get nothing below
  /// the local level. The console keeps the configured level.
  void _applyLevels() {
    final config = _config;
    if (config == null) return;
    final remoteLevel = _remoteLoggingService?.minLevel ?? Level.OFF;
    final rootLevel = remoteLevel < config.logLevel ? remoteLevel : config.logLevel;
    _console.level = config.logLevel;
    EquatableConfig.stringify = rootLevel <= Level.FINE;
    if (Logger.root.level != rootLevel) {
      Logger.root.level = rootLevel;
      _logger.info('Root log level: $rootLevel (local ${config.logLevel}, remote $remoteLevel)');
    }
  }

  /// Updates the labels sent with every remote record.
  ///
  /// Call this after authentication when coreUrl and tenantId become available.
  void updateRemoteLabels() {
    _remoteLoggingService?.initialize(_getLabels());
  }

  /// Releases the remote logging appender.
  ///
  /// The console appender attached in [init] is left in place on purpose: the
  /// root logger is shared with whatever process the app runs in, and clearing
  /// it here would silence a host that keeps running.
  @override
  Future<void> dispose() async {
    _remoteLoggingService?.onMinLevelChanged = null;
    await _remoteLoggingService?.dispose();
  }
}

/// Prints the records at or above [level], whatever lower level the root
/// logger lets through for remote logging.
class _ConsoleAppender extends PrintAppender {
  _ConsoleAppender({required this.level}) : super(formatter: const ColorFormatter());

  Level level;

  @override
  void handle(LogRecord record) {
    if (record.level >= level) super.handle(record);
  }
}
