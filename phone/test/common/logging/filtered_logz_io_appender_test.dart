import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/common/logging/anonymizing_formatter.dart';
import 'package:webtrit_phone/common/logging/logging.dart';

void main() {
  late List<http.Request> requests;
  late MockClient client;

  setUp(() {
    requests = [];
    client = MockClient((request) async {
      requests.add(request);
      return http.Response('', 200);
    });
  });

  FilteredLogzIoAppender appender({int batchSize = 100}) => FilteredLogzIoAppender(
    formatter: AnonymizingFormatter(wrappedFormatter: const RemoteFormatter()),
    url: 'https://core.example.com/tenant/t1/mobile-logs',
    minLevel: Level.INFO,
    batchSize: batchSize,
    labels: const {'app': 'test'},
    httpClient: client,
  );

  void logBurst(FilteredLogzIoAppender appender, int count) {
    for (var i = 0; i < count; i++) {
      appender.handle(LogRecord(Level.INFO, 'm$i', 'test'));
    }
  }

  int linesOf(http.Request request) => request.body.split('\n').length;

  test('a burst goes out in full batches, and the rest when the batch delay passes', () {
    fakeAsync((async) {
      final sut = appender();

      logBurst(sut, 250);
      async.flushMicrotasks();

      expect(requests.map(linesOf), [100, 100]);

      async.elapse(FilteredLogzIoAppender.defaultBatchDelay);

      expect(requests.map(linesOf), [100, 100, 50]);
    });
  });

  test('never sends a request without records', () {
    fakeAsync((async) {
      final sut = appender(batchSize: 1);

      logBurst(sut, 50);
      async.elapse(const Duration(minutes: 1));
      sut.flush();
      async.flushMicrotasks();

      expect(requests, hasLength(50));
      expect(requests.where((r) => r.body.isEmpty), isEmpty);
    });
  });

  test('dispose delivers the records still batched before it closes the client', () async {
    final sut = appender();
    logBurst(sut, 3);

    await sut.dispose();

    expect(requests, hasLength(1));
    expect(linesOf(requests.single), 3);
  });

  test('discard drops the records still batched', () async {
    final sut = appender();
    logBurst(sut, 3);

    await sut.discard();

    expect(requests, isEmpty);
  });

  test('posts NDJSON as JSON with only the type in the query, no token', () async {
    final sut = appender();
    logBurst(sut, 2);

    await sut.flush();

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, '/tenant/t1/mobile-logs');
    expect(request.url.queryParameters, {'type': 'flutterlog'});
    expect(request.url.query, isNot(contains('token')));
    expect(request.headers['content-type'], startsWith('application/json'));

    final lines = request.body.split('\n').map((l) => jsonDecode(l) as Map<String, dynamic>).toList();
    expect(lines.map((l) => l['message']), ['m0', 'm1']);
    expect(lines.first, containsPair('app', 'test'));
    expect(lines.first, containsPair('lvl', 'INFO'));
  });

  test('records below the level are not sent', () async {
    final sut = appender();
    sut.handle(LogRecord(Level.FINE, 'fine', 'test'));
    sut.handle(LogRecord(Level.INFO, 'info', 'test'));

    await sut.flush();

    expect(linesOf(requests.single), 1);
  });
}
