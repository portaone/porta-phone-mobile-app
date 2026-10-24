import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:api/api.dart' hide CoreInfo, PostgresInfo;

import 'package:webtrit_phone/app/notifications/notifications.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/login/login.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAppInfo extends Mock implements AppInfo {}

class _MockPackageInfo extends Mock implements PackageInfo {}

class _UnsupportedCore implements AppCompatibilityResolver {
  @override
  AppCompatibility resolve({
    required WebtritSystemInfo systemInfo,
    required Version appVersion,
    required String coreVersionConstraint,
  }) {
    return CoreVersionUnsupported(coreVersion: systemInfo.core.version, constraint: VersionConstraint.parse('>=9.0.0'));
  }
}

const _coreUrl = 'https://core.example.com';
const _tenantId = 'tenant-1';

final _systemInfo = WebtritSystemInfo(
  core: CoreInfo(version: Version(1, 0, 0)),
  postgres: PostgresInfo(version: '15.0'),
);

LoginDeviceLimitReached _deviceLimitReached() {
  return LoginDeviceLimitReached(
    pendingLogin: PendingLogin(
      token: 'pending-login-token',
      tenantId: _tenantId,
      sessions: const [ActiveSession(id: 'session-1', current: false)],
    ),
  );
}

DeviceSwitchLimitReachedException _deviceSwitchLimitReached() {
  return DeviceSwitchLimitReachedException(
    url: Uri.parse('$_coreUrl/api/v1/user'),
    requestId: 'test-request-id',
    statusCode: 403,
    error: const ErrorResponse(code: 'device_switch_limit_reached'),
  );
}

RequestFailure _serverError() {
  return RequestFailure(
    url: Uri.parse('$_coreUrl/api/v1/user'),
    statusCode: 500,
    requestId: 'test-request-id',
    error: const ErrorResponse(code: 'internal_error'),
  );
}

