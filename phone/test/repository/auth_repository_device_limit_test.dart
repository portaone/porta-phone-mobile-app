import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/utils.dart';

class _MockApiClientFactory extends Mock implements WebtritApiClientFactory {}

class _MockApiClient extends Mock implements WebtritApiClient {}

class _MockSystemInfoRemoteDatasource extends Mock implements SystemInfoRemoteDatasource {}

const _coreUrl = 'https://core.example.com';
const _tenantId = 'tenant-1';

DeviceLimitReachedException _refusal({
  List<String> sessions = const ['session-1', 'session-2'],
  String? token = 'pending',
}) {
  return DeviceLimitReachedException(
    url: Uri.parse('$_coreUrl/api/v1/session'),
    requestId: 'test-request-id',
    statusCode: 409,
    sessions: [
      for (final id in sessions)
        UserSession(
          id: id,
          current: false,
          status: UserSessionStatus.active,
          userAgent: 'agent of $id',
          appType: AppType.ios,
        ),
    ],
    pendingLoginToken: token,
  );
}

// The backend's device limit refusal is turned into a waiting login here, where
// the sessions and the token it carries meet the tenant the request was made
// in. Every call that ends in a session does it the same way.
void main() {
  late _MockApiClient client;
  late AuthRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const SessionLoginCredential(type: AppType.android, identifier: 'x', login: 'x', password: 'x'),
    );
    registerFallbackValue(const SessionUserCredential(type: AppType.android, identifier: 'x'));
    registerFallbackValue(const SessionOtpProvisional(otpId: 'x'));
    registerFallbackValue(const RequestOptions());
  });

  setUp(() {
    client = _MockApiClient();
    final factory = _MockApiClientFactory();
    when(
      () => factory.createWebtritApiClient(
        coreUrl: any(named: 'coreUrl'),
        tenantId: any(named: 'tenantId'),
      ),
    ).thenReturn(client);

    repository = AuthRepositoryImpl(
      apiClientFactory: factory,
      systemInfoRemoteDatasource: _MockSystemInfoRemoteDatasource(),
      appIdentifier: 'device-id',
      appBundleId: 'com.example.app',
    );
  });

  final calls = <String, (void Function(_MockApiClient, Object), Future<Object?> Function(AuthRepository, String))>{
    'login': (
      (client, error) => when(() => client.createSession(any())).thenThrow(error),
      (repository, tenantId) =>
          repository.login(coreUrl: _coreUrl, tenantId: tenantId, userRef: 'user', password: 'secret'),
    ),
    'verifyOtp': (
      (client, error) => when(() => client.verifySessionOtp(any(), any())).thenThrow(error),
      (repository, tenantId) => repository.verifyOtp(
        coreUrl: _coreUrl,
        tenantId: tenantId,
        sessionOtpProvisional: const SessionOtpProvisional(otpId: 'otp-1'),
        code: '123456',
      ),
    ),
    'signup': (
      (client, error) => when(
        () => client.createUser(
          any(),
          extraPayload: any(named: 'extraPayload'),
          options: any(named: 'options'),
        ),
      ).thenThrow(error),
      (repository, tenantId) => repository.signup(coreUrl: _coreUrl, tenantId: tenantId, email: 'user@example.com'),
    ),
    'completeLogin': (
      (client, error) => when(
        () => client.completeSession(
          pendingLoginToken: any(named: 'pendingLoginToken'),
          revokeSessionId: any(named: 'revokeSessionId'),
        ),
      ).thenThrow(error),
      (repository, tenantId) => repository.completeLogin(
        coreUrl: _coreUrl,
        tenantId: tenantId,
        pendingLoginToken: 'pending',
        revokeSessionId: 'session-1',
      ),
    ),
  };

  for (final MapEntry(key: name, value: (answerWith, call)) in calls.entries) {
    test('$name leaves the login waiting with the devices, the token and the tenant of the request', () async {
      answerWith(client, _refusal());

      await expectLater(
        call(repository, _tenantId),
        throwsA(
          isA<LoginDeviceLimitReached>()
              .having((e) => e.pendingLogin?.token, 'token', 'pending')
              .having((e) => e.pendingLogin?.tenantId, 'tenantId', _tenantId)
              .having((e) => e.pendingLogin?.sessions.map((s) => s.id), 'sessions', ['session-1', 'session-2']),
        ),
      );
    });
  }

  test('the tenant of a waiting login is the one the request was made in', () async {
    final (answerWith, call) = calls['signup']!;
    answerWith(client, _refusal());

    await expectLater(
      call(repository, 'embedded-tenant'),
      throwsA(isA<LoginDeviceLimitReached>().having((e) => e.pendingLogin?.tenantId, 'tenantId', 'embedded-tenant')),
    );
  });

  test('the devices are handed over as the app shows them elsewhere', () async {
    final (answerWith, call) = calls['login']!;
    answerWith(client, _refusal(sessions: ['session-1']));

    late LoginDeviceLimitReached refusal;
    try {
      await call(repository, _tenantId);
    } on LoginDeviceLimitReached catch (e) {
      refusal = e;
    }

    final device = refusal.pendingLogin!.sessions.single;
    expect(device.id, 'session-1');
    expect(device.current, isFalse);
    expect(device.userAgent, 'agent of session-1');
    expect(device.appType, AppType.ios);
  });

  test('without a token nothing is left waiting', () async {
    final (answerWith, call) = calls['login']!;
    answerWith(client, _refusal(sessions: [], token: null));

    await expectLater(
      call(repository, _tenantId),
      throwsA(isA<LoginDeviceLimitReached>().having((e) => e.pendingLogin, 'pendingLogin', isNull)),
    );
  });

  test('with a token and no device to pick nothing is left waiting either', () async {
    final (answerWith, call) = calls['login']!;
    answerWith(client, _refusal(sessions: []));

    await expectLater(
      call(repository, _tenantId),
      throwsA(isA<LoginDeviceLimitReached>().having((e) => e.pendingLogin, 'pendingLogin', isNull)),
    );
  });

  test('the token is not printed with the refusal', () async {
    final (answerWith, call) = calls['login']!;
    answerWith(client, _refusal(token: 'a-token-that-must-not-leak'));

    await expectLater(
      call(repository, _tenantId),
      throwsA(
        isA<LoginDeviceLimitReached>().having((e) => '$e', 'toString', isNot(contains('a-token-that-must-not-leak'))),
      ),
    );
  });

  test('any other refusal passes through as it came', () async {
    final (answerWith, call) = calls['login']!;
    final switchLimit = DeviceSwitchLimitReachedException(
      url: Uri.parse('$_coreUrl/api/v1/session'),
      requestId: 'test-request-id',
      statusCode: 403,
    );
    answerWith(client, switchLimit);

    await expectLater(call(repository, _tenantId), throwsA(same(switchLimit)));
  });
}
