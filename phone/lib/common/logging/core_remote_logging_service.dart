import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:clock/clock.dart';
import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';

import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/models/models.dart';

import 'anonymizing_formatter.dart';
import 'filtered_logz_io_appender.dart';
import 'remote_formatter.dart';
import 'remote_logging_config.dart';
import 'remote_logging_config_store.dart';
import 'remote_logging_service.dart';

final _logger = Logger('CoreRemoteLoggingService');

/// Builds the appender that posts records to [endpoint].
typedef RemoteLogAppenderFactory = FilteredLogzIoAppender Function({
  required Uri endpoint,
  required Level minLevel,
  required LogRecordFormatter formatter,
  required Map<String, String> labels,
});

/// Where the service stands on sending records.
enum RemoteLoggingState {
  /// No word from a core yet: records are held in memory, nothing is sent.
  unknown,

  /// Records are sent to the endpoint of the current config.
  enabled,

  /// Nothing is held or sent.
  disabled,
}

/// Sends the app's logs to the log receiver of WebTrit Core.
///
/// The core decides, through `mobile_remote_logging` of its system info,
/// whether logs are sent, from which level, whether they are anonymized and
/// until when. Until the app knows that, the records are kept in a bounded
/// buffer, so that a session the core turns logging on for still has its
/// start; they are sent once the config says so and dropped once it says no.
///
/// The config is applied with [applyConfig] (or [applyFromCore]) and stored,
/// so the next start, a background isolate and a logged-out app all begin
/// from the last answer of the core.
class CoreRemoteLoggingService implements RemoteLoggingService {
  CoreRemoteLoggingService({
    required this.defaultLevel,
    this.store,
    this.bufferCapacity = defaultBufferCapacity,
    this.bufferUntilConfigured = true,
    RemoteLogAppenderFactory? appenderFactory,
    int appenderBatchSize = 0,
  }) : _appenderFactory = appenderFactory ?? _defaultAppenderFactory(appenderBatchSize) {
    final stored = _readStored();
    if (stored != null) {
      _apply(stored);
    } else if (!bufferUntilConfigured) {
      _apply(RemoteLoggingConfig.disabled);
    }
  }

  /// Built from the dart-defines: the level when the core names none and the
  /// size of the batches sent.
  factory CoreRemoteLoggingService.fromEnvironment({
    RemoteLoggingConfigStore? store,
    bool bufferUntilConfigured = true,
  }) {
    final levelName = EnvironmentConfig.REMOTE_LOGZIO_LOG_LEVEL;
    final defaultLevel = Level.LEVELS.firstWhere(
      (l) => l.name == levelName,
      orElse: () {
        _logger.warning('Unknown REMOTE_LOGZIO_LOG_LEVEL "$levelName"; defaulting to INFO');
        return Level.INFO;
      },
    );
    return CoreRemoteLoggingService(
      defaultLevel: defaultLevel,
      store: store,
      bufferUntilConfigured: bufferUntilConfigured,
      appenderBatchSize: EnvironmentConfig.REMOTE_LOGZIO_LOGGING_BUFFER_SIZE,
    );
  }

  /// How many records are held while the config is unknown; the oldest go first.
  static const defaultBufferCapacity = 2000;

  /// The level used when the core does not name one.
  final Level defaultLevel;

  /// Where the config is kept between runs; null keeps it in memory only.
  final RemoteLoggingConfigStore? store;

  final int bufferCapacity;

  /// Whether records are held until a config arrives. Off where nothing will
  /// ever bring one - a background isolate never asks the core - so that the
  /// isolate does not fill memory for nothing.
  final bool bufferUntilConfigured;

  final RemoteLogAppenderFactory _appenderFactory;

  final _buffer = ListQueue<LogRecord>();
  RemoteLoggingState _state = RemoteLoggingState.unknown;
  RemoteLoggingConfig? _config;
  Map<String, String> _labels = const {};
  StreamSubscription<LogRecord>? _subscription;
  FilteredLogzIoAppender? _appender;
  Timer? _expiryTimer;

  RemoteLoggingState get state => _state;

  RemoteLoggingConfig? get config => _config;

  /// The records held while the config is unknown, oldest first.
  @visibleForTesting
  List<LogRecord> get bufferedRecords => List.unmodifiable(_buffer);

  @override
  Level get minLevel => _state == RemoteLoggingState.enabled ? _effectiveLevel(_config!) : Level.OFF;

  /// Starts taking records from the root logger, or updates the [labels] sent
  /// with every record when called again.
  @override
  void initialize(Map<String, String> labels) {
    _labels = labels;
    _subscription ??= Logger.root.onRecord.listen(_handle);
    if (_state == RemoteLoggingState.enabled) {
      // Labels are fixed per appender; a new one carries the new labels.
      _replaceAppender(_config!);
    }
  }

