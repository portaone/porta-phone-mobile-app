import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:api/api.dart';

const token = 'fake_token';

class MockHttpClient extends Mock implements http.Client {}

class FakeBaseRequest extends Fake implements http.BaseRequest {}

http.StreamedResponse _jsonResponse(Object json, int status) {
  final body = jsonEncode(json);
  return http.StreamedResponse(Stream.value(utf8.encode(body)), status, headers: {'content-type': 'application/json'});
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBaseRequest());
  });

  late MockHttpClient httpClient;
  late List<SessionRejection> rejections;
  late WebtritApiClient apiClient;

  setUp(() {
    httpClient = MockHttpClient();
    rejections = [];
    apiClient = WebtritApiClient.inner(Uri.parse('https://example.com'), 'tenant-id', httpClient: httpClient);
    apiClient.sessionRejections.listen(rejections.add);
  });

  tearDown(() => apiClient.close());

  void respond(int status, [String? code]) {
    when(() => httpClient.send(any())).thenAnswer((_) async => _jsonResponse({'code': ?code}, status));
  }

  // Whichever request learns that the session is over, the owner of the
  // session hears of it once, and the caller still gets the failure.
  final sessionEnding = <String, (int, String, Matcher)>{
    'a missing session': (401, 'session_missing', isA<SessionMissingException>()),
    'an invalidated token': (401, 'token_invalid', isA<UnauthorizedException>()),
    'a refused refresh token': (422, 'refresh_token_invalid', isA<UnauthorizedException>()),
    'an account that is gone': (404, 'user_not_found', isA<UserNotFoundException>()),
  };

  for (final MapEntry(key: name, value: (status, code, matcher)) in sessionEnding.entries) {
    test('$name is reported, then rethrown', () async {
      respond(status, code);

      await expectLater(apiClient.getAppStatus(token), throwsA(matcher));
      await pumpEventQueue();

      expect(rejections, [matcher]);
    });
  }

  test('a failure about the request, not the session, is not reported', () async {
    respond(500);
    await expectLater(apiClient.getAppStatus(token), throwsA(isA<RequestFailure>()));

    respond(403, 'password_change_required');
    await expectLater(apiClient.getAppStatus(token), throwsA(isA<PasswordChangeRequiredException>()));
    await pumpEventQueue();

    expect(rejections, isEmpty);
  });

  test('refused credentials at sign-in are not a session ending', () async {
    respond(401);

    await expectLater(
      apiClient.createSession(
        const SessionLoginCredential(type: AppType.android, identifier: 'id', login: 'l', password: 'p'),
      ),
      throwsA(isA<IncorrectCredentialsException>()),
    );
    await pumpEventQueue();

    expect(rejections, isEmpty);
  });

  test('a client nobody listens to still throws', () async {
    final quiet = WebtritApiClient.inner(Uri.parse('https://example.com'), 'tenant-id', httpClient: httpClient);
    addTearDown(quiet.close);
    respond(401, 'session_missing');

    await expectLater(quiet.getAppStatus(token), throwsA(isA<SessionMissingException>()));
  });

  test('closing the client ends the stream', () async {
    final quiet = WebtritApiClient.inner(Uri.parse('https://example.com'), 'tenant-id', httpClient: httpClient);
    final done = expectLater(quiet.sessionRejections, emitsDone);

    quiet.close();

    await done;
  });
}
