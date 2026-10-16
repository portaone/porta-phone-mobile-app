import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/session_status/view/session_restart_screen.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/utils.dart';

import '../../../helpers/feature_access_factories.dart';
import '../../../mocks/feature_access_mocks.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockSystemInfoRepository extends Mock implements SystemInfoRepository {}

class _MockStackRouter extends Mock implements StackRouter {}

const _authenticated = AppState(
  status: AppLifecycleStatus.authenticated,
  themeMode: ThemeMode.system,
  locale: Locale('en'),
  userAgreementStatus: AgreementStatus.accepted,
  contactsAgreementStatus: AgreementStatus.accepted,
);

/// The configuration of a start with no system info stored.
FeatureAccess _withoutSystemInfo() {
  final snapshot = MockRemoteConfigSnapshot();
  when(() => snapshot.getBool(any())).thenReturn(null);
  return FeatureAccess.create(
    createMockAppConfig(),
    [createMockTermsResource()],
    CoreSupportFactory.create(null),
    null,
    FeatureOverridesFactory.create(snapshot),
  );
}

void main() {
  late _MockAppBloc appBloc;
  late StreamController<AppState> appStates;
  late _MockSystemInfoRepository systemInfoRepository;
  late StreamController<FeatureAccess> featureAccess;
  late _MockStackRouter router;
  late List<PageRouteInfo<dynamic>> navigations;

  /// What the backend answers: it supports its extensions, so Cloud PBX.
  final backend = systemInfoWithSupported(const ['extensions']);

  /// What app preferences hold; null until the screen has the answer stored.
  WebtritSystemInfo? stored;

  setUpAll(() {
    registerFallbackValue(FetchPolicy.cacheFirst);
    registerFallbackValue(const AppLogoutRequested());
    registerFallbackValue(<PageRouteInfo<dynamic>>[]);
  });

  setUp(() {
    appBloc = _MockAppBloc();
    appStates = StreamController<AppState>();
    whenListen(appBloc, appStates.stream, initialState: _authenticated);
    systemInfoRepository = _MockSystemInfoRepository();
    featureAccess = StreamController<FeatureAccess>();
    stored = null;
    // The repository as it behaves: a read that may reach the network stores
    // the answer, and the cache gives back what is stored.
    when(() => systemInfoRepository.getSystemInfo(fetchPolicy: FetchPolicy.cacheFirst)).thenAnswer((_) async {
      return stored ??= backend;
    });
    when(() => systemInfoRepository.getSystemInfo(fetchPolicy: FetchPolicy.cacheOnly)).thenAnswer((_) async => stored);

    navigations = [];
    router = _MockStackRouter();
    when(() => router.replaceAll(any())).thenAnswer((invocation) async {
      navigations.addAll(invocation.positionalArguments.single as List<PageRouteInfo<dynamic>>);
    });
    when(() => router.pagelessRoutesObserver).thenReturn(PagelessRoutesObserver());
  });

  tearDown(() async {
    await featureAccess.close();
    await appStates.close();
  });

  Widget subject({Future<void>? sessionEnded, bool followsBackend = true}) {
    return MultiProvider(
      providers: [
        Provider<AppBloc>.value(value: appBloc),
        Provider<SystemInfoRepository>.value(value: systemInfoRepository),
        Provider<StartupFeatureAccessCheck>.value(
          value: followsBackend
              ? StartupFeatureAccessCheck(
                  systemInfoReads: const Stream.empty(),
                  current: () async => _withoutSystemInfo(),
                )
              : StartupFeatureAccessCheck.never(),
        ),
        StreamProvider<FeatureAccess>(
          initialData: _withoutSystemInfo(),
          create: (_) => featureAccess.stream,
          updateShouldNotify: (previous, next) => previous != next,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RouterScope(
          controller: router,
          inheritableObserversBuilder: () => const [],
          stateHash: 0,
          navigatorObservers: const [],
          child: StackRouterScope(
            controller: router,
            stateHash: 0,
            child: SessionRestartScreen(sessionEnded: sessionEnded),
          ),
        ),
      ),
    );
  }

  /// The app rebuilds its configuration from what was stored, as the
  /// production stream does after the store.
  Future<void> configurationTakesItIn(WidgetTester tester) async {
    featureAccess.add(featureAccessFor(stored!));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('goes to the main shell only once the configuration is rebuilt from the stored system info', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));

    expect(find.text('Loading your settings from the server...'), findsOneWidget);
    expect(navigations, isEmpty, reason: 'the router still holds the configuration without the backend answer');

    await configurationTakesItIn(tester);

    expect(navigations.single, isA<MainShellRoute>());
  });

  testWidgets('waits for the configuration also when the backend supports nothing', (tester) async {
    // The capability checks of such an answer match those of no answer at all:
    // only the configuration itself can say it was built from system info.
    when(() => systemInfoRepository.getSystemInfo(fetchPolicy: FetchPolicy.cacheFirst)).thenAnswer((_) async {
      return stored ??= systemInfoWithSupported(const []);
    });

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.pump();
    expect(navigations, isEmpty);

    await configurationTakesItIn(tester);

    expect(navigations.single, isA<MainShellRoute>());
  });

  testWidgets('does not wait for a configuration a host supplies', (tester) async {
    await tester.pumpWidget(subject(followsBackend: false));
    await tester.pump();
    await tester.pump();

    expect(navigations.single, isA<MainShellRoute>());
  });

  testWidgets('says the server cannot be reached and loads again on request', (tester) async {
    var attempts = 0;
    when(() => systemInfoRepository.getSystemInfo(fetchPolicy: FetchPolicy.cacheFirst)).thenAnswer((_) async {
      attempts++;
      if (attempts == 1) throw Exception('connection refused');
      return stored ??= backend;
    });

    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
    expect(navigations, isEmpty);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await configurationTakesItIn(tester);

    expect(attempts, 2);
    expect(navigations.single, isA<MainShellRoute>());
  });

  testWidgets('does not leave when the loaded value does not read back from the cache', (tester) async {
    // The main shell guard reads the cache only: leaving would bring the app
    // straight back here, one request per lap.
    when(() => systemInfoRepository.getSystemInfo(fetchPolicy: FetchPolicy.cacheFirst))
        .thenAnswer((_) async => backend);

    await tester.pumpWidget(subject());
    await tester.pump();
    featureAccess.add(featureAccessFor(backend));
    await tester.pump();
    await tester.pump();

    expect(navigations, isEmpty);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('logs out on request and leaves only once the session has ended', (tester) async {
    // The bloc takes the request a turn later; a route asked for before that
    // finds a running session, and the app was left on an empty screen.
    when(() => systemInfoRepository.getSystemInfo(fetchPolicy: FetchPolicy.cacheFirst))
        .thenThrow(Exception('connection refused'));

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.tap(find.text('Log out'));
    await tester.pump();

    verify(() => appBloc.add(const AppLogoutRequested(reason: AppLogoutReason.coreUnreachable))).called(1);
    expect(navigations, isEmpty, reason: 'the session has not ended yet');

    appStates.add(_authenticated.copyWith(status: AppLifecycleStatus.teardown));
    await tester.pump();
    await tester.pump();

    // The main shell guard sends a session in teardown to the teardown screen.
    expect(navigations.single, isA<MainShellRoute>());
  });

  testWidgets('a log-out the bloc ignores leaves the button working', (tester) async {
    when(() => systemInfoRepository.getSystemInfo(fetchPolicy: FetchPolicy.cacheFirst))
        .thenThrow(Exception('connection refused'));

    await tester.pumpWidget(subject());
    await tester.pump();
    await tester.tap(find.text('Log out'));
    await tester.pump();
    await tester.tap(find.text('Log out'));
    await tester.pump();

    verify(() => appBloc.add(const AppLogoutRequested(reason: AppLogoutReason.coreUnreachable))).called(2);
  });

  testWidgets('leaves when the session ends elsewhere while the server is out of reach', (tester) async {
    when(() => systemInfoRepository.getSystemInfo(fetchPolicy: FetchPolicy.cacheFirst))
        .thenThrow(Exception('connection refused'));

    await tester.pumpWidget(subject());
    await tester.pump();
    expect(find.text('Try again'), findsOneWidget);

    appStates.add(_authenticated.copyWith(status: AppLifecycleStatus.unauthenticated));
    await tester.pump();
    await tester.pump();

    expect(navigations.single, isA<MainShellRoute>());
  });

  testWidgets('after a stopped session it says changes are applied and waits for the old one to let go', (
    tester,
  ) async {
    final sessionEnded = Completer<void>();
    stored = backend;
    featureAccess.add(featureAccessFor(backend));

    await tester.pumpWidget(subject(sessionEnded: sessionEnded.future));
    await tester.pump();
    await tester.pump();

    expect(find.text('Applying changes from the server...'), findsOneWidget);
    expect(navigations, isEmpty);

    sessionEnded.complete();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(navigations.single, isA<MainShellRoute>());
  });
}
