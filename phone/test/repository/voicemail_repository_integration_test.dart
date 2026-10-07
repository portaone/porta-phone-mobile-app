import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/services/polling_service.dart';
import 'package:webtrit_phone/services/polling_task_handle.dart';

import '../mocks/fake_connectivity_service.dart';
import 'voicemail_repository_integration_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late VoicemailRepositoryIntegrationHarness harness;

  setUp(() async {
    harness = VoicemailRepositoryIntegrationHarness(NativeDatabase.memory());
    addTearDown(harness.dispose);
    await harness.initialize();
  });

  test('all fetch callers wait for metadata mapping and the SQLite write', () async {
    harness.respond = _success;
    final write = Completer<void>();
    final writing = Completer<void>();
    harness.dao.beforeWrite = () {
      writing.complete();
      return write.future;
    };
    final updates = <List<Voicemail>>[];
    final subscription = harness.repository.watchVoicemails().listen(updates.add);
    addTearDown(subscription.cancel);
    var completed = false;
    final refresh = Future.wait([harness.repository.refresh(), harness.repository.fetchVoicemails()])
        .then((_) => completed = true);
    try {
      await writing.future.timeout(const Duration(seconds: 2));
      expect(completed, isFalse);
      expect(await harness.dao.getVoicemailById('message-1'), VoicemailRepositoryIntegrationHarness.cached);
      expect(updates.expand((items) => items).every((item) => item.sender == '1000'), isTrue);
    } finally {
      write.complete();
      await refresh;
    }
    await pumpEventQueue();
    final persisted = (await harness.dao.getVoicemailById('message-1'))!;
    expect(persisted.sender, '1001');
    expect(persisted.duration, 10);
    expect(persisted.seen, isTrue);
    expect(persisted.attachmentPath, harness.client.getVoicemailAttachmentUrl('message-1'));
    expect(updates.last.single.sender, '1001');
    // The list is the whole read: no message is asked about on its own.
    expect(harness.requests.map((request) => request.url.path), ['/api/v1/user/voicemails']);
  });

  for (final status in [401, 503]) {
    test('HTTP $status reaches all joiners while cached rows remain available', () async {
      harness.respond = (_) async => http.Response(status == 401 ? '{"code":"token_invalid"}' : 'unavailable', status);
      final results = await Future.wait([
        _failure(harness.repository.refresh()),
        _failure(harness.repository.fetchVoicemails()),
        _failure(harness.repository.removeVoicemail('message-1')),
      ]).timeout(const Duration(seconds: 2));
      final (error, stack) = results.first;
      expect(error, status == 401 ? isA<api.UnauthorizedException>() : isA<api.RequestFailure>());
      expect((error as api.RequestFailure).statusCode, status);
      for (final result in results.skip(1)) {
        expect(result.$1, same(error));
        expect(result.$2, same(stack));
      }
      expect(harness.sessionRejections, status == 401 ? [same(error)] : isEmpty);
      expect(await harness.dao.getVoicemailById('message-1'), VoicemailRepositoryIntegrationHarness.cached);
      expect(harness.requests, hasLength(1));
      harness.respond = _success;
      await harness.repository.refresh();
      expect((await harness.dao.getVoicemailById('message-1'))!.sender, '1001');
    });
  }

  for (final source in ['write', 'fallbackRead']) {
    test('$source failure preserves the original cycle outcome for polling and joiners', () async {
      final error = StateError('SQLite write boundary');
      final stack = StackTrace.fromString('write origin');
      if (source == 'write') {
        harness.respond = _success;
        harness.dao.beforeWrite = () => Future.error(error, stack);
      } else {
        harness.respond = (_) async {
          harness.dao.beforeRead = () => Future.error(StateError('fallback read failure'));
          return http.Response('original adapter failure', 503);
        };
      }
      final task = _register(harness);
      final joined = _failure(harness.repository.refresh());
      await _failed(task);
      final (actualError, actualStack) = await joined.timeout(const Duration(seconds: 2));
      expect(task.state.error, same(actualError));
      expect(task.state.stackTrace, same(actualStack));
      if (source == 'write') {
        expect(actualError, same(error));
        expect(actualStack, same(stack));
      } else {
        expect(actualError, isA<api.RequestFailure>().having((e) => e.statusCode, 'status', 503));
      }
      expect(await harness.dao.getVoicemailById('message-1'), VoicemailRepositoryIntegrationHarness.cached);
      harness.dao.beforeRead = null;
      harness.dao.beforeWrite = null;
      harness.respond = _success;
      await task.runNow();
      expect(task.state.phase, PollingTaskPhase.succeeded);
      expect((await harness.dao.getVoicemailById('message-1'))!.sender, '1001');
    });
  }

  for (final status in [422, 501]) {
    test('HTTP $status fails the attempted fetch then disables later remote work', () async {
      harness.respond = (_) async =>
          http.Response(status == 422 ? '{"code":"voicemail_not_configured"}' : 'not implemented', status);
      final (error, _) = await _failure(harness.repository.refresh());
      expect(
        error,
        status == 422 ? isA<api.VoicemailNotConfiguredException>() : isA<api.EndpointNotSupportedException>(),
      );
      expect(harness.repository.isActive, isFalse);
      await harness.repository.refresh();
      expect(harness.requests, hasLength(1));
    });
  }
}

Future<http.Response> _success(http.Request request) async => VoicemailRepositoryIntegrationHarness.listResponse();

Future<(Object, StackTrace)> _failure(Future<void> future) => future.then<(Object, StackTrace)>(
  (_) => throw StateError('A failed refresh completed normally.'),
  onError: (Object error, StackTrace stack) => (error, stack),
);

PollingTaskHandle _register(VoicemailRepositoryIntegrationHarness harness) {
  final connectivity = FakeConnectivityService(initialConnected: true);
  addTearDown(connectivity.dispose);
  final polling = PollingService(connectivityService: connectivity, options: const PollingOptions(jitterRatio: 0));
  addTearDown(polling.dispose);
  return polling.register(PollingRegistration(listener: harness.repository, interval: const Duration(seconds: 10)));
}

Future<void> _failed(PollingTaskHandle task) =>
    task.states.firstWhere((state) => state.phase == PollingTaskPhase.failed).timeout(const Duration(seconds: 2));
