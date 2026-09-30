import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/app/session/session_guard.dart';
import 'package:webtrit_phone/data/app_preferences.dart';
import 'package:webtrit_phone/features/user_info/user_info.dart';
import 'package:webtrit_phone/repositories/user_info/user_repository.dart';

/// Real repository, datasources and API mapping with only HTTP controlled.
///
/// Host tests supply mock-backed preferences; Patrol supplies native preferences.
class UserRepositoryIntegrationHarness {
  UserRepositoryIntegrationHarness(AppPreferences preferences) {
    client = api.WebtritApiClient.inner(Uri.parse('https://refresh.test'), '', httpClient: MockClient(_respond));
    client.sessionRejections.listen(sessionGuard.onUnauthorized);
    local = UserLocalDatasourcePrefsImpl(preferences);
    remote = UserRemoteDatasourceApiImpl(client, 'integration-token');
    repository = UserRepository(remoteDatasource: remote, localDatasource: local);
    worker = UserInfoSyncWorker(userRepository: repository);
  }

  static const cachedUser = UserInfo(
    numbers: Numbers(main: '1000'),
    balance: Balance(amount: 10),
  );
  static const updatedUser = UserInfo(
    numbers: Numbers(main: '1000', ext: '100'),
    balance: Balance(amount: 20, currency: 'USD'),
    firstName: 'Integration',
  );

  static http.Response successResponse() => http.Response(
    '{"numbers":{"main":"1000","ext":"100"},'
    '"balance":{"amount":20,"currency":"USD"},"first_name":"Integration"}',
    200,
    headers: {'content-type': 'application/json'},
  );

  final sessionGuard = _RecordingSessionGuard();
  final _assertionZone = Zone.current;
  final requests = <http.Request>[];
  late final api.WebtritApiClient client;
  late final UserLocalDatasourcePrefsImpl local;
  late final UserRemoteDatasourceApiImpl remote;
  late final UserRepository repository;
  late final UserInfoSyncWorker worker;

  Future<http.Response> Function(http.Request) respond = (_) async => successResponse();

  Future<http.Response> _respond(http.Request request) {
    // Native lifecycle callbacks enter through Flutter's binding zone. Keep
    // assertions in the test zone while response timers retain their caller's
    // zone, including FakeAsync in the host integration suite.
    _assertionZone.run(() => _expectUserRequest(request));
    requests.add(request);
    return respond(request);
  }

  void _expectUserRequest(http.Request request) {
    expectSync(request.method.toUpperCase(), 'GET');
    expectSync(request.url, Uri.parse('https://refresh.test/api/v1/user'));
    expectSync(request.headers['authorization'], 'Bearer integration-token');
  }

  Future<void> dispose() async {
    await worker.dispose();
    await remote.dispose();
    client.close();
  }
}

class _RecordingSessionGuard implements SessionGuard {
  final errors = <Exception>[];

  @override
  void onUnauthorized(Exception e) => errors.add(e);
}
