import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:fake_async/fake_async.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/data/app_preferences.dart';
import 'package:webtrit_phone/features/user_info/user_info.dart';
import 'package:webtrit_phone/repositories/user_info/user_repository.dart';
import 'package:webtrit_phone/services/polling_service.dart';
import 'package:webtrit_phone/services/polling_task_handle.dart';

import '../mocks/fake_connectivity_service.dart';
import 'user_repository_integration_harness.dart';

const _interval = Duration(seconds: 10);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserRepositoryIntegrationHarness harness;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    harness = UserRepositoryIntegrationHarness(await AppPreferencesImpl.init());
    addTearDown(harness.dispose);
    await harness.local.setInfo(UserRepositoryIntegrationHarness.cachedUser);
  });

  test('HTTP user data is mapped, persisted and replayed without duplicate updates', () async {
    final updates = <UserInfo>[];
    final subscription = harness.repository.getAndListen().listen(updates.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    await harness.worker.refresh();
    await harness.worker.refresh();
    await pumpEventQueue();

    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    final reopenedLocal = UserLocalDatasourcePrefsImpl(await AppPreferencesImpl.init());
    expect(reopenedLocal.getInfo(), UserRepositoryIntegrationHarness.updatedUser);
    expect(updates, [UserRepositoryIntegrationHarness.cachedUser, UserRepositoryIntegrationHarness.updatedUser]);
    expect(await harness.repository.getAndListen().first, UserRepositoryIntegrationHarness.updatedUser);
    expect(harness.requests, hasLength(2));
    expect(harness.sessionRejections, isEmpty);
  });

  test('native lifecycle callbacks can refresh outside the test zone', () async {
    await Zone.root.run(harness.worker.refresh);
    expect(harness.requests, hasLength(1));
    expect(harness.local.getInfo(), UserRepositoryIntegrationHarness.updatedUser);
  });

  for (final status in [429, 503]) {
    test('HTTP $status failures back off without transport retries, then recover', () {
      fakeAsync((async) {
        harness.respond = (_) async => harness.requests.length <= 2
            ? http.Response('{"code":"backend_unavailable"}', status)
            : UserRepositoryIntegrationHarness.successResponse();
        final updates = <UserInfo>[];
        final streamErrors = <Object>[];
        final subscription = harness.repository.getAndListen().listen(updates.add, onError: streamErrors.add);
        try {
          async.flushMicrotasks();
          final task = _register(harness.worker);
          async.flushMicrotasks();

          expect(task.state.phase, PollingTaskPhase.failed);
          expect(task.state.error, isA<api.RequestFailure>().having((e) => e.statusCode, 'status', status));
          expect(task.state.stackTrace, isNotNull);
          expect(harness.requests, hasLength(1));
          expect(harness.local.getInfo(), UserRepositoryIntegrationHarness.cachedUser);

          async.elapse(const Duration(seconds: 19));
          expect(harness.requests, hasLength(1));
          async.elapse(const Duration(seconds: 1));
          expect(harness.requests, hasLength(2));
          expect(task.state.phase, PollingTaskPhase.failed);
          async.elapse(const Duration(seconds: 39));
          expect(harness.requests, hasLength(2));
          async.elapse(const Duration(seconds: 1));
          expect(harness.requests, hasLength(3));
          expect(task.state.phase, PollingTaskPhase.succeeded);
          expect(harness.local.getInfo(), UserRepositoryIntegrationHarness.updatedUser);

          async.elapse(const Duration(seconds: 9));
          expect(harness.requests, hasLength(3));
          async.elapse(const Duration(seconds: 1));
          expect(harness.requests, hasLength(4), reason: 'success restores the base interval');
          expect(updates, [UserRepositoryIntegrationHarness.cachedUser, UserRepositoryIntegrationHarness.updatedUser]);
          expect(streamErrors, isEmpty);
          expect(harness.sessionRejections, isEmpty);
        } finally {
          // Cancel inside virtual time so async* cleanup can drain its microtasks.
          unawaited(subscription.cancel());
          async.flushMicrotasks();
        }
      });
    });
  }

  test('exhausted transport retries fail one polling cycle and preserve the original timeout', () {
    fakeAsync((async) {
      final error = TimeoutException('controlled transport timeout');
      final stack = StackTrace.fromString('HTTP transport origin');
      harness.respond = (_) => Future<http.Response>.error(error, stack);
      final task = _register(harness.worker);
      async.flushMicrotasks();

      expect(harness.requests, hasLength(1));
      expect(task.state.phase, PollingTaskPhase.running);
      async.elapse(const Duration(seconds: 3));
      expect(harness.requests, hasLength(4), reason: 'the real API client owns three transport retries');
      expect(harness.requests.map((request) => request.headers['x-request-id']).toSet(), hasLength(1));
      expect(task.state.phase, PollingTaskPhase.failed);
      expect(task.state.error, same(error));
      expect(task.state.stackTrace, same(stack));
      expect(harness.local.getInfo(), UserRepositoryIntegrationHarness.cachedUser);

      harness.respond = (_) async => UserRepositoryIntegrationHarness.successResponse();
      async.elapse(const Duration(seconds: 19));
      expect(harness.requests, hasLength(4));
      async.elapse(const Duration(seconds: 1));
      expect(harness.requests, hasLength(5), reason: 'four HTTP attempts count as one failed polling cycle');
      expect(task.state.phase, PollingTaskPhase.succeeded);
      expect(harness.local.getInfo(), UserRepositoryIntegrationHarness.updatedUser);
      expect(harness.sessionRejections, isEmpty);
    });
  });

  for (final rejection in [
    (status: 401, code: 'token_invalid', type: isA<api.UnauthorizedException>()),
    (status: 401, code: 'session_missing', type: isA<api.SessionMissingException>()),
    (status: 404, code: 'user_not_found', type: isA<api.UserNotFoundException>()),
  ]) {
    test('${rejection.code} is reported as a session rejection and manual caller as the same failed cycle', () async {
      harness.respond = (_) async => http.Response('{"code":"${rejection.code}"}', rejection.status);
      final task = _register(harness.worker, connected: false);

      await expectLater(task.runNow(), throwsA(rejection.type));

      expect(task.state.phase, PollingTaskPhase.failed);
      expect(harness.sessionRejections, hasLength(1));
      expect(task.state.error, same(harness.sessionRejections.single));
      expect(harness.local.getInfo(), UserRepositoryIntegrationHarness.cachedUser);
      expect(harness.requests, hasLength(1), reason: 'session rejections must not be retried by the API client');
    });
  }

  test('invalid user payload fails mapping without replacing the cache', () async {
    harness.respond = (_) async => http.Response('{"numbers":42}', 200);
    final task = _register(harness.worker, connected: false);

    await expectLater(task.runNow(), throwsA(isA<TypeError>()));

    expect(task.state.phase, PollingTaskPhase.failed);
    expect(harness.local.getInfo(), UserRepositoryIntegrationHarness.cachedUser);
    expect(harness.requests, hasLength(1));
    expect(harness.sessionRejections, isEmpty);
  });
}

PollingTaskHandle _register(UserInfoSyncWorker worker, {bool connected = true}) {
  final connectivity = FakeConnectivityService(initialConnected: connected);
  addTearDown(connectivity.dispose);
  final polling = PollingService(connectivityService: connectivity, options: const PollingOptions(jitterRatio: 0));
  addTearDown(polling.dispose);
  return polling.register(PollingRegistration(listener: worker, interval: _interval));
}