// An embedded page puts itself into a waiting state when it posts a signup and cannot learn how
// it ended. These pin down what the cubit records for the page: an end for every way the signup
// stops short of a session, none when it reaches one, and no second signup while one is pending.
void main() {
  late _MockAuthRepository authRepository;
  late NotificationsBloc notificationsBloc;
  late List<Session> loggedIn;

  setUpAll(() {
    registerFallbackValue(const RawHttpRequest(method: 'GET', url: 'https://example.com'));
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    notificationsBloc = NotificationsBloc();
    loggedIn = [];
    when(() => authRepository.executePostLoginHttpRequest(any())).thenAnswer((_) async {});
  });

  tearDown(() => notificationsBloc.close());

  LoginCubit buildCubit({AppCompatibilityResolver resolver = const DefaultAppCompatibilityResolver()}) {
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
      appCompatibilityResolver: resolver,
      onLoginSuccess: (session, _) => loggedIn.add(session),
    );
    addTearDown(cubit.close);
    cubit.emit(cubit.state.copyWith(coreUrl: _coreUrl, tenantId: _tenantId, systemInfo: _systemInfo));
    return cubit;
  }

  When<Future<SessionResult>> whenSignup() {
    return when(
      () => authRepository.signup(
        coreUrl: any(named: 'coreUrl'),
        tenantId: any(named: 'tenantId'),
        extraPayload: any(named: 'extraPayload'),
      ),
    );
  }

  Future<EmbeddedSignupEnd?> endOf(Object error) async {
    final cubit = buildCubit();
    whenSignup().thenThrow(error);
    await cubit.loginCustomSignupRequest(null, null);
    await pumpEventQueue();
    return cubit.state.embeddedSignupEnd;
  }

  group('a signup of the embedded page that ends without a session', () {
    test('for the device limit is recorded as such', () async {
      expect((await endOf(_deviceLimitReached()))?.reason, EmbeddedSignupEndReason.deviceLimit);
    });

    test('for the device limit with nothing to sign out is recorded as the device limit', () async {
      expect((await endOf(const LoginDeviceLimitReached()))?.reason, EmbeddedSignupEndReason.deviceLimit);
    });

    test('for the device switch limit is recorded as such', () async {
      expect((await endOf(_deviceSwitchLimitReached()))?.reason, EmbeddedSignupEndReason.deviceSwitchLimit);
    });

    test('for an error answer is recorded as failed, next to the error the dialog shows', () async {
      final cubit = buildCubit();
      whenSignup().thenThrow(_serverError());

      await cubit.loginCustomSignupRequest(null, null);
      await pumpEventQueue();

      expect(cubit.state.embeddedSignupEnd?.reason, EmbeddedSignupEndReason.failed);
      expect(cubit.state.embeddedRequestError, isA<RequestFailure>());
    });

    test('for no connection is recorded as failed', () async {
      expect((await endOf(const SocketException('Connection refused')))?.reason, EmbeddedSignupEndReason.failed);
    });

    test('on a backend this build does not fit is recorded as such', () async {
      final cubit = buildCubit(resolver: _UnsupportedCore());
      cubit.emit(cubit.state.copyWith(systemInfo: null));
      whenSignup().thenAnswer((_) async => const SessionToken(token: 'token'));
      when(() => authRepository.getSystemInfo(any(), any())).thenAnswer((_) async => _systemInfo);

      await cubit.loginCustomSignupRequest(null, null);
      await pumpEventQueue();

      expect(cubit.state.embeddedSignupEnd?.reason, EmbeddedSignupEndReason.unsupportedBackend);
      expect(loggedIn, isEmpty);
    });

    test('twice in a row gives two ends, so the page is answered each time', () async {
      final cubit = buildCubit();
      whenSignup().thenThrow(_serverError());

      await cubit.loginCustomSignupRequest(null, null);
      await pumpEventQueue();
      final first = cubit.state.embeddedSignupEnd;
      await cubit.loginCustomSignupRequest(null, null);
      await pumpEventQueue();

      expect(cubit.state.embeddedSignupEnd, isNotNull);
      expect(identical(cubit.state.embeddedSignupEnd, first), isFalse);
    });
  });

  group('a signup of the embedded page', () {
    test('that signs in records no end', () async {
      final cubit = buildCubit();
      whenSignup().thenAnswer((_) async => const SessionToken(token: 'token'));

      await cubit.loginCustomSignupRequest(null, null);
      await pumpEventQueue();

      expect(cubit.state.embeddedSignupEnd, isNull);
      expect(loggedIn, hasLength(1));
    });

    test('that asks for a one-time code records no end: the code screen takes over', () async {
      final cubit = buildCubit();
      whenSignup().thenAnswer((_) async => const SessionOtpProvisional(otpId: 'otp-1'));

      await cubit.loginCustomSignupRequest(null, null);
      await pumpEventQueue();

      expect(cubit.state.embeddedSignupEnd, isNull);
      expect(cubit.state.signupSessionOtpProvisionalWithDateTime, isNotNull);
    });

    test('clears the end of the one before it when it starts', () async {
      final cubit = buildCubit();
      whenSignup().thenThrow(_serverError());
      await cubit.loginCustomSignupRequest(null, null);
      await pumpEventQueue();

      final answer = Completer<SessionResult>();
      whenSignup().thenAnswer((_) => answer.future);
      unawaited(cubit.loginCustomSignupRequest(null, null));
      await pumpEventQueue();

      expect(cubit.state.embeddedSignupEnd, isNull);
      answer.complete(const SessionToken(token: 'token'));
      await pumpEventQueue();
    });

    test('is not sent again while the one before it is out', () async {
      final cubit = buildCubit();
      final answer = Completer<SessionResult>();
      whenSignup().thenAnswer((_) => answer.future);

      unawaited(cubit.loginCustomSignupRequest(null, null));
      await pumpEventQueue();
      await cubit.loginCustomSignupRequest(null, null);

      verify(
        () => authRepository.signup(
          coreUrl: any(named: 'coreUrl'),
          tenantId: any(named: 'tenantId'),
          extraPayload: any(named: 'extraPayload'),
        ),
      ).called(1);
      answer.complete(const SessionToken(token: 'token'));
      await pumpEventQueue();
    });

    test('is not sent while the device limit screen holds the login the last one ended in', () async {
      final cubit = buildCubit();
      whenSignup().thenThrow(_deviceLimitReached());
      await cubit.loginCustomSignupRequest(null, null);
      await pumpEventQueue();
      expect(cubit.state.pendingLogin, isNotNull);

      await cubit.loginCustomSignupRequest(null, null);
      await pumpEventQueue();

      verify(
        () => authRepository.signup(
          coreUrl: any(named: 'coreUrl'),
          tenantId: any(named: 'tenantId'),
          extraPayload: any(named: 'extraPayload'),
        ),
      ).called(1);
    });

    test('is sent again once the device limit screen is left', () async {
      final cubit = buildCubit();
      whenSignup().thenThrow(_deviceLimitReached());
      await cubit.loginCustomSignupRequest(null, null);
      await pumpEventQueue();

      cubit.loginDeviceLimitBack();
      await cubit.loginCustomSignupRequest(null, null);
      await pumpEventQueue();

      verify(
        () => authRepository.signup(
          coreUrl: any(named: 'coreUrl'),
          tenantId: any(named: 'tenantId'),
          extraPayload: any(named: 'extraPayload'),
        ),
      ).called(2);
    });
  });
}
