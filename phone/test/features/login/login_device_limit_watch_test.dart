import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:api/api.dart' show AppType, SessionToken;

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/notifications/notifications.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/login/login.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/helpers.dart';
import '../../helpers/screen_presets.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAppInfo extends Mock implements AppInfo {}

class _MockPackageInfo extends Mock implements PackageInfo {}

void main() {
  late _MockAuthRepository authRepository;
  late NotificationsBloc notificationsBloc;
  late LoginCubit cubit;

  setUp(() {
    authRepository = _MockAuthRepository();
    notificationsBloc = NotificationsBloc();

    final appInfo = _MockAppInfo();
    when(() => appInfo.version).thenReturn(Version.parse('1.0.0'));
    final packageInfo = _MockPackageInfo();
    when(() => packageInfo.version).thenReturn('1.0.0');
    when(() => packageInfo.buildNumber).thenReturn('1');

    cubit = LoginCubit(
      authRepository: authRepository,
      notificationsBloc: notificationsBloc,
      appInfo: appInfo,
      packageInfo: packageInfo,
      appCompatibilityResolver: const DefaultAppCompatibilityResolver(),
      onLoginSuccess: (_, _) {},
    );

    cubit.emit(
      cubit.state.copyWith(
        coreUrl: 'https://core.example.com',
        tenantId: 'tenant-1',
        systemInfo: WebtritSystemInfo(
          core: CoreInfo(version: Version(1, 0, 0)),
          postgres: PostgresInfo(version: '15.0'),
        ),
        pendingLogin: const PendingLogin(
          token: 'pending-login-token',
          tenantId: 'tenant-1',
          sessions: [
            ActiveSession(
              id: 'session-1',
              current: false,
              appType: AppType.android,
              userAgent: 'PortaPhone/1.0.0+1 (Pixel 9; Android: 15)',
            ),
            ActiveSession(
              id: 'session-2',
              current: false,
              appType: AppType.ios,
              userAgent: 'PortaPhone/1.0.0+1 (iPhone 12 mini; iOS: 26)',
            ),
          ],
        ),
      ),
    );
  });

  tearDown(() {
    cubit.close();
    notificationsBloc.close();
  });

  Widget wrap() {
    return ThemeProvider(
      settings: const ThemeSettings(),
      lightDynamic: null,
      darkDynamic: null,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<LoginCubit>.value(
          value: cubit,
          child: LoginDeviceLimitScreen(dateFormat: DateFormat('yyyy-MM-dd HH:mm')),
        ),
      ),
    );
  }

  for (final preset in watchPresets) {
    testWidgets('on $preset the reason and the devices as rows under the screen\'s name', (tester) async {
      preset.apply(tester);
      expect(await pumpCollectingOverflows(tester, wrap()), isEmpty);

      expect(find.text('Device limit reached'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      for (final device in ['Pixel 9', 'iPhone 12 mini']) {
        await tester.scrollUntilVisible(
          find.widgetWithText(WatchListTile, device),
          40,
          scrollable: find.byType(Scrollable).last,
        );
      }
    });
  }

  testWidgets('a tap on a device asks on the watch confirm; no keeps it signed in', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    await tester.pumpWidget(wrap());

    await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(sessionsTileId, 0)));
    await tester.pumpAndSettle();
    expect(find.byType(WatchConfirm), findsOneWidget);
    expect(find.text('Sign out this session?'), findsOneWidget);

    await tester.tap(find.byKey(confirmDialogNoButtonKey));
    await tester.pumpAndSettle();
    expect(find.byType(WatchConfirm), findsNothing);
    expect(cubit.state.pendingLoginRevokingSessionId, isNull);
    verifyNever(
      () => authRepository.completeLogin(
        coreUrl: any(named: 'coreUrl'),
        tenantId: any(named: 'tenantId'),
        pendingLoginToken: any(named: 'pendingLoginToken'),
        revokeSessionId: any(named: 'revokeSessionId'),
      ),
    );
    handle.dispose();
  });

  testWidgets('yes on the watch confirm finishes the login with the device signed out', (tester) async {
    final handle = tester.ensureSemantics();
    when(
      () => authRepository.completeLogin(
        coreUrl: any(named: 'coreUrl'),
        tenantId: any(named: 'tenantId'),
        pendingLoginToken: any(named: 'pendingLoginToken'),
        revokeSessionId: any(named: 'revokeSessionId'),
      ),
    ).thenAnswer((_) async => const SessionToken(token: 'token-1'));
    watchPresets.last.apply(tester);
    await tester.pumpWidget(wrap());

    await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(sessionsTileId, 0)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(confirmDialogYesButtonKey));
    // Not pumpAndSettle: the row keeps its spinner until the app leaves the
    // login, which this test has nothing to do it with.
    await tester.pump(const Duration(milliseconds: 500));

    verify(
      () => authRepository.completeLogin(
        coreUrl: 'https://core.example.com',
        tenantId: 'tenant-1',
        pendingLoginToken: 'pending-login-token',
        revokeSessionId: 'session-1',
      ),
    ).called(1);
    handle.dispose();
  });

  testWidgets('while a device is being signed out another one asks nothing', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    await tester.pumpWidget(wrap());
    cubit.emit(cubit.state.copyWith(processing: true, pendingLoginRevokingSessionId: 'session-1'));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.bySemanticsIdentifier(numberedId(sessionsTileId, 1)),
      40,
      scrollable: find.byType(Scrollable).last,
    );
    await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(sessionsTileId, 1)));
    await tester.pump();

    expect(find.byType(WatchConfirm), findsNothing);
    handle.dispose();
  });
}
