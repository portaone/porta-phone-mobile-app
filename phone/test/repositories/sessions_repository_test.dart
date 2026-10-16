import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockWebtritApiClient extends Mock implements WebtritApiClient {}

void main() {
  const token = 'token_1';

  late _MockWebtritApiClient apiClient;
  late SessionsRepositoryApiImpl repository;

  setUp(() {
    apiClient = _MockWebtritApiClient();
    repository = SessionsRepositoryApiImpl(apiClient, token);
  });

  RequestFailure failure(int status, String? code) => RequestFailure(
    url: Uri.parse('https://core/api/v1/user/sessions/settings'),
    statusCode: status,
    requestId: 'r1',
    error: code == null ? null : ErrorResponse(code: code),
  );

  SessionAutoTerminateLimitExceededException limitExceeded() => SessionAutoTerminateLimitExceededException(
    url: Uri.parse('https://core/api/v1/user/sessions/settings'),
    statusCode: 422,
    requestId: 'r1',
    error: const ErrorResponse(code: 'exceeds_installation_limit'),
  );

  SessionAutoTerminateNotSupportedException notSupported() => SessionAutoTerminateNotSupportedException(
    url: Uri.parse('https://core/api/v1/user/sessions/settings'),
    statusCode: 501,
    requestId: 'r1',
    error: const ErrorResponse(code: 'functionality_not_implemented'),
  );

  void answer(Object error) {
    when(() => apiClient.updateUserSessionsSettings(token, inactivityTimeoutDays: any(named: 'inactivityTimeoutDays')))
        .thenThrow(error);
  }

  group('setInactivityTimeout', () {
    test('answers with what the core now holds', () async {
      when(() => apiClient.updateUserSessionsSettings(token, inactivityTimeoutDays: 7))
          .thenAnswer((_) async => const UserSessionsAutoTerminate(inactivityTimeoutDays: 7, installationMaxDays: 90));

      expect(
        await repository.setInactivityTimeout(7),
        const SessionAutoTerminate(inactivityTimeoutDays: 7, installationMaxDays: 90),
      );
    });

    for (final (error, reason) in [
      (limitExceeded(), SessionAutoTerminateRefusal.exceedsInstallationLimit),
      (notSupported(), SessionAutoTerminateRefusal.notSupported),
    ]) {
      test('${error.runtimeType} is the refusal $reason', () async {
        answer(error);

        await expectLater(
          repository.setInactivityTimeout(120),
          throwsA(isA<SessionAutoTerminateRefusedException>().having((e) => e.reason, 'reason', reason)),
        );
      });
    }

    for (final (status, code) in [(422, 'validation_error'), (501, null), (503, 'external_api_issue')]) {
      test('$status $code is no refusal of the period and comes as it was', () async {
        final error = failure(status, code);
        answer(error);

        await expectLater(repository.setInactivityTimeout(120), throwsA(same(error)));
      });
    }
  });
}
