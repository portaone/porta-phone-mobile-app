import 'dart:io';
import 'dart:ui';

import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/resolvers/resolvers.dart';

import '../../helpers/feature_access_factories.dart';
import '../../mocks/mock_app_preferences.dart';
import '../../repository/system_info_repository_integration_harness.dart';
import 'main_shell_harness.dart';

class _MockUserAgreementStatusRepository extends Mock implements UserAgreementStatusRepository {}

class _MockContactsAgreementStatusRepository extends Mock implements ContactsAgreementStatusRepository {}

class _MockSessionRepository extends Mock implements SessionRepository {}

class _MockLocaleRepository extends Mock implements LocaleRepository {}

class _MockThemeModeRepository extends Mock implements ThemeModeRepository {}

class _MockUserSessionCleanupResolver extends Mock implements UserSessionCleanupResolver {}

class _MockAppInfo extends Mock implements AppInfo {}

class _MockAppPermissions extends Mock implements AppPermissions {}

class _FakeNavigationResolver extends Fake implements NavigationResolver {
  final resolutions = <bool>[];

  @override
  bool get isReevaluating => false;

  @override
  void next([bool continueNavigation = true]) => resolutions.add(continueNavigation);

  @override
  void overrideNext({
    List<PageRouteInfo>? children,
    Object? args,
    Map<String, dynamic>? queryParams,
    String? fragment,
    bool reevaluateNext = true,
  }) {}
}

class _FakeStackRouter extends Fake implements StackRouter {
  final replacements = <List<PageRouteInfo>>[];

  @override
  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {
    replacements.add(routes);
  }
}

const _session = Session(coreUrl: 'https://refresh.test', token: 'test-token', userId: '555002');

