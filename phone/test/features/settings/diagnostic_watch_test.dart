import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/features/settings/features/diagnostic/diagnostic.dart';
import 'package:webtrit_phone/features/settings/features/diagnostic/models/models.dart';
import 'package:webtrit_phone/features/settings/features/diagnostic/view/diagnostic_screen.dart';
import 'package:webtrit_phone/features/settings/features/diagnostic/widgets/diagnostic_watch.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/helpers.dart';
import '../../helpers/screen_presets.dart';

class _MockDiagnosticCubit extends MockCubit<DiagnosticState> implements DiagnosticCubit {}

class _MockNetworkTesterCubit extends MockCubit<NetworkTesterState> implements NetworkTesterCubit {}

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockStackRouter extends Mock implements StackRouter {}

void main() {
  late _MockDiagnosticCubit diagnostic;
  late _MockNetworkTesterCubit network;
  late _MockAppBloc appBloc;

  final microphone = PermissionWithStatus(Permission.microphone, PermissionStatus.denied);
  final camera = PermissionWithStatus(Permission.camera, PermissionStatus.granted);

  setUpAll(() => registerFallbackValue(microphone));

  setUp(() {
    diagnostic = _MockDiagnosticCubit();
    network = _MockNetworkTesterCubit();
    appBloc = _MockAppBloc();
    when(() => diagnostic.state).thenReturn(
      DiagnosticState(
        permissions: [camera, microphone],
        pushTokenStatus: const PushTokenStatus(type: PushTokenStatusType.success),
        batteryMode: CallkeepAndroidBatteryMode.optimized,
        fullScreenIntentStatus: CallkeepSpecialPermissionStatus.granted,
      ),
    );
    when(() => diagnostic.handleRequestPermission(any())).thenAnswer((_) async {});
    when(() => diagnostic.openAppSettings()).thenAnswer((_) async {});
    when(() => network.state).thenReturn(
      const NetworkTesterState(networks: [ConnectivityResult.wifi], gatheringStatus: IceGatheringStatus.gathering),
    );
    when(() => network.refresh()).thenAnswer((_) async {});
    when(() => appBloc.state).thenReturn(
      const AppState(
        themeMode: ThemeMode.light,
        locale: Locale('en'),
        userAgreementStatus: AgreementStatus.accepted,
        contactsAgreementStatus: AgreementStatus.accepted,
      ),
    );
  });

  Widget app() {
    final router = _MockStackRouter();
    when(() => router.pagelessRoutesObserver).thenReturn(PagelessRoutesObserver());
    when(
      () => router.canPop(
        ignoreChildRoutes: any(named: 'ignoreChildRoutes'),
        ignoreParentRoutes: any(named: 'ignoreParentRoutes'),
        ignorePagelessRoutes: any(named: 'ignorePagelessRoutes'),
      ),
    ).thenReturn(false);
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => RouterScope(
        controller: router,
        inheritableObserversBuilder: () => const [],
        stateHash: 0,
        child: StackRouterScope(
          controller: router,
          stateHash: 0,
          child: MultiProvider(
            providers: [
              BlocProvider<DiagnosticCubit>.value(value: diagnostic),
              BlocProvider<NetworkTesterCubit>.value(value: network),
              BlocProvider<AppBloc>.value(value: appBloc),
              Provider<DiagnosticScreenContext>.value(
                value: DiagnosticScreenContext(isLocalContactsFeatureEnabled: false),
              ),
            ],
            child: child!,
          ),
        ),
      ),
      home: const DiagnosticScreen(),
    );
  }

  Finder rows() => find.byType(WatchListTile);

  for (final preset in watchPresets) {
    testWidgets('on $preset a row per check, the failing one first and outlined; no app bar', (tester) async {
      preset.apply(tester);
      expect(await pumpCollectingOverflows(tester, app()), isEmpty);

      expect(find.byType(AppBar), findsNothing);
      final first = tester.widget<WatchListTile>(rows().first);
      expect(first.title, 'Microphone');
      expect(first.outlined, isTrue);
      expect(first.subtitle, 'Access Denied');
    });
  }

  testWidgets('the order is worst first: failing, to look at, running, fine', (tester) async {
    watchPresets.last.apply(tester);
    await tester.pumpWidget(app());

    // Microphone denied; Battery mode optimised; the network still checking;
    // push, camera and full-screen calls fine. Each is reached scrolling down
    // only, so one listed above another fails the walk.
    for (final title in ['Microphone', 'Battery mode', 'Network', 'Camera']) {
      await tester.scrollUntilVisible(find.text(title), 40, scrollable: find.byType(Scrollable).last);
    }
  });

  testWidgets('a denied permission opens its page; Request permission on the edge asks the system', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    await tester.pumpWidget(app());

    await tester.tap(find.text('Microphone'));
    await tester.pumpAndSettle();
    expect(find.byType(DiagnosticWatchCheckPage), findsOneWidget);
    expect(find.text('Access Denied'), findsOneWidget);

    await tapViaSemantics(tester, find.bySemanticsLabel('Allow'));
    verify(() => diagnostic.handleRequestPermission(microphone)).called(1);
    // The page closes, as the phone's sheet does: it would go on showing the
    // status it opened with. Not settled: the list under it has the network
    // check's spinner.
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DiagnosticWatchCheckPage), findsNothing);
    handle.dispose();
  });

  testWidgets('a check that is fine has no fix on its page', (tester) async {
    watchPresets.last.apply(tester);
    await tester.pumpWidget(app());

    await tester.scrollUntilVisible(find.text('Camera'), 60, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();

    expect(find.text('Access Granted'), findsOneWidget);
    expect(find.byType(WatchEdgeButton), findsNothing);
  });

  testWidgets('the network page runs the check again from its edge', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    when(() => network.state).thenReturn(const NetworkTesterState(networks: [ConnectivityResult.none]));
    await tester.pumpWidget(app());

    expect(tester.widget<WatchListTile>(rows().at(1)).title, 'Network');
    await tapViaSemantics(tester, find.bySemanticsIdentifier(diagnosticNetworkTestId));
    await tester.pumpAndSettle();
    expect(find.byType(DiagnosticWatchNetworkPage), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);

    await tapViaSemantics(tester, find.bySemanticsLabel('Run again'));
    verify(() => network.refresh()).called(1);
    handle.dispose();
  });
}
