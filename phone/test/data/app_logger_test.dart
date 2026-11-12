import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/common/common.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/models/models.dart';

class _FakeRemote implements RemoteLoggingService {
  @override
  Level minLevel = Level.OFF;

  @override
  void Function()? onMinLevelChanged;

  void sendFrom(Level level) {
    minLevel = level;
    onMinLevelChanged?.call();
  }

  @override
  void initialize(Map<String, String> labels) {}

  @override
  Future<void> dispose() async {}
}

void main() {
  const config = LoggingConfig(logLevel: Level.INFO, monitorCheckInterval: Duration(seconds: 15));

  late _FakeRemote remote;
  late AppLogger appLogger;

  setUp(() async {
    remote = _FakeRemote();
    appLogger = await AppLogger.init(config, remote, () => const {});
  });

  tearDown(() async {
    await appLogger.dispose();
    Logger.root.clearListeners();
  });

  test('the root logger follows the configured level while nothing is sent', () {
    expect(Logger.root.level, Level.INFO);
    expect(EquatableConfig.stringify, isFalse);
  });

  test('a lower remote level opens the root logger, and closes it again when sending stops', () {
    remote.sendFrom(Level.FINE);

    expect(Logger.root.level, Level.FINE);
    expect(EquatableConfig.stringify, isTrue);

    remote.sendFrom(Level.OFF);

    expect(Logger.root.level, Level.INFO);
    expect(EquatableConfig.stringify, isFalse);
  });

  test('a higher remote level leaves the configured one', () {
    remote.sendFrom(Level.WARNING);

    expect(Logger.root.level, Level.INFO);
  });

  test('a new local config keeps the lower remote level', () {
    remote.sendFrom(Level.FINER);

    appLogger.applyConfig(const LoggingConfig(logLevel: Level.WARNING, monitorCheckInterval: Duration(seconds: 15)));

    expect(Logger.root.level, Level.FINER);
  });
}
