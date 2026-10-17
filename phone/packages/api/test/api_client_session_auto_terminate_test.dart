import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:api/api.dart';

// When idle sessions end: read with the session list, written with
// PUT /user/sessions/settings. The shapes are Core's `SessionSchema.AutoTerminate`.
void main() {
  const authority = 'demo.webtrit.com';
  const token = 'token_1';

  WebtritApiClient clientAnswering(int status, Object body, {void Function(Request request)? onRequest}) {
    Future<Response> handler(Request request) async {
      onRequest?.call(request);
      return Response(jsonEncode(body), status, request: request, headers: const {'content-type': 'application/json'});
    }

    return WebtritApiClient.inner(Uri.https(authority), '', httpClient: MockClient(handler));
  }

  group('getUserSessionList', () {
    test('reads auto_terminate next to the sessions', () async {
      final apiClient = clientAnswering(200, {
        'items': [
          {'id': 's1', 'current': true, 'status': 'active'},
        ],
        'auto_terminate': {'inactivity_timeout_days': 30, 'installation_max_days': 90},
      });

      final list = await apiClient.getUserSessionList(token);

      expect(list.items.map((s) => s.id), ['s1']);
      expect(list.autoTerminate, const UserSessionsAutoTerminate(inactivityTimeoutDays: 30, installationMaxDays: 90));
    });

    test('keeps both nulls: sessions that never end on an installation with no limit', () async {
      final apiClient = clientAnswering(200, {
        'items': <Object>[],
        'auto_terminate': {'inactivity_timeout_days': null, 'installation_max_days': null},
      });

      final list = await apiClient.getUserSessionList(token);

      expect(list.autoTerminate, const UserSessionsAutoTerminate());
    });

    test('a core without idle-session cleanup sends no auto_terminate, and the list still loads', () async {
      final apiClient = clientAnswering(200, {
        'items': [
          {'id': 's1', 'current': true, 'status': 'active'},
        ],
      });

      final list = await apiClient.getUserSessionList(token);

      expect(list.items, hasLength(1));
      expect(list.autoTerminate, isNull);
    });

    test('getUserSessions still answers with the sessions alone', () async {
      final apiClient = clientAnswering(200, {
        'items': [
          {'id': 's1', 'current': true, 'status': 'active'},
        ],
        'auto_terminate': {'inactivity_timeout_days': 7, 'installation_max_days': 90},
      });

      expect(await apiClient.getUserSessions(token), [
        const UserSession(id: 's1', current: true, status: UserSessionStatus.active),
      ]);
    });
  });

  group('updateUserSessionsSettings', () {
    test('puts the number of days and reads back what the core holds', () async {
      late Request captured;
      final apiClient = clientAnswering(200, {
        'inactivity_timeout_days': 7,
        'installation_max_days': 90,
      }, onRequest: (request) => captured = request);

      final result = await apiClient.updateUserSessionsSettings(token, inactivityTimeoutDays: 7);

      expect(captured.method, equalsIgnoringCase('put'));
      expect(captured.url.toString(), 'https://$authority/api/v1/user/sessions/settings');
      expect(captured.headers['authorization'], 'Bearer $token');
      expect(jsonDecode(captured.body), {'inactivity_timeout_days': 7});
      expect(result, const UserSessionsAutoTerminate(inactivityTimeoutDays: 7, installationMaxDays: 90));
    });

    test('null travels as an explicit null: the way back to the installation timeout', () async {
      late Request captured;
      final apiClient = clientAnswering(200, {
        'inactivity_timeout_days': 90,
        'installation_max_days': 90,
      }, onRequest: (request) => captured = request);

      await apiClient.updateUserSessionsSettings(token, inactivityTimeoutDays: null);

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body.containsKey('inactivity_timeout_days'), isTrue);
      expect(body['inactivity_timeout_days'], isNull);
    });

    for (final (status, code, exception) in [
      (422, 'exceeds_installation_limit', SessionAutoTerminateLimitExceededException),
      (501, 'functionality_not_implemented', SessionAutoTerminateNotSupportedException),
    ]) {
      test('$status $code has its endpoint-specific exception', () async {
        final apiClient = clientAnswering(status, {'code': code});

        await expectLater(
          apiClient.updateUserSessionsSettings(token, inactivityTimeoutDays: 120),
          throwsA(
            isA<RequestFailure>()
                .having((f) => f.runtimeType, 'runtimeType', exception)
                .having((f) => f.statusCode, 'statusCode', status)
                .having((f) => f.errorCode, 'errorCode', code),
          ),
        );
      });
    }

    for (final (status, code, exception) in [
      (422, 'validation_error', RequestFailure),
      (422, null, RequestFailure),
      (501, null, ServerFailureException),
      (501, 'exceeds_installation_limit', ServerFailureException),
      (503, 'external_api_issue', ServerFailureException),
    ]) {
      test('$status $code is not mistaken for an idle-period refusal', () async {
        final apiClient = clientAnswering(status, {'code': code});

        await expectLater(
          apiClient.updateUserSessionsSettings(token, inactivityTimeoutDays: 120),
          throwsA(
            isA<RequestFailure>()
                .having((f) => f.runtimeType, 'runtimeType', exception)
                .having((f) => f.statusCode, 'statusCode', status)
                .having((f) => f.errorCode, 'errorCode', code),
          ),
        );
      });
    }
  });
}
