import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/features/login/login.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../../helpers/screen_presets.dart';
import 'login_harness.dart';

class _MockLoginCubit extends MockCubit<LoginState> implements LoginCubit {}

/// The sign-in routes as the app declares them, over a page to go back to.
class _Router extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: LoginCoreUrlAssignScreenPageRoute.page, initial: true),
    AutoRoute(
      page: LoginSwitchScreenPageRoute.page,
      children: [
        AutoRoute(page: LoginWaysInScreenPageRoute.page),
        AutoRoute(page: LoginPasswordSigninScreenPageRoute.page),
        AutoRoute(page: LoginQrSigninScreenPageRoute.page),
      ],
    ),
  ];
}

void main() {
  const password = LoginType.passwordSignin;
  const qr = LoginType.qrSignin;

  Future<_Router> pump(WidgetTester tester, List<LoginType> supported, {bool processing = false}) async {
    watchPresets.first.apply(tester);
    final cubit = _MockLoginCubit();
    whenListen(cubit, const Stream<LoginState>.empty(), initialState: LoginState(processing: processing));
    when(() => cubit.isDemoModeEnabled).thenReturn(false);

    final router = _Router();
    await tester.pumpWidget(
      LoginHarness.wrapCubit(
        cubit,
        Builder(
          builder: (context) => MaterialApp.router(
            theme: Theme.of(context),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router.config(),
          ),
        ),
      ),
    );
    // Not awaited: a push completes when the page is popped.
    unawaited(router.push(LoginSwitchScreenPageRoute(bodySafeAreaSides: const {}, forceLoginTypes: supported)));
    // A form in flight spins for ever, so a fixed wait instead of settling.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return router;
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  // Two ways in that need no more routes than the one under test: QR is never
  // offered on a watch, so with password the grid has something to lead with.
  const leadsWithQr = [qr, password];

  testWidgets('a way a watch lacks at the front opens on the grid, not its form', (tester) async {
    await pump(tester, leadsWithQr);

    expect(find.byType(LoginWaysIn), findsOneWidget);
    expect(find.byType(LoginQrSigninScreen), findsNothing);
  });

  testWidgets('choosing one opens its form, and back returns to the grid', (tester) async {
    await pump(tester, leadsWithQr);

    await tester.tap(find.byKey(password.toLoginSegmentKey()));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPasswordSigninScreen), findsOneWidget);

    await back(tester);
    expect(find.byType(LoginWaysIn), findsOneWidget);
    expect(find.byType(LoginPasswordSigninScreen), findsNothing);
  });

  testWidgets('back from the grid leaves the ways in', (tester) async {
    final router = await pump(tester, leadsWithQr);

    await back(tester);

    expect(router.topRoute.name, LoginCoreUrlAssignScreenPageRoute.name);
  });

  testWidgets('with a single way in the form opens directly and back leaves it', (tester) async {
    final router = await pump(tester, const [password]);
    expect(find.byType(LoginPasswordSigninScreen), findsOneWidget);
    expect(find.byType(LoginWaysIn), findsNothing);

    await back(tester);

    expect(router.topRoute.name, LoginCoreUrlAssignScreenPageRoute.name);
  });

  testWidgets('while a request is in flight back keeps a single way in', (tester) async {
    await pump(tester, const [password], processing: true);

    await back(tester);

    expect(find.byType(LoginPasswordSigninScreen), findsOneWidget);
  });

  testWidgets('while a request is in flight back keeps a form behind the grid', (tester) async {
    await pump(tester, leadsWithQr, processing: true);
    await tester.tap(find.byKey(password.toLoginSegmentKey()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await back(tester);

    expect(find.byType(LoginPasswordSigninScreen), findsOneWidget);
    expect(find.byType(LoginWaysIn), findsNothing);
  });
}
