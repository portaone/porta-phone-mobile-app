import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:api/api.dart';

// A failure becomes a named exception through rules: the ones true of every
// call, and the ones an endpoint declares for itself. These pin which is which,
// because the whole point of the split is that a rule about one endpoint never
// fires on the others.
void main() {
  const authority = 'demo.webtrit.com';
  const token = 'token_1';

  WebtritApiClient clientAnswering(int status, Map<String, dynamic>? body) {
    return WebtritApiClient.inner(
      Uri.https(authority),
      '',
      httpClient: MockClient(
        (request) async => Response(
          body == null ? '' : jsonEncode(body),
          status,
          request: request,
          headers: const {'content-type': 'application/json'},
        ),
      ),
    );
  }

  group('rules that hold for every call', () {
    test('a missing session is named wherever it happens', () async {
      final apiClient = clientAnswering(401, {'code': 'session_missing'});

      await expectLater(apiClient.getUserVoicemailList(token), throwsA(isA<SessionMissingException>()));
    });

    test('an invalidated token is named on an unrelated endpoint too', () async {
      final apiClient = clientAnswering(401, {'code': 'token_invalid'});

      await expectLater(apiClient.getUserContactList(token), throwsA(isA<UnauthorizedException>()));
    });

    test('an expired password is named whatever the status', () async {
      final apiClient = clientAnswering(403, {'code': 'password_change_required'});

      await expectLater(apiClient.getUserContactList(token), throwsA(isA<PasswordChangeRequiredException>()));
    });

    test('an unrecognised failure stays a plain RequestFailure', () async {
      // A 4xx nobody claims: the backend answered about this request and no
      // rule has anything to add. A 5xx is not this case any more - the
      // backend blamed itself, which is a name of its own.
      final apiClient = clientAnswering(409, {'code': 'something_else'});

      await expectLater(
        apiClient.getUserContactList(token),
        throwsA(
          allOf(isA<RequestFailure>(), isNot(isA<UnauthorizedException>()), isNot(isA<ServerFailureException>())),
        ),
      );
    });
  });

  group('rules an endpoint declares for itself', () {
    test('voicemail reports its own switched-off state', () async {
      final apiClient = clientAnswering(422, {'code': 'voicemail_not_configured'});

      await expectLater(apiClient.getUserVoicemailList(token), throwsA(isA<VoicemailNotConfiguredException>()));
    });

    test('the same code from another endpoint is NOT read as that', () async {
      // The rule belongs to the mailbox calls. Read globally it would rename a
      // failure of any endpoint that happened to answer with the same word.
      final apiClient = clientAnswering(422, {'code': 'voicemail_not_configured'});

      await expectLater(
        apiClient.getUserContactList(token),
        throwsA(allOf(isA<RequestFailure>(), isNot(isA<VoicemailNotConfiguredException>()))),
      );
    });

    test('a bare 404 means the account on the endpoints that say so', () async {
      final apiClient = clientAnswering(404, null);

      await expectLater(apiClient.getUserInfo(token), throwsA(isA<UserNotFoundException>()));
    });

    test('a bare 404 elsewhere is an ordinary failure', () async {
      final apiClient = clientAnswering(404, null);

      await expectLater(
        apiClient.getUserContactList(token),
        throwsA(allOf(isA<RequestFailure>(), isNot(isA<UserNotFoundException>()))),
      );
    });

    test('creating a session reads a 401 as refused credentials', () async {
      // The shape the PortaSwitch adapter actually answers with: a message and
      // a reason, and no code for a rule to key on.
      final apiClient = clientAnswering(401, {
        'message': 'User authentication error',
        'details': {'path': null, 'reason': 'User authentication error'},
      });

      await expectLater(
        apiClient.createSession(
          SessionLoginCredential(type: AppType.android, identifier: 'identifier', login: 'login', password: 'password'),
        ),
        throwsA(isA<IncorrectCredentialsException>()),
      );
    });

    test('a 401 elsewhere is about the session, not the credentials', () async {
      final apiClient = clientAnswering(401, {'code': 'token_invalid'});

      await expectLater(
        apiClient.getUserContactList(token),
        throwsA(allOf(isA<UnauthorizedException>(), isNot(isA<IncorrectCredentialsException>()))),
      );
    });

    test('an optional endpoint still reads a bare 404 as absent', () async {
      final apiClient = clientAnswering(404, null);

      await expectLater(apiClient.getUserVoicemailList(token), throwsA(isA<EndpointNotSupportedException>()));
    });
  });

  group('an error body in a shape of its own', () {
    // Two shapes are in the wild, and neither may cost the caller the status
    // code: the whole point of reading the body is to say more about a failure,
    // never to turn one into something else.
    test('Core lists what it refused, and the first of them is read', () async {
      final apiClient = clientAnswering(422, {
        'code': 'parameters_validate_issue',
        'details': [
          {'reason': 'unexpected_field', 'path': 'trash'},
        ],
      });

      await expectLater(
        apiClient.deleteUserVoicemail(token, 'vm-1'),
        throwsA(
          isA<RequestFailure>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.errorCode, 'errorCode', 'parameters_validate_issue')
              .having((e) => e.error?.details?.path, 'details.path', 'trash')
              .having((e) => e.error?.details?.reason, 'details.reason', 'unexpected_field'),
        ),
      );
    });

    test('an adaptee sends one detail rather than a list, and it reads the same', () async {
      final apiClient = clientAnswering(422, {
        'code': 'validation_error',
        'details': {'reason': 'too_long', 'path': 'name'},
      });

      await expectLater(
        apiClient.getUserContactList(token),
        throwsA(isA<RequestFailure>().having((e) => e.error?.details?.reason, 'details.reason', 'too_long')),
      );
    });

    test('a shape nobody expected still answers with the status it came with', () async {
      // This used to throw a cast error out of the parse, so the caller was
      // handed a TypeError and never learned there had been a 422 at all.
      final apiClient = clientAnswering(422, {'code': 'odd', 'details': 42});

      await expectLater(
        apiClient.deleteUserVoicemail(token, 'vm-1'),
        throwsA(isA<RequestFailure>().having((e) => e.statusCode, 'statusCode', 422)),
      );
    });
  });

  group('a backend that failed on its own side', () {
    test('is named rather than left as a bare failure', () async {
      final apiClient = clientAnswering(500, {'code': 'external_api_issue'});

      await expectLater(
        apiClient.deleteUserVoicemail(token, 'vm-1'),
        throwsA(isA<ServerFailureException>().having((e) => e.statusCode, 'statusCode', 500)),
      );
    });

    test('whatever the shape of the 5xx', () async {
      final apiClient = clientAnswering(503, null);

      await expectLater(apiClient.deleteUserVoicemail(token, 'vm-1'), throwsA(isA<ServerFailureException>()));
    });

    test('while a 4xx still answers about the request itself', () async {
      // The distinction the name is for: this one is an answer about the
      // message, and a caller may act on it.
      final apiClient = clientAnswering(404, {'code': 'message_not_found'});

      await expectLater(
        apiClient.deleteUserVoicemail(token, 'vm-1'),
        throwsA(isA<RequestFailure>().having((e) => e is ServerFailureException, 'is a server failure', isFalse)),
      );
    });
  });
}
