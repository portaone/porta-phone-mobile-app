import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:api/api.dart' hide CoreInfo, PostgresInfo;

import 'package:webtrit_phone/app/notifications/notifications.dart';
import 'package:webtrit_phone/common/logging/anonymizing_formatter.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/login/login.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAppInfo extends Mock implements AppInfo {}

class _MockPackageInfo extends Mock implements PackageInfo {}

const _coreUrl = 'https://core.example.com';
const _tenantId = 'tenant-1';
const _pendingLoginToken = 'pending-login-token';

final _url = Uri.parse('$_coreUrl/api/v1/session');

LoginDeviceLimitReached _deviceLimitReached({
  List<String> sessions = const ['session-1', 'session-2'],
  String token = _pendingLoginToken,
  String tenantId = _tenantId,
}) {
  return LoginDeviceLimitReached(
    pendingLogin: PendingLogin(
      token: token,
      tenantId: tenantId,
      sessions: [for (final id in sessions) ActiveSession(id: id, current: false)],
    ),
  );
}

DeviceSwitchLimitReachedException _deviceSwitchLimitReached() {
  return DeviceSwitchLimitReachedException(
    url: _url,
    requestId: 'test-request-id',
    statusCode: 403,
    error: const ErrorResponse(code: 'device_switch_limit_reached'),
  );
}

