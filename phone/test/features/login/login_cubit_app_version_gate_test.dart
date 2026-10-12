import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:api/api.dart' show SessionToken;

import 'package:webtrit_phone/app/notifications/notifications.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/login/login.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAppInfo extends Mock implements AppInfo {}

class _MockPackageInfo extends Mock implements PackageInfo {}

WebtritSystemInfo _systemInfo({Version? minSupportedAppVersion, List<String> supported = const ['passwordSignin']}) {
  return WebtritSystemInfo(
    core: CoreInfo(version: Version(1, 0, 0)),
    postgres: PostgresInfo(),
    adapter: AdapterInfo(supported: supported),
    minSupportedAppVersion: minSupportedAppVersion,
  );
}

void main() {
  late _MockAuthRepository authRepository;
  late NotificationsBloc notificationsBloc;
  late List<Session> loginSuccesses;

  setUpAll(() {
    registerFallbackValue(const RawHttpRequest(method: 'GET', url: 'https://example.com'));
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    notificationsBloc = NotificationsBloc();
    loginSuccesses = [];
  });

  tearDown(() {
    notificationsBloc.close();
  });

  LoginCubit buildCubit(String appVersion, {String storeVersion = '0.0.0', String storeBuildNumber = '0'}) {
    final appInfo = _MockAppInfo();
    when(() => appInfo.version).thenReturn(Version.parse(appVersion));
    final packageInfo = _MockPackageInfo();
    when(() => packageInfo.version).thenReturn(storeVersion);
    when(() => packageInfo.buildNumber).thenReturn(storeBuildNumber);
    return LoginCubit(
      authRepository: authRepository,
      notificationsBloc: notificationsBloc,
      appInfo: appInfo,
      packageInfo: packageInfo,
      appCompatibilityResolver: const DefaultAppCompatibilityResolver(),
      onLoginSuccess: (session, _) => loginSuccesses.add(session),
    );
  }

  Future<void> submitCoreUrl(LoginCubit cubit) async {
    cubit.coreUrlInputChanged('https://demo.example.com');
    cubit.loginCoreUrlAssignSubmitted();
    await pumpEventQueue();
  }

  test('blocks login when the app is older than min_supported_app_version', () async {
    when(() => authRepository.getSystemInfo(any(), any()))
        .thenAnswer((_) async => _systemInfo(minSupportedAppVersion: Version(2, 0, 0)));

    final cubit = buildCubit('1.15.3', storeVersion: '4.4.9', storeBuildNumber: '449000002');
    await submitCoreUrl(cubit);

    final notification = notificationsBloc.state.lastNotification;
    expect(notification, isA<AppVersionUnsupportedErrorNotification>());
    // The internal app_version leads the message; the build version+code
    // rides along in parentheses.
    expect((notification as AppVersionUnsupportedErrorNotification).storeVersion, '4.4.9+449000002');
    expect(notification.appVersion, '1.15.3');
    expect(cubit.state.systemInfo, isNull);
    expect(cubit.state.supportedLoginTypes, isNull);
    expect(loginSuccesses, isEmpty);

    await cubit.close();
  });

  test('proceeds when the app satisfies min_supported_app_version', () async {
    when(() => authRepository.getSystemInfo(any(), any()))
        .thenAnswer((_) async => _systemInfo(minSupportedAppVersion: Version(1, 0, 0)));

    final cubit = buildCubit('1.15.3');
    await submitCoreUrl(cubit);

    expect(notificationsBloc.state.lastNotification, isNot(isA<AppVersionUnsupportedErrorNotification>()));
    expect(cubit.state.systemInfo, isNotNull);

    await cubit.close();
  });

  test('proceeds when the backend declares no minimum (null)', () async {
    when(() => authRepository.getSystemInfo(any(), any()))
        .thenAnswer((_) async => _systemInfo(minSupportedAppVersion: null));

    final cubit = buildCubit('1.15.3');
    await submitCoreUrl(cubit);

    expect(notificationsBloc.state.lastNotification, isNot(isA<AppVersionUnsupportedErrorNotification>()));
    expect(cubit.state.systemInfo, isNotNull);

    await cubit.close();
  });

  test('an embedded launch page signs nobody in when the app is too old for the backend', () async {
    // The page signs up before the system info is read, so the gate is met
    // with a token already in hand - and still lets nothing through.
    when(
      () => authRepository.signup(
        coreUrl: any(named: 'coreUrl'),
        tenantId: any(named: 'tenantId'),
        extraPayload: any(named: 'extraPayload'),
      ),
    ).thenAnswer((_) async => const SessionToken(token: 'token-1', userId: 'user-1'));
    when(() => authRepository.getSystemInfo(any(), any()))
        .thenAnswer((_) async => _systemInfo(minSupportedAppVersion: Version(2, 0, 0)));

    final cubit = buildCubit('1.15.3');
    cubit.emit(const LoginState(coreUrl: 'https://demo.example.com'));
    await cubit.loginCustomSignupRequest(null, {'method': 'POST', 'url': 'https://example.com/hook'});
    await pumpEventQueue();

    expect(notificationsBloc.state.lastNotification, isA<AppVersionUnsupportedErrorNotification>());
    expect(loginSuccesses, isEmpty);
    expect(cubit.state.token, isNull);
    expect(cubit.state.processing, isFalse);
    verifyNever(() => authRepository.executePostLoginHttpRequest(any()));

    await cubit.close();
  });
}
