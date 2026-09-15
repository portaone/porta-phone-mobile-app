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
      final apiClient = clientAnswering(500, {'code': 'something_else'});

      await expectLater(
        apiClient.getUserContactList(token),
        throwsA(allOf(isA<RequestFailure>(), isNot(isA<UnauthorizedException>()))),
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

    test('an optional endpoint still reads a bare 404 as absent', () async {
      final apiClient = clientAnswering(404, null);

      await expectLater(apiClient.getUserVoicemailList(token), throwsA(isA<EndpointNotSupportedException>()));
    });
  });
}
