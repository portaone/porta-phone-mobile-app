import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;
import 'package:webtrit_phone/repositories/repositories.dart';

import '../mocks/mocks.dart';

void main() {
  late MockWebtritApiClient apiClient;
  late AppRepository repository;

  setUpAll(() {
    registerFallbackValue(const api.AppStatus(register: true));
  });

  setUp(() {
    apiClient = MockWebtritApiClient();
    repository = AppRepository(webtritApiClient: apiClient, token: 'user_token');
  });

  test('reads and writes the register flag with the session token', () async {
    when(() => apiClient.getAppStatus(any())).thenAnswer((_) async => const api.AppStatus(register: false));
    when(() => apiClient.updateAppStatus(any(), any())).thenAnswer((_) async {});

    expect(await repository.getRegisterStatus(), isFalse);
    await repository.setRegisterStatus(true);

    verify(() => apiClient.getAppStatus('user_token')).called(1);
    verify(() => apiClient.updateAppStatus('user_token', const api.AppStatus(register: true))).called(1);
  });

  // A rejected session is not this repository's concern: the API client
  // reports it (see packages/api/test/api_client_session_rejection_test.dart).
  test('a failure reaches the caller unchanged', () async {
    final failure = api.SessionMissingException(
      url: Uri.https('demo.webtrit.com', '/api/v1/app/status'),
      requestId: 'r',
      statusCode: 401,
    );
    when(() => apiClient.getAppStatus(any())).thenThrow(failure);

    await expectLater(repository.getRegisterStatus(), throwsA(same(failure)));
  });
}
