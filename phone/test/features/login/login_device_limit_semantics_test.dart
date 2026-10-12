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
            ActiveSession(id: 'session-1', current: false, appType: AppType.android, userAgent: 'Pixel 9'),
            ActiveSession(id: 'session-2', current: false, appType: AppType.ios, userAgent: 'iPhone 12 mini'),
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
        home: Scaffold(
          body: BlocProvider<LoginCubit>.value(
            value: cubit,
            child: LoginDeviceLimitBody(dateFormat: DateFormat('yyyy-MM-dd HH:mm')),
          ),
        ),
      ),
    );
  }

  Finder signOutOf(String device) {
    return find.descendant(
      of: find.ancestor(of: find.text(device), matching: find.byType(SessionTile)),
      matching: find.widgetWithText(TextButton, 'Sign out'),
    );
  }

  testWidgets('the screen can be told apart by id and says what it is for', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(wrap());

    expect(find.bySemanticsIdentifier(loginDeviceLimitScreenId), findsOneWidget);
    expect(find.textContaining('Sign out one of them to continue on this device'), findsOneWidget);
    expect(find.text('Android app'), findsOneWidget);
    expect(find.text('iOS app'), findsOneWidget);

    handle.dispose();
  });

  testWidgets('every device offers to be signed out', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(wrap());

    for (final device in ['Pixel 9', 'iPhone 12 mini']) {
      expectTapTargetSemantics(tester, signOutOf(device), label: 'Sign out', isButton: true);
    }
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });

  testWidgets('signing a device out asks first and then finishes the login with it', (tester) async {
    final handle = tester.ensureSemantics();
    when(
      () => authRepository.completeLogin(
        coreUrl: any(named: 'coreUrl'),
        tenantId: any(named: 'tenantId'),
        pendingLoginToken: any(named: 'pendingLoginToken'),
        revokeSessionId: any(named: 'revokeSessionId'),
      ),
    ).thenAnswer((_) async => const SessionToken(token: 'token-1'));

    await tester.pumpWidget(wrap());

    await tapViaSemantics(tester, signOutOf('iPhone 12 mini'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out this session?'), findsOneWidget);
    verifyNever(
      () => authRepository.completeLogin(
        coreUrl: any(named: 'coreUrl'),
        tenantId: any(named: 'tenantId'),
        pendingLoginToken: any(named: 'pendingLoginToken'),
        revokeSessionId: any(named: 'revokeSessionId'),
      ),
    );

    await tapViaSemantics(tester, find.widgetWithText(TextButton, 'Yes'));
    // Not pumpAndSettle: the row keeps its progress indicator until the app
    // leaves the login, which this test has nothing to do it with.
    await tester.pump(const Duration(milliseconds: 500));

    verify(
      () => authRepository.completeLogin(
        coreUrl: 'https://core.example.com',
        tenantId: 'tenant-1',
        pendingLoginToken: 'pending-login-token',
        revokeSessionId: 'session-2',
      ),
    ).called(1);

    handle.dispose();
  });

  testWidgets('declining the question signs nothing out', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(wrap());

    await tapViaSemantics(tester, signOutOf('Pixel 9'));
    await tester.pumpAndSettle();
    await tapViaSemantics(tester, find.widgetWithText(TextButton, 'No'));
    await tester.pumpAndSettle();

    verifyNever(
      () => authRepository.completeLogin(
        coreUrl: any(named: 'coreUrl'),
        tenantId: any(named: 'tenantId'),
        pendingLoginToken: any(named: 'pendingLoginToken'),
        revokeSessionId: any(named: 'revokeSessionId'),
      ),
    );
    expect(cubit.state.pendingLogin, isNotNull);

    handle.dispose();
  });

  testWidgets('the device being signed out cannot be pressed again', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(wrap());
    cubit.emit(cubit.state.copyWith(processing: true, pendingLoginRevokingSessionId: 'session-1'));
    await tester.pump();

    expect(
      tester.getSemantics(signOutOf('Pixel 9')),
      isSemantics(label: 'Sign out', isButton: true, hasTapAction: false),
    );

    handle.dispose();
  });

  testWidgets('a device that turned out to be signed out already leaves the list', (tester) async {
    await tester.pumpWidget(wrap());

    cubit.emit(cubit.state.copyWith(pendingLogin: cubit.state.pendingLogin!.withoutSession('session-1')));
    await tester.pump();

    expect(find.text('Pixel 9'), findsNothing);
    expect(find.text('iPhone 12 mini'), findsOneWidget);
  });

  testWidgets('shows no device once the login it was for is gone', (tester) async {
    await tester.pumpWidget(wrap());

    cubit.loginDeviceLimitBack();
    await tester.pump();

    expect(find.byType(SessionTile), findsNothing);
  });
}
