import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/features/register_status/register_status.dart';
import 'package:webtrit_phone/features/session_status/session_status.dart';
import 'package:webtrit_phone/features/settings/settings.dart';
import 'package:webtrit_phone/features/settings/widgets/widgets.dart';
import 'package:webtrit_phone/features/user_info/user_info.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/utils/utils.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/helpers.dart';
import '../../helpers/screen_presets.dart';

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState> implements SettingsBloc {}

class _MockUserInfoCubit extends MockCubit<UserInfoState> implements UserInfoCubit {}

class _MockSessionStatusCubit extends MockCubit<SessionStatusState> implements SessionStatusCubit {}

class _MockRegisterStatusCubit extends MockCubit<RegisterStatus> implements RegisterStatusCubit {}

class _MockSessionsCubit extends MockCubit<SessionsState> implements SessionsCubit {}

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockStackRouter extends Mock implements StackRouter {}

final _sections = [
  SettingsSection(
    titleL10n: 'settings_ListViewTileTitle_settings',
    items: [
      SettingItem(
        titleL10n: 'settings_ListViewTileTitle_language',
        icon: Icons.language,
        flavor: SettingsFlavor.language,
      ),
      SettingItem(
        titleL10n: 'settings_ListViewTileTitle_themeMode',
        icon: Icons.brightness_6,
        flavor: SettingsFlavor.themeMode,
      ),
      SettingItem(
        titleL10n: 'settings_ListViewTileTitle_about',
        icon: Icons.info_outline,
        flavor: SettingsFlavor.about,
      ),
    ],
  ),
  SettingsSection(
    titleL10n: 'settings_ListViewTileTitle_toolbox',
    items: [
      SettingItem(
        titleL10n: 'settings_ListViewTileTitle_logRecordsConsole',
        icon: Icons.list,
        flavor: SettingsFlavor.log,
      ),
      SettingItem(
        titleL10n: 'settings_ListViewTileTitle_accountDelete',
        icon: Icons.delete_outline,
        flavor: SettingsFlavor.deleteAccount,
      ),
    ],
  ),
];