  /// Applies the `mobile_remote_logging` block of a core that answered at
  /// [tenantUrl]; null, the block of a core that has none, turns logging off.
  void applyFromCore(MobileRemoteLoggingInfo? info, Uri tenantUrl) {
    applyConfig(RemoteLoggingConfig.fromCore(info, tenantUrl));
  }

  /// Applies [config] and stores it for the next start and for background isolates.
  void applyConfig(RemoteLoggingConfig config) {
    _apply(config);
    final store = this.store;
    if (store != null) {
      unawaited(store.write(config).catchError((Object e, StackTrace s) => _logger.warning('Failed to store', e, s)));
    }
  }

  RemoteLoggingConfig? _readStored() {
    try {
      return store?.read();
    } catch (e, s) {
      _logger.warning('Failed to read the stored remote logging config', e, s);
      return null;
    }
  }

  void _apply(RemoteLoggingConfig config) {
    final previous = _config;
    final previousState = _state;
    _config = config;

    if (!config.isActiveAt(clock.now())) {
      _disable();
    } else if (previousState != RemoteLoggingState.enabled || previous != config) {
      _enable(config);
    }

    if (previousState != _state || previous != config) {
      _logger.info('Remote logging ${_state.name}: $config');
    }
  }

  void _enable(RemoteLoggingConfig config) {
    _state = RemoteLoggingState.enabled;
    _replaceAppender(config);
    _scheduleExpiry(config.expiresAt);

    final appender = _appender!;
    while (_buffer.isNotEmpty) {
      appender.handle(_buffer.removeFirst());
    }
  }

  void _disable() {
    _state = RemoteLoggingState.disabled;
    _buffer.clear();
    _expiryTimer?.cancel();
    _expiryTimer = null;
    final appender = _appender;
    _appender = null;
    if (appender != null) unawaited(appender.discard());
  }

  void _replaceAppender(RemoteLoggingConfig config) {
    final old = _appender;
    final formatter = AnonymizingFormatter(
      anonymizationType: config.anonymization ? AnonymizationType.full : AnonymizationType.none,
      wrappedFormatter: const RemoteFormatter(),
    );
    _appender = _appenderFactory(
      endpoint: config.endpoint!,
      minLevel: _effectiveLevel(config),
      formatter: formatter,
      labels: _labels,
    );
    // The records the old appender holds were taken under the settings they
    // were meant for; let it send them.
    if (old != null) unawaited(old.dispose());
  }

  void _scheduleExpiry(DateTime? expiresAt) {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    if (expiresAt == null) return;
    // A long delay is cut into steps: on the web a timer longer than about
    // 24 days fires at once.
    final remaining = expiresAt.difference(clock.now());
    final delay = remaining > _maxExpiryStep ? _maxExpiryStep : remaining;
    _expiryTimer = Timer(delay, _checkExpiry);
  }

  static const _maxExpiryStep = Duration(days: 1);

  void _checkExpiry() {
    final config = _config;
    if (_state != RemoteLoggingState.enabled || config == null) return;
    if (config.isActiveAt(clock.now())) {
      _scheduleExpiry(config.expiresAt);
    } else {
      _disable();
      _logger.info('Remote logging expired at ${config.expiresAt}');
    }
  }

  Level _effectiveLevel(RemoteLoggingConfig config) => config.level ?? defaultLevel;

  void _handle(LogRecord record) {
    switch (_state) {
      case RemoteLoggingState.unknown:
        _buffer.addLast(record);
        while (_buffer.length > bufferCapacity) {
          _buffer.removeFirst();
        }
      case RemoteLoggingState.enabled:
        // The timer may be late, or the clock changed under it: every record
        // checks the end on its own.
        final config = _config!;
        if (!config.isActiveAt(clock.now())) {
          _checkExpiry();
          return;
        }
        _appender?.handle(record);
      case RemoteLoggingState.disabled:
        break;
    }
  }

  /// Stops taking records and sends what the appender still holds.
  @override
  Future<void> dispose() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    final appender = _appender;
    _appender = null;
    await appender?.dispose();
  }

  static RemoteLogAppenderFactory _defaultAppenderFactory(int batchSize) {
    return ({required endpoint, required minLevel, required formatter, required labels}) {
      return FilteredLogzIoAppender(
        formatter: formatter,
        url: endpoint.toString(),
        // The log receiver of the core authenticates the app on its own and
        // ignores a token in the request.
        apiToken: '',
        bufferSize: batchSize,
        labels: labels,
        minLevel: minLevel,
      );
    };
  }
}
