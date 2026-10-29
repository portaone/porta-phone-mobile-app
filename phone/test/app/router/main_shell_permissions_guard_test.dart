/// After the microphone stopped being required (App Store Review Guideline 5.1.1(iv): the
/// app must stay usable after "Don't Allow"), the permissions screen is no gate: it is a step
/// on the way in from a sign-in, shown only while something the app asks for is not granted,
/// after the agreements; a start of an app already signed in never passes through it.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/resolvers/resolvers.dart';

import '../../mocks/mock_app_preferences.dart';
import 'main_shell_harness.dart';
import '../../helpers/feature_access_factories.dart';

class _FakeNavigationResolver extends Fake implements NavigationResolver {
  final resolutions = <bool>[];

  var overrodeNext = false;

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
  }) => overrodeNext = true;
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

void main() {
  late MockAppBloc appBloc;
  late MockSystemInfoRepository systemInfoRepository;
  late MockAppPermissions appPermissions;
  late _FakeNavigationResolver resolver;
  late _FakeStackRouter router;

  void signedIn({AgreementStatus userAgreement = AgreementStatus.accepted, bool loggedIn = true}) {
    when(() => appBloc.state).thenReturn(
      AppState(
        status: loggedIn ? AppLifecycleStatus.authenticated : AppLifecycleStatus.unauthenticated,
        session: loggedIn
            ? const Session(coreUrl: 'http://127.0.0.1:1', token: 'test-token', userId: 'test-user')
            : const Session(),
        themeMode: ThemeMode.system,
        locale: const Locale('en'),
        userAgreementStatus: userAgreement,
        contactsAgreementStatus: AgreementStatus.accepted,
      ),
    );
  }

  setUpAll(registerHarnessFallbacks);

  setUp(() {
    // The guard builds its log line from the resolver's route, which the fake
    // does not carry; keeping fine records off leaves that closure unevaluated.
    Logger.root.level = Level.INFO;

    appBloc = MockAppBloc();
    systemInfoRepository = MockSystemInfoRepository();
    appPermissions = MockAppPermissions();
    resolver = _FakeNavigationResolver();
    router = _FakeStackRouter();

    when(() => systemInfoRepository.getSystemInfo(fetchPolicy: any(named: 'fetchPolicy')))
        .thenAnswer((_) async => systemInfoWithSupported(const []));
    signedIn();
  });

  AppRouter buildRouter() {
    final featureAccess = featureAccessFor(systemInfoWithSupported(const []));
    return AppRouter(
      appBloc,
      appPermissions,
      systemInfoRepository,
      null,
      featureAccess.bottomMenuConfig,
      BottomMenuInitialTabResolver(
        config: featureAccess.bottomMenuConfig,
        repository: ActiveMainTabRepositoryPrefsImpl(MockAppPreferences()),
      ),
      featureAccess.checker,
    );
  }

  PageRouteInfo? sentTo() => router.replacements.isEmpty ? null : router.replacements.single.single;

  group('the way in from a sign-in', () {
    test('goes through the permissions screen while a permission is not granted', () async {
      when(() => appPermissions.anyNotGranted).thenAnswer((_) async => true);

      await buildRouter().onLoginScreenPageRouteGuardNavigation(resolver, router);

      expect(resolver.resolutions, [false]);
      expect(sentTo(), isA<PermissionsScreenPageRoute>());
    });

    test('goes straight to the main screen with everything granted', () async {
      when(() => appPermissions.anyNotGranted).thenAnswer((_) async => false);

      await buildRouter().onLoginScreenPageRouteGuardNavigation(resolver, router);

      expect(sentTo(), isA<MainShellRoute>());
    });

    test('leaves an open agreement to the main screen, whose guard shows it first', () async {
      signedIn(userAgreement: AgreementStatus.pending);
      when(() => appPermissions.anyNotGranted).thenAnswer((_) async => true);

      await buildRouter().onLoginScreenPageRouteGuardNavigation(resolver, router);

      expect(sentTo(), isA<MainShellRoute>());
      verifyNever(() => appPermissions.anyNotGranted);
    });

    test('an accepted agreement leads on to the permissions screen', () async {
      when(() => appPermissions.anyNotGranted).thenAnswer((_) async => true);

      await buildRouter().onUserAgreementScreenPageRouteGuardNavigation(resolver, router);

      expect(sentTo(), isA<PermissionsScreenPageRoute>());
    });
  });

  group('the main screen and the permissions screen', () {
    test('a start of an app already signed in goes in, whatever is granted', () async {
      when(() => appPermissions.anyNotGranted).thenAnswer((_) async => true);

      await buildRouter().onMainShellRouteGuardNavigation(resolver, router);

      expect(resolver.overrodeNext, isTrue);
      expect(router.replacements, isEmpty);
      verifyNever(() => appPermissions.anyNotGranted);
    });

    test('the permissions screen stays while there is something to ask', () async {
      when(() => appPermissions.anyNotGranted).thenAnswer((_) async => true);

      await buildRouter().onPermissionsScreenPageRouteGuardNavigation(resolver, router);

      expect(resolver.resolutions, [true]);
    });

    test('the permissions screen sends the user on once everything is granted', () async {
      when(() => appPermissions.anyNotGranted).thenAnswer((_) async => false);

      await buildRouter().onPermissionsScreenPageRouteGuardNavigation(resolver, router);

      expect(resolver.resolutions, [false]);
      expect(sentTo(), isA<MainShellRoute>());
    });
  });
}
