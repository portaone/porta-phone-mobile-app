import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/notifications/notifications.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/features/login/login.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/helpers.dart';
import '../../helpers/screen_presets.dart';
import '../../helpers/shipped_theme.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAppInfo extends Mock implements AppInfo {}

class _MockPackageInfo extends Mock implements PackageInfo {}

const _signUp = LoginDefaultModeAction(titleL10n: 'login_Button_signUpToDemoInstance', flavor: LoginFlavor.login);

// A brand with every way in it can configure: its own sign-up and two
// embedded pages.
final _threeWaysIn = <LoginModeAction>[
  _signUp,
  LoginEmbeddedModeButton(
    titleL10n: 'Partner sign-up',
    flavor: LoginFlavor.embedded,
    customLoginFeature: EmbeddedData(
      id: 'partner',
      uri: Uri.parse('https://example.com/a'),
      reconnectStrategy: ReconnectStrategy.softReload,
    ),
  ),
  LoginEmbeddedModeButton(
    titleL10n: 'Reseller portal',
    flavor: LoginFlavor.embedded,
    customLoginFeature: EmbeddedData(
      id: 'reseller',
      uri: Uri.parse('https://example.com/b'),
      reconnectStrategy: ReconnectStrategy.softReload,
    ),
  ),
];

void main() {
  late NotificationsBloc notificationsBloc;
  late LoginCubit cubit;

  setUp(() {
    notificationsBloc = NotificationsBloc();

    final appInfo = _MockAppInfo();
    when(() => appInfo.version).thenReturn(Version.parse('1.0.0'));
    final packageInfo = _MockPackageInfo();
    when(() => packageInfo.version).thenReturn('1.0.0');
    when(() => packageInfo.buildNumber).thenReturn('1');

    cubit = LoginCubit(
      authRepository: _MockAuthRepository(),
      notificationsBloc: notificationsBloc,
      appInfo: appInfo,
      packageInfo: packageInfo,
      appCompatibilityResolver: const DefaultAppCompatibilityResolver(),
      onLoginSuccess: (_, _) {},
    );
  });

  // A branded build: its core is fixed, so the landing has no custom sign-in.
  setUp(() => EnvironmentConfig.applyOverrides({EnvironmentConfig.CORE_URL__NAME: 'https://core.example.com'}));

  tearDown(() {
    EnvironmentConfig.clearOverrides();
    cubit.close();
    notificationsBloc.close();
  });

  // The landing as the shipped theme and config show it: the logo, the
  // greeting and the configured buttons.
  Widget landing({List<LoginModeAction> launchButtons = const [_signUp]}) {
    return withShippedTheme(
      BlocProvider<LoginCubit>.value(
        value: cubit,
        child: LoginModeSelectScreen(appGreetingL10n: 'WebTrit', launchButtons: launchButtons),
      ),
    );
  }

  group('one way in', () {
    for (final preset in allScreenPresets) {
      testWidgets('the landing fits on $preset', (tester) async {
        preset.apply(tester);

        expect(await pumpCollectingOverflows(tester, landing()), isEmpty);
      });
    }

    for (final preset in watchPresets) {
      testWidgets('on $preset the button fills the bottom of the face', (tester) async {
        preset.apply(tester);
        await pumpCollectingOverflows(tester, landing());

        final button = tester.getRect(find.byKey(loginModeScreenSignUpButtonKey));
        expect(find.byType(WatchEdgeButton), findsOneWidget);
        expect(button.bottom, closeTo(preset.size.height, 6), reason: 'it rests on the bottom edge');
        expect(button.height, greaterThanOrEqualTo(kMinInteractiveDimension));
        expect(button.width, greaterThan(preset.size.width * 0.7), reason: 'it spans the face');
      });

      testWidgets('on $preset the button is the sign-up anchor automation finds', (tester) async {
        final handle = tester.ensureSemantics();
        preset.apply(tester);
        await pumpCollectingOverflows(tester, landing());

        expect(find.bySemanticsIdentifier(loginModeScreenId), findsOneWidget);
        expectTapTargetSemantics(
          tester,
          find.bySemanticsIdentifier(loginModeScreenSignUpButtonId),
          label: 'Sign up / sign in',
          identifier: loginModeScreenSignUpButtonId,
        );

        handle.dispose();
      });
    }

    for (final preset in [...handsetPresets, ...largePresets]) {
      testWidgets('on $preset the phone arrangement is kept', (tester) async {
        preset.apply(tester);
        await pumpCollectingOverflows(tester, landing());

        expect(find.byType(WatchEdgeButton), findsNothing);
        expect(find.byType(AppBar), findsOneWidget);
      });
    }
  });

  group('a long launch button title', () {
    const longTitle = LoginDefaultModeAction(
      titleL10n: 'Sign up with your company account today',
      flavor: LoginFlavor.login,
    );

    for (final preset in watchPresets) {
      testWidgets('on $preset it stays inside the edge button', (tester) async {
        preset.apply(tester);

        expect(await pumpCollectingOverflows(tester, landing(launchButtons: const [longTitle])), isEmpty);

        final button = tester.getRect(find.byKey(loginModeScreenSignUpButtonKey));
        final label = tester.getRect(
          find.descendant(of: find.byKey(loginModeScreenSignUpButtonKey), matching: find.byType(Text)),
        );
        expect(label.left, greaterThanOrEqualTo(button.left + 12), reason: 'it keeps off the curved sides');
        expect(label.right, lessThanOrEqualTo(button.right - 12));
        expect(label.bottom, lessThanOrEqualTo(button.bottom));
      });
    }
  });

  group('several ways in', () {
    for (final preset in allScreenPresets) {
      testWidgets('the landing fits on $preset', (tester) async {
        preset.apply(tester);

        expect(await pumpCollectingOverflows(tester, landing(launchButtons: _threeWaysIn)), isEmpty);
      });
    }

    for (final preset in watchPresets) {
      testWidgets('on $preset every way in can be scrolled to and tapped', (tester) async {
        preset.apply(tester);
        await pumpCollectingOverflows(tester, landing(launchButtons: _threeWaysIn));

        expect(find.byType(WatchEdgeButton), findsNothing);
        for (final title in ['Sign up / sign in', 'Partner sign-up', 'Reseller portal']) {
          final button = find.widgetWithText(ElevatedButton, title);
          await tester.scrollUntilVisible(button, 40);
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          final rect = tester.getRect(button);
          expect(rect.height, greaterThanOrEqualTo(kMinInteractiveDimension - 0.01), reason: title);
          expect(rect.top, greaterThanOrEqualTo(0), reason: title);
          expect(rect.bottom, lessThanOrEqualTo(preset.size.height), reason: title);
        }

        // Scrolled to the end, the last entry keeps clear of the face's edge.
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
        await tester.pumpAndSettle();
        final last = tester.getRect(find.widgetWithText(ElevatedButton, 'Reseller portal'));
        expect(last.bottom, lessThanOrEqualTo(preset.size.height - 8));
      });
    }
  });

  group('a demo build', () {
    setUp(EnvironmentConfig.clearOverrides);

    for (final preset in watchPresets) {
      testWidgets('on $preset the custom sign-in is a list entry automation finds', (tester) async {
        final handle = tester.ensureSemantics();
        preset.apply(tester);

        expect(await pumpCollectingOverflows(tester, landing()), isEmpty);
        expect(cubit.isDemoModeEnabled, isTrue, reason: 'no core is configured, so this is a demo build');

        final customSignIn = find.bySemanticsIdentifier(loginModeScreenUrlButtonId);
        await tester.scrollUntilVisible(find.byKey(loginModeScreenUrlButtonKey), 40);
        expectTapTargetSemantics(
          tester,
          customSignIn,
          label: 'Sign in to your Cloud Backend',
          identifier: loginModeScreenUrlButtonId,
        );
        // The face shows one short line; the full phrase is only the name.
        expect(find.text('Cloud Backend'), findsOneWidget);

        // Drawn in the greeting's colour, which the brand set against the
        // background this entry sits on - not in a colour meant for the
        // primary surface.
        final context = tester.element(find.byKey(loginModeScreenUrlButtonKey));
        final greetingColor = Theme.of(context)
            .extension<LoginModeSelectScreenStyles>()!
            .primary!
            .onboardingTextStyle!
            .textStyle!
            .color;
        final button = tester.widget<OutlinedButton>(find.byKey(loginModeScreenUrlButtonKey));
        expect(button.style!.foregroundColor!.resolve({}), greetingColor);

        handle.dispose();
      });
    }
  });
}