/// The state a storage move leaves behind: the session survives, the
/// system-info cache does not. On its own that is harmless - the next fetch
/// refills the cache. With a core that will not answer it is the one state the
/// main shell cannot be built from, and the app used to sit on a white screen
/// swapping routes between its two guards forever.
void main() {
  late SystemInfoRepositoryIntegrationHarness systemInfo;
  late _MockSessionRepository sessionRepository;
  late _MockUserSessionCleanupResolver cleanupResolver;
  late AppBloc appBloc;
  late Session currentSession;
  late _FakeNavigationResolver resolver;
  late _FakeStackRouter router;

  setUpAll(() {
    registerHarnessFallbacks();
    registerFallbackValue(const Session());
  });

  setUp(() {
    systemInfo = SystemInfoRepositoryIntegrationHarness(MockAppPreferences());
    // The core is down: every request is refused before it reaches a status.
    systemInfo.respond = (_) async => throw const SocketException('Connection refused');

    sessionRepository = _MockSessionRepository();
    cleanupResolver = _MockUserSessionCleanupResolver();
    currentSession = _session;
    when(() => sessionRepository.getCurrent()).thenAnswer((_) => currentSession);
    when(() => sessionRepository.save(any())).thenAnswer((_) async {});
    when(() => sessionRepository.revokeSession(any())).thenAnswer((_) async {});
    when(() => sessionRepository.clean()).thenAnswer((_) async {
      currentSession = const Session();
    });
    when(() => cleanupResolver.resolve()).thenAnswer((_) async {});

    final agreements = _MockUserAgreementStatusRepository();
    final contactsAgreements = _MockContactsAgreementStatusRepository();
    final locale = _MockLocaleRepository();
    final themeMode = _MockThemeModeRepository();
    final appInfo = _MockAppInfo();
    when(() => agreements.getUserAgreementStatus()).thenReturn(AgreementStatus.accepted);
    when(() => contactsAgreements.getContactsAgreementStatus()).thenReturn(AgreementStatus.accepted);
    when(() => locale.getLocale()).thenReturn(const Locale('en'));
    when(() => themeMode.getThemeMode()).thenReturn(ThemeMode.system);
    when(() => appInfo.version).thenReturn(Version.parse('1.16.5'));

    appBloc = AppBloc(
      userAgreementStatusRepository: agreements,
      contactsAgreementStatusRepository: contactsAgreements,
      sessionRepository: sessionRepository,
      localeRepository: locale,
      themeModeRepository: themeMode,
      systemInfoRepository: systemInfo.repository,
      userSessionCleanupResolver: cleanupResolver,
      appInfo: appInfo,
      appCompatibilityResolver: const DefaultAppCompatibilityResolver(),
    );

    resolver = _FakeNavigationResolver();
    router = _FakeStackRouter();
  });

  tearDown(() async {
    await appBloc.close();
    await systemInfo.dispose();
  });

  AppRouter buildRouter() {
    final featureAccess = featureAccessFor(systemInfoWithSupported(const []));
    final permissions = _MockAppPermissions();
    when(() => permissions.isDenied).thenAnswer((_) async => false);
    return AppRouter(
      appBloc,
      permissions,
      systemInfo.repository,
      null,
      featureAccess.bottomMenuConfig,
      BottomMenuInitialTabResolver(
        config: featureAccess.bottomMenuConfig,
        repository: ActiveMainTabRepositoryPrefsImpl(MockAppPreferences()),
      ),
      featureAccess.checker,
    );
  }

  test('an authenticated start with no cache and no core ends at login, not on an empty stack', () async {
    appBloc.add(const AppLoggedIn(session: _session));
    await pumpEventQueue();
    expect(appBloc.state.status, AppLifecycleStatus.authenticated);
    expect(systemInfo.preferences.getSystemInfo(), isNull, reason: 'the storage move left no cached value');

    final appRouter = buildRouter();

    // 1. The shell cannot be built: the cache is empty, so the real repository
    //    reaches for the core and the core refuses the connection.
    await appRouter.onMainShellRouteGuardNavigation(resolver, router);

    expect(systemInfo.requests, isNotEmpty, reason: 'the cache miss must have reached the network');
    expect(resolver.resolutions, [false]);
    expect(router.replacements.single.single, isA<TeardownScreenPageRoute>());

    // 2. The session ends, and the teardown runs for real.
    await pumpEventQueue();
    expect(appBloc.state.status, AppLifecycleStatus.teardown);
    expect(appBloc.state.logoutReason, AppLogoutReason.coreUnreachable);

    appBloc.add(const AppCleanupRequested());
    await pumpEventQueue();
    expect(appBloc.state.status, AppLifecycleStatus.unauthenticated);
    verify(() => cleanupResolver.resolve()).called(1);
    // The core never answered, so nothing says the remote session is spent.
    verifyNever(() => sessionRepository.revokeSession(any()));

    // 3. The teardown screen hands the user to login, which is where another
    //    core can be entered - the only thing that can help here.
    final loginResolver = _FakeNavigationResolver();
    final loginRouter = _FakeStackRouter();
    appRouter.onTeardownScreenGuardNavigation(loginResolver, loginRouter);

    expect(loginRouter.replacements.single.single, isA<LoginRouterPageRoute>());
  });

  test('the guard leaves a cached session alone, however dead the core is', () async {
    // The same dead core, but the cache survived: the shell builds and polling
    // retries in the background, so nobody is signed out over a network fault.
    await systemInfo.repository.preload(SystemInfoRepositoryIntegrationHarness.cachedInfo);
    appBloc.add(const AppLoggedIn(session: _session));
    await pumpEventQueue();
    // The bloc resolves the compatibility gate on its own at startup, before
    // the cache had a value; only what the guard does is under test here.
    systemInfo.requests.clear();

    await buildRouter().onMainShellRouteGuardNavigation(resolver, router);
    await pumpEventQueue();

    expect(systemInfo.requests, isEmpty, reason: 'a cache hit must not reach the network');
    expect(router.replacements, isEmpty);
    expect(appBloc.state.status, AppLifecycleStatus.authenticated);
  });

  test('a second guard pass does not start a second teardown', () async {
    // Navigation can be re-evaluated while the sequence is running; entering
    // teardown again would strand the app on that screen.
    appBloc.add(const AppLoggedIn(session: _session));
    await pumpEventQueue();

    final appRouter = buildRouter();
    await appRouter.onMainShellRouteGuardNavigation(resolver, router);
    await pumpEventQueue();

    final second = _FakeNavigationResolver();
    final secondRouter = _FakeStackRouter();
    await appRouter.onMainShellRouteGuardNavigation(second, secondRouter);
    await pumpEventQueue();

    expect(appBloc.state.status, AppLifecycleStatus.teardown);
    expect(appBloc.state.logoutReason, AppLogoutReason.coreUnreachable);
    // The teardown branch at the top of the guard takes over, so the second
    // pass routes without asking the repository again.
    expect(secondRouter.replacements.single.single, isA<TeardownScreenPageRoute>());
  });
}
