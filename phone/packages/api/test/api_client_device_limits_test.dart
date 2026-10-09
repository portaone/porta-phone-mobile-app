import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:api/api.dart';

// The device limits of an account are met by the calls that end in a session,
// and only by them. One of the two refusals can be answered: it lists the
// sessions of the account and leaves the login waiting under a token, and
// revoking one of them finishes it. These pin what each call reads out of the
// refusal and that the same words mean nothing on the endpoints around them.
void main() {
  const authority = 'demo.webtrit.com';
  const token = 'token_1';
  const pendingLoginToken = 'pending-login-token';

  Map<String, dynamic> session(String id, {String userAgent = 'PortaPhone/1.17.0 (Pixel 9; Android: 17)'}) => {
    'id': id,
    'current': false,
    'status': 'active',
    'user_agent': userAgent,
    'location': 'UA',
    'app_type': 'android',
    'app_identifier': 'identifier-of-$id',
    'app_bundle_id': 'com.webtrit.phone',
    'created_at': '2026-10-01T10:00:00Z',
    'last_activity_at': '2026-10-08T18:30:00Z',
  };

  Map<String, dynamic> deviceLimitReached({List<Object?>? sessions, String? pendingLoginToken = pendingLoginToken}) => {
    'code': 'device_limit_reached',
    'sessions': sessions ?? [session('session-1'), session('session-2')],
    'pending_login_token': ?pendingLoginToken,
  };

  late List<Request> requests;

  WebtritApiClient clientAnswering(int status, Map<String, dynamic>? body) {
    requests = [];
    return WebtritApiClient.inner(
      Uri.https(authority),
      '',
      httpClient: MockClient((request) async {
        requests.add(request);
        return Response(
          body == null ? '' : jsonEncode(body),
          status,
          request: request,
          headers: const {'content-type': 'application/json'},
        );
      }),
    );
  }

  // Every call that ends in a session, by the name a failing test should show.
  final logins = <String, Future<Object?> Function(WebtritApiClient)>{
    'createSession': (client) => client.createSession(
      const SessionLoginCredential(type: AppType.android, identifier: 'device', login: 'user', password: 'secret'),
    ),
    'verifySessionOtp': (client) => client.verifySessionOtp(const SessionOtpProvisional(otpId: 'otp-1'), '123456'),
    'createSessionAutoProvision': (client) => client.createSessionAutoProvision(
      const SessionAutoProvisionCredential(type: AppType.android, identifier: 'device', configToken: 'config-token'),
    ),
    'createUser': (client) =>
        client.createUser(const SessionUserCredential(type: AppType.android, identifier: 'device')),
    'completeSession': (client) =>
        client.completeSession(pendingLoginToken: pendingLoginToken, revokeSessionId: 'session-1'),
  };

  group('a login refused for the device limit', () {
    for (final MapEntry(key: name, value: login) in logins.entries) {
      test('$name hands back the sessions and the token of the waiting login', () async {
        final apiClient = clientAnswering(409, deviceLimitReached());

        await expectLater(
          login(apiClient),
          throwsA(
            isA<DeviceLimitReachedException>()
                .having((e) => e.statusCode, 'statusCode', 409)
                .having((e) => e.errorCode, 'errorCode', 'device_limit_reached')
                .having((e) => e.sessions.map((s) => s.id), 'sessions', ['session-1', 'session-2'])
                .having((e) => e.pendingLoginToken, 'pendingLoginToken', pendingLoginToken)
                .having((e) => e.canBeCompleted, 'canBeCompleted', isTrue),
          ),
        );
      });
    }

    test('the sessions are read like the ones of the session list', () async {
      final apiClient = clientAnswering(409, deviceLimitReached(sessions: [session('session-1')]));

      late DeviceLimitReachedException refusal;
      try {
        await logins['createSession']!(apiClient);
      } on DeviceLimitReachedException catch (e) {
        refusal = e;
      }

      final listed = refusal.sessions.single;
      expect(listed.current, isFalse);
      expect(listed.status, UserSessionStatus.active);
      expect(listed.userAgent, 'PortaPhone/1.17.0 (Pixel 9; Android: 17)');
      expect(listed.location, 'UA');
      expect(listed.appType, AppType.android);
      expect(listed.appIdentifier, 'identifier-of-session-1');
      expect(listed.appBundleId, 'com.webtrit.phone');
      expect(listed.createdAt, DateTime.utc(2026, 10, 1, 10));
      expect(listed.lastActivityAt, DateTime.utc(2026, 10, 8, 18, 30));
    });

    test('without a token there is nothing to complete', () async {
      // The limit is taken by other accounts of the customer: no session of
      // this account to revoke, so the backend sends no token.
      final apiClient = clientAnswering(409, deviceLimitReached(sessions: [], pendingLoginToken: null));

      await expectLater(
        logins['createSession']!(apiClient),
        throwsA(
          isA<DeviceLimitReachedException>()
              .having((e) => e.sessions, 'sessions', isEmpty)
              .having((e) => e.pendingLoginToken, 'pendingLoginToken', isNull)
              .having((e) => e.canBeCompleted, 'canBeCompleted', isFalse),
        ),
      );
    });

    test('an empty token is no token', () async {
      final apiClient = clientAnswering(409, deviceLimitReached(pendingLoginToken: ''));

      await expectLater(
        logins['createSession']!(apiClient),
        throwsA(isA<DeviceLimitReachedException>().having((e) => e.canBeCompleted, 'canBeCompleted', isFalse)),
      );
    });

    test('a session it cannot read is left out and the rest are kept', () async {
      final apiClient = clientAnswering(
        409,
        deviceLimitReached(
          sessions: [
            session('session-1'),
            {'user_agent': 'no id, no status'},
            'not an object',
            null,
            session('session-2'),
          ],
        ),
      );

      await expectLater(
        logins['createSession']!(apiClient),
        throwsA(
          isA<DeviceLimitReachedException>()
              .having((e) => e.sessions.map((s) => s.id), 'sessions', ['session-1', 'session-2'])
              .having((e) => e.pendingLoginToken, 'pendingLoginToken', pendingLoginToken),
        ),
      );
    });

    test('a field added to a session later does not hide the session', () async {
      final apiClient = clientAnswering(
        409,
        deviceLimitReached(
          sessions: [
            {...session('session-1'), 'device_name': 'Pixel 9', 'status': 'a status of the future'},
          ],
        ),
      );

      await expectLater(
        logins['createSession']!(apiClient),
        throwsA(
          isA<DeviceLimitReachedException>()
              .having((e) => e.sessions.single.id, 'session', 'session-1')
              .having((e) => e.sessions.single.status, 'status', UserSessionStatus.unknown),
        ),
      );
    });

    test('a session of an app type this build does not know is still listed', () async {
      final apiClient = clientAnswering(
        409,
        deviceLimitReached(
          sessions: [
            {...session('session-1'), 'app_type': 'a_type_of_the_future'},
          ],
        ),
      );

      await expectLater(
        logins['createSession']!(apiClient),
        throwsA(
          isA<DeviceLimitReachedException>()
              .having((e) => e.sessions.single.id, 'session', 'session-1')
              .having((e) => e.sessions.single.appType, 'appType', isNull)
              .having((e) => e.canBeCompleted, 'canBeCompleted', isTrue),
        ),
      );
    });

    test('sessions in a shape it does not know leave an empty list, not a parse error', () async {
      final apiClient = clientAnswering(409, {
        'code': 'device_limit_reached',
        'sessions': {'items': []},
        'pending_login_token': pendingLoginToken,
      });

      await expectLater(
        logins['createSession']!(apiClient),
        throwsA(
          isA<DeviceLimitReachedException>()
              .having((e) => e.sessions, 'sessions', isEmpty)
              .having((e) => e.canBeCompleted, 'canBeCompleted', isTrue),
        ),
      );
    });

    test('the token is not printed with the refusal', () async {
      final apiClient = clientAnswering(409, deviceLimitReached());

      await expectLater(
        logins['createSession']!(apiClient),
        throwsA(isA<DeviceLimitReachedException>().having((e) => '$e', 'toString', isNot(contains(pendingLoginToken)))),
      );
    });
  });

  group('a login refused for the device switch limit', () {
    for (final MapEntry(key: name, value: login) in logins.entries) {
      test('$name names it', () async {
        final apiClient = clientAnswering(403, {'code': 'device_switch_limit_reached'});

        await expectLater(
          login(apiClient),
          throwsA(
            isA<DeviceSwitchLimitReachedException>()
                .having((e) => e.statusCode, 'statusCode', 403)
                .having((e) => e.errorCode, 'errorCode', 'device_switch_limit_reached'),
          ),
        );
      });
    }
  });

  group('completing a waiting login', () {
    test('posts the token and the session to revoke, with no session of its own', () async {
      final apiClient = clientAnswering(200, {'token': token, 'user_id': 'user-1', 'tenant_id': 'tenant-1'});

      final result = await apiClient.completeSession(
        pendingLoginToken: pendingLoginToken,
        revokeSessionId: 'session-1',
      );

      final request = requests.single;
      expect(request.method.toUpperCase(), 'POST');
      expect(request.url.path, '/api/v1/session/complete');
      expect(request.headers.containsKey('authorization'), isFalse);
      expect(jsonDecode(request.body), {'pending_login_token': pendingLoginToken, 'revoke_session_id': 'session-1'});

      expect(result.token, token);
      expect(result.userId, 'user-1');
      expect(result.tenantId, 'tenant-1');
    });

    test('a token that ran out or was used means the login starts over', () async {
      final apiClient = clientAnswering(404, {'code': 'pending_login_not_found'});

      await expectLater(logins['completeSession']!(apiClient), throwsA(isA<PendingLoginNotFoundException>()));
    });

    test('a session that is already gone is told apart from a login that is', () async {
      final apiClient = clientAnswering(404, {'code': 'session_not_found'});

      await expectLater(
        logins['completeSession']!(apiClient),
        throwsA(allOf(isA<PendingLoginSessionNotFoundException>(), isNot(isA<PendingLoginNotFoundException>()))),
      );
    });

    test('a refusal is not retried', () async {
      final apiClient = clientAnswering(404, {'code': 'pending_login_not_found'});

      await expectLater(logins['completeSession']!(apiClient), throwsA(isA<PendingLoginNotFoundException>()));
      expect(requests, hasLength(1));
    });
  });

  group('the same words on other endpoints', () {
    test('a 409 with the code is an ordinary failure where no session is created', () async {
      final apiClient = clientAnswering(409, deviceLimitReached());

      await expectLater(
        apiClient.getUserContactList(token),
        throwsA(allOf(isA<RequestFailure>(), isNot(isA<DeviceLimitReachedException>()))),
      );
    });

    test('a 403 with the code is an ordinary failure where no session is created', () async {
      final apiClient = clientAnswering(403, {'code': 'device_switch_limit_reached'});

      await expectLater(
        apiClient.getUserContactList(token),
        throwsA(allOf(isA<RequestFailure>(), isNot(isA<DeviceSwitchLimitReachedException>()))),
      );
    });

    test('session_not_found from the session list is not about a waiting login', () async {
      final apiClient = clientAnswering(404, {'code': 'session_not_found'});

      await expectLater(
        apiClient.getUserSessions(token),
        throwsA(allOf(isA<RequestFailure>(), isNot(isA<PendingLoginSessionNotFoundException>()))),
      );
    });

    test('pending_login_not_found means nothing to a login that is not being completed', () async {
      final apiClient = clientAnswering(404, {'code': 'pending_login_not_found'});

      await expectLater(
        logins['verifySessionOtp']!(apiClient),
        throwsA(allOf(isA<RequestFailure>(), isNot(isA<PendingLoginNotFoundException>()))),
      );
    });

    test('the codes are read with their statuses', () async {
      // The same code under another status is not this refusal: nothing says
      // what such an answer carries.
      final apiClient = clientAnswering(422, deviceLimitReached());

      await expectLater(
        logins['createSession']!(apiClient),
        throwsA(allOf(isA<RequestFailure>(), isNot(isA<DeviceLimitReachedException>()))),
      );
    });

    test('wrong credentials are still named on createSession', () async {
      final apiClient = clientAnswering(401, {'code': 'incorrect_credentials'});

      await expectLater(logins['createSession']!(apiClient), throwsA(isA<IncorrectCredentialsException>()));
    });
  });
}
