import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:logging_appenders/base_remote_appender.dart';

import 'package:webtrit_phone/common/logging/logging.dart';
import 'package:webtrit_phone/models/models.dart';

/// Records what would be sent instead of sending it.
class _FakeAppender extends FilteredLogzIoAppender {
  _FakeAppender({required this.endpoint, required super.minLevel, required super.formatter, required super.labels})
    : super(url: endpoint.toString(), apiToken: '');

  final Uri endpoint;
  final lines = <String>[];
  bool discarded = false;
  bool disposed = false;

  @override
  Future<void> log(Level logLevel, DateTime time, String line, Map<String, String> lineLabels) async {
    lines.add(line);
  }

  @override
  Future<void> sendLogEventsWithHttp(
    List<LogEntry> entries,
    Map<String, String> userProperties,
    Future<void> cancelToken,
  ) async {}

  @override
  Future<void> discard() async {
    discarded = true;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await super.dispose();
  }
}

class _MemoryStore implements RemoteLoggingConfigStore {
  _MemoryStore([this.config]);

  RemoteLoggingConfig? config;

  @override
  RemoteLoggingConfig? read() => config;

  @override
  Future<void> write(RemoteLoggingConfig config) async {
    this.config = config;
  }
}

void main() {
  final logger = Logger('remote_logging_test');
  final endpoint = Uri.parse('https://core.example.com/tenant/t1/mobile-logs');
  final otherEndpoint = Uri.parse('https://other.example.com/mobile-logs');
  final start = DateTime.utc(2026, 11, 10, 12);

  late List<_FakeAppender> appenders;
  late List<CoreRemoteLoggingService> services;

  RemoteLoggingConfig enabled({Level? level, bool anonymization = true, DateTime? expiresAt, Uri? to}) =>
      RemoteLoggingConfig(
        enabled: true,
        anonymization: anonymization,
        level: level,
        expiresAt: expiresAt,
        endpoint: to ?? endpoint,
      );

  CoreRemoteLoggingService create({
    RemoteLoggingConfigStore? store,
    int bufferCapacity = 2000,
    bool bufferUntilConfigured = true,
  }) {
    final service = CoreRemoteLoggingService(
      defaultLevel: Level.INFO,
      store: store,
      bufferCapacity: bufferCapacity,
      bufferUntilConfigured: bufferUntilConfigured,
      appenderFactory: ({required endpoint, required minLevel, required formatter, required labels}) {
        final appender = _FakeAppender(endpoint: endpoint, minLevel: minLevel, formatter: formatter, labels: labels);
        appenders.add(appender);
        return appender;
      },
    )..initialize(const {'app': 'test'});
    services.add(service);
    return service;
  }

  /// Lines of [appender] this test logged, without the service's own notes.
  List<String> sent(_FakeAppender appender) => appender.lines.where((l) => l.contains('msg-')).toList();

  setUp(() {
    Logger.root.level = Level.ALL;
    appenders = [];
    services = [];
  });

  tearDown(() async {
    for (final service in services) {
      await service.dispose();
    }
  });

  group('while the config is unknown', () {
    test('records are held and nothing is sent', () {
      final service = create();

      logger.info('msg-1');
      logger.warning('msg-2');

      expect(service.state, RemoteLoggingState.unknown);
      expect(appenders, isEmpty);
      expect(service.bufferedRecords.map((r) => r.message), containsAll(['msg-1', 'msg-2']));
    });

    test('the buffer keeps only the newest records', () {
      final service = create(bufferCapacity: 3);

      for (var i = 0; i < 10; i++) {
        logger.info('msg-$i');
      }

      expect(service.bufferedRecords.map((r) => r.message), ['msg-7', 'msg-8', 'msg-9']);
    });
  });

  group('when the config becomes enabled', () {
    test('the held records are sent first, filtered by level, then new ones follow', () {
      fakeAsync((async) {
        final service = create();
        logger.fine('msg-fine');
        logger.info('msg-info');
        logger.warning('msg-warning');

        service.applyConfig(enabled(level: Level.INFO));
        logger.info('msg-after');

        expect(service.state, RemoteLoggingState.enabled);
        expect(appenders.single.endpoint, endpoint);
        expect(sent(appenders.single), [contains('msg-info'), contains('msg-warning'), contains('msg-after')]);
        expect(service.bufferedRecords, isEmpty);
      }, initialTime: start);
    });

    test('the default level applies when the core names none', () {
      fakeAsync((async) {
        final service = create();
        service.applyConfig(enabled());

        logger.fine('msg-fine');
        logger.info('msg-info');

        expect(service.minLevel, Level.INFO);
        expect(sent(appenders.single), [contains('msg-info')]);
      }, initialTime: start);
    });

    test('anonymization follows the config', () {
      fakeAsync((async) {
        final service = create();
        service.applyConfig(enabled(anonymization: true));
        logger.info('msg-a sip:1234@pbx.example.com');

        service.applyConfig(enabled(anonymization: false));
        logger.info('msg-b sip:1234@pbx.example.com');

        expect(sent(appenders[0]), [contains('msg-a sip:[REDACTED]@pbx.example.com')]);
        expect(sent(appenders[1]), [contains('msg-b sip:1234@pbx.example.com')]);
      }, initialTime: start);
    });
  });

  group('when the config becomes disabled', () {
    test('from unknown, the held records are dropped', () {
      final service = create();
      logger.info('msg-1');

      service.applyConfig(RemoteLoggingConfig.disabled);
      logger.info('msg-2');

      expect(service.state, RemoteLoggingState.disabled);
      expect(service.bufferedRecords, isEmpty);
      expect(appenders, isEmpty);
    });

    test('from enabled, the appender is discarded unsent and nothing more goes out', () {
      fakeAsync((async) {
        final service = create();
        service.applyConfig(enabled());
        logger.info('msg-1');

        service.applyConfig(RemoteLoggingConfig.disabled);
        logger.info('msg-2');

        expect(service.state, RemoteLoggingState.disabled);
        expect(service.minLevel, Level.OFF);
        expect(appenders.single.discarded, isTrue);
        expect(sent(appenders.single), [contains('msg-1')]);
        expect(service.bufferedRecords, isEmpty);
      }, initialTime: start);
    });

    test('an absent block of the core turns logging off', () {
      fakeAsync((async) {
        final service = create();
        service.applyConfig(enabled());

        service.applyFromCore(null, Uri.parse('https://core.example.com'));

        expect(service.state, RemoteLoggingState.disabled);
      }, initialTime: start);
    });
  });

  group('expires_at', () {
    test('a config already past its end is applied as disabled', () {
      fakeAsync((async) {
        final service = create();
        logger.info('msg-1');

        service.applyConfig(enabled(expiresAt: start.subtract(const Duration(minutes: 1))));

        expect(service.state, RemoteLoggingState.disabled);
        expect(service.bufferedRecords, isEmpty);
        expect(appenders, isEmpty);
      }, initialTime: start);
    });

    test('logging stops when the end passes without a word from the core', () {
      fakeAsync((async) {
        final service = create();
        service.applyConfig(enabled(expiresAt: start.add(const Duration(hours: 1))));
        logger.info('msg-before');

        async.elapse(const Duration(hours: 1, seconds: 1));
        logger.info('msg-after');

        expect(service.state, RemoteLoggingState.disabled);
        expect(appenders.single.discarded, isTrue);
        expect(sent(appenders.single), [contains('msg-before')]);
      }, initialTime: start);
    });

    test('an end days away is still honoured', () {
      fakeAsync((async) {
        final service = create();
        service.applyConfig(enabled(expiresAt: start.add(const Duration(days: 3))));

        async.elapse(const Duration(days: 2));
        expect(service.state, RemoteLoggingState.enabled);

        async.elapse(const Duration(days: 1, seconds: 1));
        expect(service.state, RemoteLoggingState.disabled);
      }, initialTime: start);
    });

    test('a stored config past its end does not send at the next start', () {
      fakeAsync((async) {
        final store = _MemoryStore(enabled(expiresAt: start.subtract(const Duration(days: 1))));

        final service = create(store: store);
        logger.info('msg-1');

        expect(service.state, RemoteLoggingState.disabled);
        expect(appenders, isEmpty);
      }, initialTime: start);
    });
  });

  group('a config change at runtime', () {
    test('moves sending to the new endpoint and level; the old appender sends what it holds', () {
      fakeAsync((async) {
        final service = create();
        service.applyConfig(enabled(level: Level.INFO));
        logger.info('msg-1');

        service.applyConfig(enabled(level: Level.WARNING, to: otherEndpoint));
        logger.info('msg-2');
        logger.warning('msg-3');

        expect(appenders, hasLength(2));
        expect(appenders[0].disposed, isTrue);
        expect(appenders[0].discarded, isFalse);
        expect(appenders[1].endpoint, otherEndpoint);
        expect(sent(appenders[0]), [contains('msg-1')]);
        expect(sent(appenders[1]), [contains('msg-3')]);
      }, initialTime: start);
    });

    test('the same config again keeps the appender', () {
      fakeAsync((async) {
        final service = create();
        service.applyConfig(enabled());
        service.applyConfig(enabled());

        expect(appenders, hasLength(1));
      }, initialTime: start);
    });

    test('disabled then enabled again starts sending again', () {
      fakeAsync((async) {
        final service = create();
        service.applyConfig(RemoteLoggingConfig.disabled);
        logger.info('msg-1');

        service.applyConfig(enabled());
        logger.info('msg-2');

        expect(service.state, RemoteLoggingState.enabled);
        expect(sent(appenders.single), [contains('msg-2')]);
      }, initialTime: start);
    });
  });

  group('the stored config', () {
    test('applies at once at the next start', () {
      fakeAsync((async) {
        final service = create(store: _MemoryStore(enabled()));
        logger.info('msg-1');

        expect(service.state, RemoteLoggingState.enabled);
        expect(sent(appenders.last), [contains('msg-1')]);
      }, initialTime: start);
    });

    test('is written on every applied config', () {
      fakeAsync((async) {
        final store = _MemoryStore();
        final service = create(store: store);

        service.applyConfig(enabled(level: Level.FINE));
        async.flushMicrotasks();
        expect(store.config, enabled(level: Level.FINE));

        service.applyConfig(RemoteLoggingConfig.disabled);
        async.flushMicrotasks();
        expect(store.config, RemoteLoggingConfig.disabled);
      }, initialTime: start);
    });

    test('without one, a service that is not to buffer starts disabled', () {
      final service = create(bufferUntilConfigured: false);
      logger.info('msg-1');

      expect(service.state, RemoteLoggingState.disabled);
      expect(service.bufferedRecords, isEmpty);
    });
  });

  test('applyFromCore posts to the tenant URL followed by the path', () {
    fakeAsync((async) {
      final service = create();

      service.applyFromCore(
        MobileRemoteLoggingInfo(available: true, enabled: true, level: 'WARNING', path: '/mobile-logs'),
        Uri.parse('https://core.example.com/tenant/t1'),
      );

      expect(service.state, RemoteLoggingState.enabled);
      expect(service.minLevel, Level.WARNING);
      expect(appenders.single.endpoint, endpoint);
    }, initialTime: start);
  });

  test('new labels replace the appender while enabled', () {
    fakeAsync((async) {
      final service = create();
      service.applyConfig(enabled());

      service.initialize(const {'app': 'test', 'coreUrl': 'x'});

      expect(appenders, hasLength(2));
      expect(appenders.last.labels, containsPair('coreUrl', 'x'));
    }, initialTime: start);
  });
}