// A login is refused for the device limit after its credentials were accepted,
// so it can be finished by signing another device out. These follow that login
// through the cubit: how each sign-in leaves it waiting, every answer to
// finishing it, and what the user is told when nothing here can be done.
void main() {
  late _MockAuthRepository authRepository;
  late NotificationsBloc notificationsBloc;
  late List<Session> loggedIn;

  setUpAll(() {
    registerFallbackValue(const SessionOtpProvisional(otpId: 'fallback'));
    registerFallbackValue(const RawHttpRequest(method: 'GET', url: 'https://example.com'));
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    notificationsBloc = NotificationsBloc();
    loggedIn = [];
  });

  tearDown(() => notificationsBloc.close());

  LoginCubit buildCubit() {
    final appInfo = _MockAppInfo();
    when(() => appInfo.version).thenReturn(Version.parse('1.0.0'));
    final packageInfo = _MockPackageInfo();
    when(() => packageInfo.version).thenReturn('0.0.0');
    when(() => packageInfo.buildNumber).thenReturn('0');

    final cubit = LoginCubit(
      authRepository: authRepository,
      notificationsBloc: notificationsBloc,
      appInfo: appInfo,
      packageInfo: packageInfo,
      appCompatibilityResolver: const DefaultAppCompatibilityResolver(),
      onLoginSuccess: (session, _) => loggedIn.add(session),
    );
    addTearDown(cubit.close);

    // Where the sign-in screens leave the state: the backend is chosen and read.
    cubit.emit(
      cubit.state.copyWith(
        coreUrl: _coreUrl,
        tenantId: _tenantId,
        systemInfo: WebtritSystemInfo(
          core: CoreInfo(version: Version(1, 0, 0)),
          postgres: PostgresInfo(version: '15.0'),
        ),
      ),
    );
    return cubit;
  }

  void whenLoginAnswers(Object error) {
    when(
      () => authRepository.login(
        coreUrl: any(named: 'coreUrl'),
        tenantId: any(named: 'tenantId'),
        userRef: any(named: 'userRef'),
        password: any(named: 'password'),
      ),
    ).thenThrow(error);
  }

  When<Future<SessionToken>> whenCompleting() {
    return when(
      () => authRepository.completeLogin(
        coreUrl: any(named: 'coreUrl'),
        tenantId: any(named: 'tenantId'),
        pendingLoginToken: any(named: 'pendingLoginToken'),
        revokeSessionId: any(named: 'revokeSessionId'),
      ),
    );
  }

  Future<LoginCubit> cubitWithPendingLogin({List<String> sessions = const ['session-1', 'session-2']}) async {
    final cubit = buildCubit();
    cubit.handleError(_deviceLimitReached(sessions: sessions), StackTrace.current, 'test');
    await pumpEventQueue();
    return cubit;
  }

  Notification? lastNotification() => notificationsBloc.state.lastNotification;

  group('a sign-in refused for the device limit', () {
    test('by password leaves the login waiting with the devices to pick from', () async {
      final cubit = buildCubit();
      whenLoginAnswers(_deviceLimitReached());

      await cubit.loginQrSigninSubmitted(userRef: 'user', password: 'secret');
      await pumpEventQueue();

      final pendingLogin = cubit.state.pendingLogin;
      expect(pendingLogin, isNotNull);
      expect(pendingLogin!.token, _pendingLoginToken);
      expect(pendingLogin.tenantId, _tenantId);
      expect(pendingLogin.sessions.map((s) => s.id), ['session-1', 'session-2']);
      expect(cubit.state.processing, isFalse);
      expect(lastNotification(), isNull);
      expect(loggedIn, isEmpty);
    });

    test('by a one-time code leaves the login waiting and the code screen behind', () async {
      final cubit = buildCubit();
      cubit.emit(
        cubit.state.copyWith(
          otpSigninSessionOtpProvisionalWithDateTime: (const SessionOtpProvisional(otpId: 'otp-1'), DateTime(2026)),
          otpSigninCodeInput: const CodeInput.dirty('123456'),
        ),
      );
      when(
        () => authRepository.verifyOtp(
          coreUrl: any(named: 'coreUrl'),
          tenantId: any(named: 'tenantId'),
          sessionOtpProvisional: any(named: 'sessionOtpProvisional'),
          code: any(named: 'code'),
        ),
      ).thenThrow(_deviceLimitReached());

      cubit.loginOptSigninVerifySubmitted();
      await pumpEventQueue();

      expect(cubit.state.pendingLogin?.token, _pendingLoginToken);
      expect(cubit.state.processing, isFalse);
      // The code was accepted before the limit was checked, so it is spent.
      expect(cubit.state.otpSigninSessionOtpProvisionalWithDateTime, isNull);
      expect(cubit.state.otpSigninCodeInput, const CodeInput.pure());
    });

    test('by password leaves a one-time code that is still waiting alone', () async {
      final cubit = buildCubit();
      final waitingCode = (const SessionOtpProvisional(otpId: 'otp-1'), DateTime(2026));
      cubit.emit(
        cubit.state.copyWith(
          otpSigninSessionOtpProvisionalWithDateTime: waitingCode,
          signupSessionOtpProvisionalWithDateTime: waitingCode,
        ),
      );
      whenLoginAnswers(_deviceLimitReached());

      await cubit.loginQrSigninSubmitted(userRef: 'user', password: 'secret');
      await pumpEventQueue();
      cubit.loginDeviceLimitBack();

      expect(cubit.state.pendingLogin, isNull);
      expect(cubit.state.otpSigninSessionOtpProvisionalWithDateTime, waitingCode);
      expect(cubit.state.signupSessionOtpProvisionalWithDateTime, waitingCode);
    });

    test('by signing up leaves the login waiting', () async {
      final cubit = buildCubit();
      cubit.signupEmailInputChanged('user@example.com');
      when(
        () => authRepository.signup(
          coreUrl: any(named: 'coreUrl'),
          tenantId: any(named: 'tenantId'),
          email: any(named: 'email'),
        ),
      ).thenThrow(_deviceLimitReached());

      cubit.loginSignupRequestSubmitted();
      await pumpEventQueue();

      expect(cubit.state.pendingLogin?.token, _pendingLoginToken);
      expect(cubit.state.processing, isFalse);
    });

    test('from an embedded page waits in the tenant the repository names and raises no error dialog', () async {
      final cubit = buildCubit();
      when(
        () => authRepository.signup(
          coreUrl: any(named: 'coreUrl'),
          tenantId: any(named: 'tenantId'),
          extraPayload: any(named: 'extraPayload'),
        ),
      ).thenThrow(_deviceLimitReached(tenantId: 'embedded-tenant'));

      await cubit.loginCustomSignupRequest({'tenant_id': 'embedded-tenant'}, null);
      await pumpEventQueue();

      expect(cubit.state.pendingLogin?.tenantId, 'embedded-tenant');
      expect(cubit.state.embeddedRequestError, isNull);
      expect(cubit.state.processing, isFalse);
    });

    test('from an embedded page with nothing to sign out is told by the message, not by the error dialog', () async {
      final cubit = buildCubit();
      when(
        () => authRepository.signup(
          coreUrl: any(named: 'coreUrl'),
          tenantId: any(named: 'tenantId'),
          extraPayload: any(named: 'extraPayload'),
        ),
      ).thenThrow(const LoginDeviceLimitReached());

      await cubit.loginCustomSignupRequest(null, null);
      await pumpEventQueue();

      expect(cubit.state.embeddedRequestError, isNull);
      expect(lastNotification(), isA<LoginDeviceLimitReachedNotification>());
    });

    test('is not reported as an unexpected error', () async {
      final cubit = buildCubit();

      cubit.handleError(_deviceLimitReached(), StackTrace.current, 'test');
      await pumpEventQueue();

      expect(lastNotification(), isNot(isA<LoginUnexpectedErrorNotification>()));
    });

    test('with nothing of this account to sign out says so and leaves nothing waiting', () async {
      final cubit = buildCubit();

      cubit.handleError(const LoginDeviceLimitReached(), StackTrace.current, 'test');
      await pumpEventQueue();

      expect(cubit.state.pendingLogin, isNull);
      expect(lastNotification(), isA<LoginDeviceLimitReachedNotification>());
    });

    test('does not let a code still in front of the camera start another sign-in', () async {
      final cubit = await cubitWithPendingLogin();

      await cubit.loginQrSigninSubmitted(userRef: 'user', password: 'secret');

      verifyNever(
        () => authRepository.login(
          coreUrl: any(named: 'coreUrl'),
          tenantId: any(named: 'tenantId'),
          userRef: any(named: 'userRef'),
          password: any(named: 'password'),
        ),
      );
    });
  });

  group('a sign-in refused for the device switch limit', () {
    test('says so and leaves nothing waiting', () async {
      final cubit = buildCubit();
      whenLoginAnswers(_deviceSwitchLimitReached());

      await cubit.loginQrSigninSubmitted(userRef: 'user', password: 'secret');
      await pumpEventQueue();

      expect(cubit.state.pendingLogin, isNull);
      expect(cubit.state.processing, isFalse);
      expect(lastNotification(), isA<LoginDeviceSwitchLimitReachedNotification>());
    });

    test('sends a one-time code sign-in back to where a code is asked for', () async {
      final cubit = buildCubit();
      cubit.emit(
        cubit.state.copyWith(
          otpSigninSessionOtpProvisionalWithDateTime: (const SessionOtpProvisional(otpId: 'otp-1'), DateTime(2026)),
          otpSigninCodeInput: const CodeInput.dirty('123456'),
        ),
      );
      when(
        () => authRepository.verifyOtp(
          coreUrl: any(named: 'coreUrl'),
          tenantId: any(named: 'tenantId'),
          sessionOtpProvisional: any(named: 'sessionOtpProvisional'),
          code: any(named: 'code'),
        ),
      ).thenThrow(_deviceSwitchLimitReached());

      cubit.loginOptSigninVerifySubmitted();
      await pumpEventQueue();

      // The code was accepted before the limit was checked, so it is spent.
      expect(cubit.state.otpSigninSessionOtpProvisionalWithDateTime, isNull);
      expect(cubit.state.otpSigninCodeInput, const CodeInput.pure());
      expect(lastNotification(), isA<LoginDeviceSwitchLimitReachedNotification>());
    });

    test('from an embedded page is told by the message, not by the page\'s error dialog', () async {
      final cubit = buildCubit();
      when(
        () => authRepository.signup(
          coreUrl: any(named: 'coreUrl'),
          tenantId: any(named: 'tenantId'),
          extraPayload: any(named: 'extraPayload'),
        ),
      ).thenThrow(_deviceSwitchLimitReached());

      await cubit.loginCustomSignupRequest(null, null);
      await pumpEventQueue();

      expect(cubit.state.embeddedRequestError, isNull);
      expect(lastNotification(), isA<LoginDeviceSwitchLimitReachedNotification>());
    });
  });

  group('picking a device to sign out', () {
    test('finishes the login with the token, in the tenant it waits in', () async {
      final cubit = await cubitWithPendingLogin();
      whenCompleting().thenAnswer((_) async => const SessionToken(token: 'token-1', userId: 'user-1'));

      await cubit.loginDeviceLimitSessionPicked('session-2');
      await pumpEventQueue();

      verify(
        () => authRepository.completeLogin(
          coreUrl: _coreUrl,
          tenantId: _tenantId,
          pendingLoginToken: _pendingLoginToken,
          revokeSessionId: 'session-2',
        ),
      ).called(1);
      expect(
        loggedIn.single,
        const Session(coreUrl: _coreUrl, tenantId: _tenantId, token: 'token-1', userId: 'user-1'),
      );
    });

    test('finishes it in the tenant the login waits in, not the one in the state', () async {
      final cubit = buildCubit();
      cubit.handleError(_deviceLimitReached(tenantId: 'embedded-tenant'), StackTrace.current, 'test');
      whenCompleting().thenAnswer((_) async => const SessionToken(token: 'token-1'));

      await cubit.loginDeviceLimitSessionPicked('session-1');
      await pumpEventQueue();

      verify(
        () => authRepository.completeLogin(
          coreUrl: _coreUrl,
          tenantId: 'embedded-tenant',
          pendingLoginToken: _pendingLoginToken,
          revokeSessionId: 'session-1',
        ),
      ).called(1);
      expect(loggedIn.single.tenantId, 'embedded-tenant');
    });

    test('takes the tenant of the answer when it names one', () async {
      final cubit = await cubitWithPendingLogin();
      whenCompleting().thenAnswer((_) async => const SessionToken(token: 'token-1', tenantId: 'tenant-of-the-answer'));

      await cubit.loginDeviceLimitSessionPicked('session-1');
      await pumpEventQueue();

      expect(loggedIn.single.tenantId, 'tenant-of-the-answer');
      expect(loggedIn.single.userId, '');
    });

    test('marks the device while the request is out', () async {
      final cubit = await cubitWithPendingLogin();
      whenCompleting().thenAnswer((_) => Future.delayed(const Duration(milliseconds: 10), () => throw StateError('x')));

      final picking = cubit.loginDeviceLimitSessionPicked('session-2');

      expect(cubit.state.processing, isTrue);
      expect(cubit.state.pendingLoginRevokingSessionId, 'session-2');
      await picking;
    });

    test('ignores a second pick while the first is out', () async {
      final cubit = await cubitWithPendingLogin();
      whenCompleting().thenAnswer((_) async => const SessionToken(token: 'token-1'));

      final first = cubit.loginDeviceLimitSessionPicked('session-1');
      await cubit.loginDeviceLimitSessionPicked('session-2');
      await first;

      verify(
        () => authRepository.completeLogin(
          coreUrl: any(named: 'coreUrl'),
          tenantId: any(named: 'tenantId'),
          pendingLoginToken: any(named: 'pendingLoginToken'),
          revokeSessionId: 'session-1',
        ),
      ).called(1);
      verifyNever(
        () => authRepository.completeLogin(
          coreUrl: any(named: 'coreUrl'),
          tenantId: any(named: 'tenantId'),
          pendingLoginToken: any(named: 'pendingLoginToken'),
          revokeSessionId: 'session-2',
        ),
      );
    });

    test('does nothing when no login is waiting', () async {
      final cubit = buildCubit();

      await cubit.loginDeviceLimitSessionPicked('session-1');

      verifyNever(
        () => authRepository.completeLogin(
          coreUrl: any(named: 'coreUrl'),
          tenantId: any(named: 'tenantId'),
          pendingLoginToken: any(named: 'pendingLoginToken'),
          revokeSessionId: any(named: 'revokeSessionId'),
        ),
      );
    });

    test('still over the limit: shows the list as it is now and says so', () async {
      final cubit = await cubitWithPendingLogin();
      whenCompleting().thenThrow(_deviceLimitReached(sessions: ['session-2', 'session-3'], token: 'next-token'));

      await cubit.loginDeviceLimitSessionPicked('session-1');
      await pumpEventQueue();

      expect(cubit.state.pendingLogin!.sessions.map((s) => s.id), ['session-2', 'session-3']);
      expect(cubit.state.pendingLogin!.token, 'next-token');
      expect(cubit.state.processing, isFalse);
      expect(cubit.state.pendingLoginRevokingSessionId, isNull);
      expect(lastNotification(), isA<LoginDeviceLimitStillReachedNotification>());
    });

    test('a device already signed out leaves the list and the login keeps waiting', () async {
      final cubit = await cubitWithPendingLogin();
      whenCompleting().thenThrow(
        PendingLoginSessionNotFoundException(url: _url, requestId: 'test-request-id', statusCode: 404),
      );

      await cubit.loginDeviceLimitSessionPicked('session-1');
      await pumpEventQueue();

      expect(cubit.state.pendingLogin!.sessions.map((s) => s.id), ['session-2']);
      expect(cubit.state.pendingLogin!.token, _pendingLoginToken);
      expect(cubit.state.processing, isFalse);
      expect(lastNotification(), isA<LoginPendingLoginSessionNotFoundNotification>());
    });

    test('the last device already signed out sends the user to sign in again', () async {
      final cubit = await cubitWithPendingLogin(sessions: ['session-1']);
      whenCompleting().thenThrow(
        PendingLoginSessionNotFoundException(url: _url, requestId: 'test-request-id', statusCode: 404),
      );

      await cubit.loginDeviceLimitSessionPicked('session-1');
      await pumpEventQueue();

      expect(cubit.state.pendingLogin, isNull);
      expect(lastNotification(), isA<LoginPendingLoginNotFoundNotification>());
    });

    test('a login that ran out sends the user to sign in again', () async {
      final cubit = await cubitWithPendingLogin();
      whenCompleting().thenThrow(
        PendingLoginNotFoundException(url: _url, requestId: 'test-request-id', statusCode: 404),
      );

      await cubit.loginDeviceLimitSessionPicked('session-1');
      await pumpEventQueue();

      expect(cubit.state.pendingLogin, isNull);
      expect(cubit.state.processing, isFalse);
      expect(lastNotification(), isA<LoginPendingLoginNotFoundNotification>());
    });

    test('the switch limit met on the way ends the waiting', () async {
      final cubit = await cubitWithPendingLogin();
      whenCompleting().thenThrow(_deviceSwitchLimitReached());

      await cubit.loginDeviceLimitSessionPicked('session-1');
      await pumpEventQueue();

      expect(cubit.state.pendingLogin, isNull);
      expect(lastNotification(), isA<LoginDeviceSwitchLimitReachedNotification>());
    });

    test('a failure that says nothing about the login keeps it waiting for another try', () async {
      final cubit = await cubitWithPendingLogin();
      whenCompleting().thenThrow(ServerFailureException(url: _url, requestId: 'test-request-id', statusCode: 503));

      await cubit.loginDeviceLimitSessionPicked('session-1');
      await pumpEventQueue();

      expect(cubit.state.pendingLogin!.sessions.map((s) => s.id), ['session-1', 'session-2']);
      expect(cubit.state.processing, isFalse);
      expect(cubit.state.pendingLoginRevokingSessionId, isNull);
      expect(lastNotification(), isA<LoginUnexpectedErrorNotification>());
    });
  });

  group('leaving the device limit screen', () {
    test('drops the waiting login', () async {
      final cubit = await cubitWithPendingLogin();

      cubit.loginDeviceLimitBack();

      expect(cubit.state.pendingLogin, isNull);
      expect(cubit.state.pendingLoginRevokingSessionId, isNull);
      expect(cubit.state.processing, isFalse);
    });

    test('keeps the password form as it was typed', () async {
      final cubit = await cubitWithPendingLogin();
      cubit.passwordSigninUserRefInputChanged('user');

      cubit.loginDeviceLimitBack();

      expect(cubit.state.passwordSigninUserRefInput.value, 'user');
    });

    test('is not possible while a device is being signed out', () async {
      final cubit = await cubitWithPendingLogin();
      whenCompleting().thenAnswer(
        (_) => Future.delayed(const Duration(milliseconds: 10), () => const SessionToken(token: 'token-1')),
      );

      final picking = cubit.loginDeviceLimitSessionPicked('session-1');
      cubit.loginDeviceLimitBack();

      expect(cubit.state.pendingLogin, isNotNull);
      await picking;
      expect(loggedIn, hasLength(1));
    });
  });

  group('a login that waited on an embedded launch page', () {
    // The page signs up before the system info is read, so the steps that
    // follow a successful signup there have to be made after the wait too.
    Future<LoginCubit> cubitWaitingWithoutSystemInfo({Map<String, dynamic>? callbackData}) async {
      final cubit = buildCubit();
      cubit.emit(const LoginState(coreUrl: _coreUrl).copyWith(embeddedCallbackData: callbackData));
      cubit.handleError(_deviceLimitReached(), StackTrace.current, 'test');
      await pumpEventQueue();
      whenCompleting().thenAnswer((_) async => const SessionToken(token: 'token-1', userId: 'user-1'));
      when(() => authRepository.executePostLoginHttpRequest(any())).thenAnswer((_) async {});
      return cubit;
    }

    final systemInfo = WebtritSystemInfo(
      core: CoreInfo(version: Version(1, 0, 0)),
      postgres: PostgresInfo(version: '15.0'),
    );

    test('reads the system info before it signs in', () async {
      final cubit = await cubitWaitingWithoutSystemInfo();
      when(() => authRepository.getSystemInfo(_coreUrl, _tenantId)).thenAnswer((_) async => systemInfo);

      await cubit.loginDeviceLimitSessionPicked('session-1');
      await pumpEventQueue();

      expect(cubit.state.systemInfo, systemInfo);
      expect(
        loggedIn.single,
        const Session(coreUrl: _coreUrl, tenantId: _tenantId, token: 'token-1', userId: 'user-1'),
      );
    });

    test('makes the call the page asked for after a login', () async {
      final cubit = await cubitWaitingWithoutSystemInfo(
        callbackData: {'method': 'POST', 'url': 'https://example.com/hook'},
      );
      when(() => authRepository.getSystemInfo(_coreUrl, _tenantId)).thenAnswer((_) async => systemInfo);

      await cubit.loginDeviceLimitSessionPicked('session-1');
      await pumpEventQueue();

      verify(() => authRepository.executePostLoginHttpRequest(any(that: isNotNull))).called(1);
    });
  });

  test('the token of a waiting login is not printed with the state', () async {
    final cubit = await cubitWithPendingLogin();

    expect('${cubit.state}', isNot(contains(_pendingLoginToken)));
    expect('${cubit.state.pendingLogin}', isNot(contains(_pendingLoginToken)));
  });

  test('the token of a waiting login is taken out of the log', () {
    const line = 'response body: {"code":"device_limit_reached","pending_login_token":"$_pendingLoginToken"}';

    final formatted = AnonymizingFormatter(anonymizationType: AnonymizationType.full)
        .formatToStringBuffer(LogRecord(Level.INFO, line, 'test'), StringBuffer());

    expect('$formatted', isNot(contains(_pendingLoginToken)));
    expect('$formatted', contains('[REDACTED_PENDINGLOGINTOKEN]'));
  });
}
