import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/session_status/view/session_restart_screen.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../helpers/feature_access_factories.dart';
import '../../../helpers/screen_presets.dart';
import '../../../helpers/semantics.dart';

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

// The two ways out of the screen that says the server cannot be reached,
// reached the way a screen reader and automation reach them, on a phone and
// on a watch.
void main() {
  late _MockAppBloc appBloc;
  late _MockSystemInfoRepository systemInfoRepository;
  late _MockStackRouter router;
  var attempts = 0;

  setUpAll(() {
    registerFallbackValue(FetchPolicy.cacheFirst);
    registerFallbackValue(const AppLogoutRequested());
  });

  setUp(() {
    appBloc = _MockAppBloc();
    whenListen(appBloc, const Stream<AppState>.empty(), initialState: _authenticated);
    systemInfoRepository = _MockSystemInfoRepository();
    attempts = 0;
    when(() => systemInfoRepository.getSystemInfo(fetchPolicy: any(named: 'fetchPolicy'))).thenAnswer((_) async {
      attempts++;
      throw Exception('connection refused');
    });
    router = _MockStackRouter();
    when(() => router.pagelessRoutesObserver).thenReturn(PagelessRoutesObserver());
  });

  Future<void> pumpScreen(WidgetTester tester, {Future<void>? sessionEnded}) async {
    final featureAccess = featureAccessFor(systemInfoWithSupported(const []));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppBloc>.value(value: appBloc),
          Provider<SystemInfoRepository>.value(value: systemInfoRepository),
          Provider<StartupFeatureAccessCheck>.value(value: StartupFeatureAccessCheck.never()),
          Provider<FeatureAccess>.value(value: featureAccess),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
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
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> pumpUnreachable(WidgetTester tester) => pumpScreen(tester);

  testWidgets('try again is named and loads the settings again', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpUnreachable(tester);

    final finder = find.bySemanticsIdentifier(sessionRestartRetryButtonId);
    expectTapTargetSemantics(
      tester,
      finder,
      label: 'Try again',
      identifier: sessionRestartRetryButtonId,
      isButton: true,
    );
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    await tapViaSemantics(tester, finder);
    await tester.pump();

    expect(attempts, 2);
    handle.dispose();
  });

  testWidgets('log out is named and ends the session', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpUnreachable(tester);

    final finder = find.bySemanticsIdentifier(sessionRestartLogoutButtonId);
    expectTapTargetSemantics(
      tester,
      finder,
      label: 'Log out',
      identifier: sessionRestartLogoutButtonId,
      isButton: true,
    );

    await tapViaSemantics(tester, finder);

    verify(() => appBloc.add(const AppLogoutRequested(reason: AppLogoutReason.coreUnreachable))).called(1);
    handle.dispose();
  });

  group('on a watch', () {
    for (final preset in watchPresets) {
      testWidgets('on $preset unreachable: the reason, Try again on the edge, Log out under it', (tester) async {
        preset.apply(tester);
        await pumpUnreachable(tester);

        expect(find.byType(WatchStatePage), findsOneWidget);
        expect(
          find.descendant(of: find.byType(WatchEdgeButton), matching: find.byKey(sessionRestartRetryButtonKey)),
          findsOneWidget,
        );
        expect(find.byKey(sessionRestartLogoutButtonKey, skipOffstage: false), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('after a stopped session: the spinner, the line saying changes are applied', (tester) async {
      watchPresets.first.apply(tester);
      await pumpScreen(tester, sessionEnded: Completer<void>().future);

      expect(find.byType(WatchSpinner), findsOneWidget);
      expect(find.text('Applying changes from the server...'), findsOneWidget);
      expect(find.byType(WatchEdgeButton), findsNothing);
    });

    testWidgets('with no system info stored: the spinner, the line saying settings are loaded', (tester) async {
      when(() => systemInfoRepository.getSystemInfo(fetchPolicy: any(named: 'fetchPolicy')))
          .thenAnswer((_) => Completer<Never>().future);
      watchPresets.first.apply(tester);
      await pumpScreen(tester);

      expect(find.byType(WatchSpinner), findsOneWidget);
      expect(find.text('Loading your settings from the server...'), findsOneWidget);
    });

    testWidgets('Try again loads again; Log out logs out, both through semantics', (tester) async {
      final handle = tester.ensureSemantics();
      watchPresets.last.apply(tester);
      await pumpUnreachable(tester);
      final before = attempts;

      await tapViaSemantics(tester, find.bySemanticsIdentifier(sessionRestartRetryButtonId));
      await tester.pump();
      expect(attempts, greaterThan(before));

      await tester.pump();
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(sessionRestartLogoutButtonKey),
        40,
        scrollable: find.byType(Scrollable).last,
      );
      await tapViaSemantics(tester, find.bySemanticsIdentifier(sessionRestartLogoutButtonId));
      verify(() => appBloc.add(const AppLogoutRequested(reason: AppLogoutReason.coreUnreachable))).called(1);
      handle.dispose();
    });
  });
}