void main() {
  const info = UserInfo(
    numbers: Numbers(main: '555007'),
    firstName: 'Yuliya',
    lastName: 'Marchenko',
    balance: Balance(balanceType: BalanceType.prepaid, amount: 12.4, currency: 'USD'),
  );

  late _MockSettingsBloc settingsBloc;
  late _MockUserInfoCubit userInfoCubit;
  late _MockSessionStatusCubit sessionStatusCubit;
  late _MockRegisterStatusCubit registerStatusCubit;
  late _MockSessionsCubit sessionsCubit;
  late _MockAppBloc appBloc;
  late _MockStackRouter router;

  setUpAll(() {
    registerFallbackValue(const DiagnosticScreenPageRoute());
  });

  setUp(() {
    settingsBloc = _MockSettingsBloc();
    userInfoCubit = _MockUserInfoCubit();
    sessionStatusCubit = _MockSessionStatusCubit();
    registerStatusCubit = _MockRegisterStatusCubit();
    sessionsCubit = _MockSessionsCubit();
    appBloc = _MockAppBloc();
    router = _MockStackRouter();

    when(() => settingsBloc.state).thenReturn(const SettingsState(progress: false));
    when(() => userInfoCubit.state).thenReturn(const UserInfoState(userInfo: info));
    when(() => sessionStatusCubit.state)
        .thenReturn(const SessionStatusState(status: SessionStatus(signalingStatus: CallStatus.ready)));
    when(() => registerStatusCubit.state).thenReturn(const RegisterStatus(value: true));
    when(() => registerStatusCubit.setStatus(any())).thenAnswer((_) async => true);
    when(() => sessionsCubit.state).thenReturn(
      SessionsState(
        sessions: [for (var i = 0; i < 4; i++) ActiveSession(id: '$i', current: i == 0)],
      ),
    );
    when(() => appBloc.state).thenReturn(
      const AppState(
        themeMode: ThemeMode.system,
        locale: Locale('en'),
        userAgreementStatus: AgreementStatus.accepted,
        contactsAgreementStatus: AgreementStatus.accepted,
      ),
    );
    when(() => router.navigate(any())).thenAnswer((_) async {});
  });

  Widget screen({bool busy = false}) {
    if (busy) when(() => settingsBloc.state).thenReturn(const SettingsState(progress: true));
    return ThemeProvider(
      settings: const ThemeSettings(),
      lightDynamic: null,
      darkDynamic: null,
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
            child: MultiBlocProvider(
              providers: [
                BlocProvider<SettingsBloc>.value(value: settingsBloc),
                BlocProvider<UserInfoCubit>.value(value: userInfoCubit),
                BlocProvider<SessionStatusCubit>.value(value: sessionStatusCubit),
                BlocProvider<RegisterStatusCubit>.value(value: registerStatusCubit),
                BlocProvider<SessionsCubit>.value(value: sessionsCubit),
                BlocProvider<AppBloc>.value(value: appBloc),
                Provider<ThemeSettings>.value(value: const ThemeSettings()),
              ],
              child: PresenceViewParams(
                hybridPresenceSupport: false,
                blfViaSipSupport: false,
                presenceViaSipSupport: false,
                child: SettingsScreen(sections: _sections, sessionsEnabled: true),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Finder list() => find.byType(Scrollable).first;

  for (final preset in watchPresets) {
    testWidgets('on $preset the account heads the list; no app bar', (tester) async {
      preset.apply(tester);
      expect(await pumpCollectingOverflows(tester, screen()), isEmpty);

      expect(find.text('Yuliya Marchenko'), findsOneWidget);
      expect(find.textContaining('555007 · '), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(SettingsWatchList), findsOneWidget);
    });
  }

  testWidgets('the number and the balance are read with a pause, not the dot between them', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    await tester.pumpWidget(screen());
    await tester.pump();

    expect(find.bySemanticsLabel(RegExp(r'^555007, \S')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('\u00B7')), findsNothing);
    handle.dispose();
  });

  testWidgets('the rows: the connection, Online, Sessions with its count, the sections and Log out last', (
    tester,
  ) async {
    watchPresets.last.apply(tester);
    await tester.pumpWidget(screen());

    expect(find.text('Connection established'), findsOneWidget);
    expect(find.byType(WatchToggleChip), findsOneWidget);
    for (final text in ['SETTINGS', 'Language', 'English', 'Light', 'Delete account', 'Logout']) {
      await tester.scrollUntilVisible(find.text(text), 60, scrollable: list());
    }
    // A log has no room on a face.
    expect(find.text('Log records console', skipOffstage: false), findsNothing);
    expect(tester.getRect(find.text('Logout')).top, greaterThan(tester.getRect(find.text('Delete account')).top));
  });

  testWidgets('Online switches the registration; the connection row opens Diagnostics', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    await tester.pumpWidget(screen());

    await tapViaSemantics(tester, find.bySemanticsIdentifier(registerStatusSwitchId));
    verify(() => registerStatusCubit.setStatus(false)).called(1);

    await tapViaSemantics(tester, find.bySemanticsIdentifier(sessionStatusTileId));
    verify(() => router.navigate(const DiagnosticScreenPageRoute())).called(1);
    handle.dispose();
  });

  testWidgets('off the server Online says so and a tap opens Diagnostics, not a switch', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    when(() => sessionStatusCubit.state)
        .thenReturn(const SessionStatusState(status: SessionStatus(signalingStatus: CallStatus.connectivityNone)));
    await tester.pumpWidget(screen());

    expect(find.text('Needs connection'), findsOneWidget);
    await tapViaSemantics(tester, find.bySemanticsIdentifier(registerStatusSwitchId));
    verifyNever(() => registerStatusCubit.setStatus(any()));
    verify(() => router.navigate(const DiagnosticScreenPageRoute())).called(1);
    handle.dispose();
  });

  testWidgets('Log out asks on the watch confirm first', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    await tester.pumpWidget(screen());
    await tester.scrollUntilVisible(find.text('Logout'), 60, scrollable: list());

    await tapViaSemantics(tester, find.bySemanticsIdentifier(settingsLogoutButtonId));
    await tester.pumpAndSettle();

    expect(find.byType(WatchConfirm), findsOneWidget);
    verifyNever(() => settingsBloc.add(const SettingsLogouted()));
    await tester.tap(find.byKey(confirmDialogYesButtonKey));
    await tester.pumpAndSettle();
    verify(() => settingsBloc.add(const SettingsLogouted())).called(1);
    handle.dispose();
  });

  testWidgets('busy: a spinner over the list, which takes no taps', (tester) async {
    watchPresets.first.apply(tester);
    await tester.pumpWidget(screen(busy: true));

    expect(find.byType(WatchSpinner), findsOneWidget);
    expect(find.byType(AbsorbPointer), findsWidgets);
  });
}
