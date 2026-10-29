/// The first start after an update from 1.16.4 or older has no system
/// info stored (it moved from secure storage to app preferences in 1.16.5), so
/// the configuration the app starts with says the backend supports nothing.
/// The Contacts section must still offer every source the backend supports
/// once the main shell is built - on the device it came up without Cloud PBX
/// and stayed so until the next cold start.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:theme_schema/models/models.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/resolvers/resolvers.dart';
import 'package:webtrit_phone/utils/utils.dart';

import '../../helpers/feature_access_factories.dart';

import '../../mocks/mock_app_preferences.dart';
import 'main_shell_harness.dart';

class _FakeNavigationResolver extends Fake implements NavigationResolver {
  final resolutions = <bool>[];

  List<PageRouteInfo>? children;

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
  }) => this.children = children;
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

/// The contacts section as deployments configure it: one list with both
/// address books and the favourites, opened at start.
const _contactsTab = ContactsTabScheme(
  initial: true,
  titleL10n: 'main_BottomNavigationBarItemLabel_contacts',
  icon: '0xee35',
  layout: ContactsLayoutScheme.unified,
  contactSourceTypes: ['local', 'external'],
);

/// Built the way the production stream factory builds it, from whatever
/// system info is stored - none on the start under test.
FeatureAccess _featureAccess(WebtritSystemInfo? systemInfo) {
  final appConfig = createMockAppConfig();
  final bottomMenu = appConfig.mainConfig.bottomMenu;
  when(() => bottomMenu.tabs).thenReturn(const [_contactsTab]);
  final snapshot = MockRemoteConfigSnapshot();
  when(() => snapshot.getBool(any())).thenReturn(null);
  return FeatureAccess.create(
    appConfig,
    [createMockTermsResource()],
    CoreSupportFactory.create(systemInfo),
    systemInfo,
    FeatureOverridesFactory.create(snapshot),
  );
}

/// The sources the contacts route built by the guard offers.
List<ContactsListSelection> _offeredSources(List<PageRouteInfo> children) {
  final shell = children.single;
  final contacts = shell.initialChildren!.single;
  final screen = contacts.initialChildren!.single;
  return (screen.args! as ContactsFilterScreenPageRouteArgs).selections;
}

void main() {
  late MockAppBloc appBloc;
  late MockSystemInfoRepository systemInfoRepository;
  late MockAppPermissions appPermissions;

  /// What the backend answers: it supports its extensions, so Cloud PBX.
  final backend = systemInfoWithSupported(const ['extensions']);

  /// What app preferences hold; null until something stores the answer.
  WebtritSystemInfo? stored;

  setUpAll(registerHarnessFallbacks);

  setUp(() {
    Logger.root.level = Level.INFO;

    appBloc = MockAppBloc();
    systemInfoRepository = MockSystemInfoRepository();
    appPermissions = MockAppPermissions();
    stored = null;

    when(() => appBloc.state).thenReturn(
      AppState(
        status: AppLifecycleStatus.authenticated,
        session: const Session(coreUrl: 'http://127.0.0.1:1', token: 'test-token', userId: 'test-user'),
        themeMode: ThemeMode.system,
        locale: const Locale('en'),
        userAgreementStatus: AgreementStatus.accepted,
        contactsAgreementStatus: AgreementStatus.accepted,
      ),
    );
    // The repository as it behaves: the cache answers what is stored, and a
    // read that may reach the network stores the backend's answer.
    when(() => systemInfoRepository.getSystemInfo(fetchPolicy: FetchPolicy.cacheOnly)).thenAnswer((_) async => stored);
    when(() => systemInfoRepository.getSystemInfo(fetchPolicy: FetchPolicy.cacheFirst)).thenAnswer((_) async {
      return stored ??= backend;
    });
    when(() => systemInfoRepository.getSystemInfo(fetchPolicy: FetchPolicy.networkOnly)).thenAnswer((_) async {
      return stored = backend;
    });
  });

  test('a start with no system info stored builds Contacts with every source the backend supports', () async {
    // The app starts on the configuration of an empty cache, and so does its router.
    final startup = _featureAccess(null);
    final appRouter = AppRouter(
      appBloc,
      appPermissions,
      systemInfoRepository,
      null,
      startup.bottomMenuConfig,
      BottomMenuInitialTabResolver(
        config: startup.bottomMenuConfig,
        repository: ActiveMainTabRepositoryPrefsImpl(MockAppPreferences()),
      ),
      startup.checker,
    );

    final resolver = _FakeNavigationResolver();
    final router = _FakeStackRouter();
    await appRouter.onMainShellRouteGuardNavigation(resolver, router);

    // If the guard sends the app to the restart screen instead, that screen
    // loads the system info; the app then rebuilds its configuration from it,
    // hands it to the router, and the main shell is asked for again.
    var children = resolver.children;
    if (children == null) {
      expect(router.replacements.single.single, isA<SessionRestartScreenPageRoute>());
      await systemInfoRepository.getSystemInfo(fetchPolicy: FetchPolicy.cacheFirst);
      final current = _featureAccess(stored);
      appRouter.updateConfiguration(
        null,
        current.bottomMenuConfig,
        BottomMenuInitialTabResolver(
          config: current.bottomMenuConfig,
          repository: ActiveMainTabRepositoryPrefsImpl(MockAppPreferences()),
        ),
        current.checker,
      );
      final again = _FakeNavigationResolver();
      await appRouter.onMainShellRouteGuardNavigation(again, _FakeStackRouter());
      children = again.children;
    }

    expect(children, isNotNull, reason: 'the main shell was never built');
    expect(
      _offeredSources(children!),
      contains(const ContactsSourceSelection(ContactSourceType.external)),
      reason: 'Contacts came up without Cloud PBX although the backend supports it',
    );
  });
}
