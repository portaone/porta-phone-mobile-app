import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;
import 'package:webtrit_phone/app/session/session.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../mocks/mocks.dart';

class _RecordingSessionGuard implements SessionGuard {
  final unauthorized = <Exception>[];

  @override
  void onUnauthorized(Exception e) => unauthorized.add(e);
}

final _url = Uri.https('demo.webtrit.com', '/api/v1/app/status');

void main() {
  late MockWebtritApiClient apiClient;
  late _RecordingSessionGuard sessionGuard;
  late AppRepository repository;

  setUpAll(() {
    registerFallbackValue(const api.AppStatus(register: true));
  });

  setUp(() {
    apiClient = MockWebtritApiClient();
    sessionGuard = _RecordingSessionGuard();
    repository = AppRepository(webtritApiClient: apiClient, token: 'user_token', sessionGuard: sessionGuard);
  });

  void failWith(Exception failure) {
    when(() => apiClient.getAppStatus(any())).thenThrow(failure);
    when(() => apiClient.updateAppStatus(any(), any())).thenThrow(failure);
  }

  // The register status is fetched on every start and every regained
  // connection, so it is often the first request to learn that the session is
  // gone. It must end the session the way every other request does.
  final rejections = <String, Exception Function()>{
    'an unauthorized token': () => api.UnauthorizedException(url: _url, requestId: 'r', statusCode: 401),
    'a missing session': () => api.SessionMissingException(url: _url, requestId: 'r', statusCode: 401),
    'a user that no longer exists': () => api.UserNotFoundException(url: _url, requestId: 'r', statusCode: 404),
  };

  for (final MapEntry(key: name, value: rejection) in rejections.entries) {
    test('$name is handed to the session guard and rethrown, on read and on write', () async {
      final failure = rejection();
      failWith(failure);

      await expectLater(repository.getRegisterStatus(), throwsA(same(failure)));
      await expectLater(repository.setRegisterStatus(false), throwsA(same(failure)));

      expect(sessionGuard.unauthorized, [same(failure), same(failure)]);
    });
  }

  test('a failure that says nothing about the session stays with the caller', () async {
    failWith(api.RequestFailure(url: _url, requestId: 'r', statusCode: 500));

    await expectLater(repository.getRegisterStatus(), throwsA(isA<api.RequestFailure>()));

    expect(sessionGuard.unauthorized, isEmpty);
  });

  test('reads and writes the register flag with the session token', () async {
    when(() => apiClient.getAppStatus(any())).thenAnswer((_) async => const api.AppStatus(register: false));
    when(() => apiClient.updateAppStatus(any(), any())).thenAnswer((_) async {});

    expect(await repository.getRegisterStatus(), isFalse);
    await repository.setRegisterStatus(true);

    verify(() => apiClient.getAppStatus('user_token')).called(1);
    verify(() => apiClient.updateAppStatus('user_token', const api.AppStatus(register: true))).called(1);
    expect(sessionGuard.unauthorized, isEmpty);
  });
}
