// The watch screens in their states, as pictures in build/look/ - see
// test/helpers/look.dart. LOOK=1 fvm flutter test test/look --update-goldens
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' show SessionOtpProvisional;

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/features/contacts_agreement/contacts_agreement.dart';
import 'package:webtrit_phone/features/login/login.dart';
import 'package:webtrit_phone/features/main/main.dart';
import 'package:webtrit_phone/features/permissions/permissions.dart';
import 'package:webtrit_phone/features/permissions/widgets/permission_tips.dart';
import 'package:webtrit_phone/features/session_status/session_status.dart';
import 'package:webtrit_phone/features/user_agreement/user_agreement.dart';
import 'package:webtrit_phone/models/models.dart';

import '../features/consent_harness.dart';
import '../features/keypad/keypad_harness.dart';
import '../features/login/login_harness.dart';
import '../helpers/look.dart';
import '../helpers/screen_presets.dart';
import '../helpers/shipped_theme.dart';
import '../helpers/stack_router.dart';

class _MockLoginCubit extends MockCubit<LoginState> implements LoginCubit {}

const _signUp = LoginDefaultModeAction(titleL10n: 'login_Button_signUpToDemoInstance', flavor: LoginFlavor.login);

void main() {
  setUpAll(() async {
    if (lookRequested) await loadRealFonts();
  });
  tearDown(EnvironmentConfig.clearOverrides);

  /// One picture per watch preset, named `<screen>_<state>_<preset width>`.
  void looks(
    String name,
    Future<Widget> Function(WidgetTester tester) build, {
    Future<void> Function(WidgetTester)? act,
  }) {
    for (final preset in watchPresets) {
      testWidgets('look $name on $preset', skip: lookSkipReason != null, (tester) async {
        preset.apply(tester);
        await pumpCollectingOverflows(tester, await build(tester));
        await act?.call(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await lookAt('${name}_${preset.size.width.round()}');
      });
    }
  }

  Widget withLoginCubit(LoginCubit cubit, Widget screen) => LoginHarness.wrapCubit(cubit, screen);

  _MockLoginCubit mockLogin(LoginState state) {
    final cubit = _MockLoginCubit();
    whenListen(cubit, const Stream<LoginState>.empty(), initialState: state);
    when(() => cubit.isDemoModeEnabled).thenReturn(false);
    return cubit;
  }

  // Taken as each picture is built, so every run shows the full countdown.
  (SessionOtpProvisional, DateTime) otpSession() => (const SessionOtpProvisional(otpId: 'otp'), DateTime.now());

  // Landing
  looks('landing', (_) async {
    EnvironmentConfig.applyOverrides({EnvironmentConfig.CORE_URL__NAME: 'https://core.example.com'});
    final harness = LoginHarness();
    addTearDown(harness.release);
    return harness.wrap(const LoginModeSelectScreen(appGreetingL10n: 'WebTrit', launchButtons: [_signUp]));
  });
  looks('landing_long-title', (_) async {
    EnvironmentConfig.applyOverrides({EnvironmentConfig.CORE_URL__NAME: 'https://core.example.com'});
    final harness = LoginHarness();
    addTearDown(harness.release);
    return harness.wrap(
      const LoginModeSelectScreen(
        appGreetingL10n: 'Vitel Wireless Xphone',
        launchButtons: [
          LoginDefaultModeAction(titleL10n: 'Sign up with your company account', flavor: LoginFlavor.login),
        ],
      ),
    );
  });
  looks('landing_signing-in', (_) async {
    EnvironmentConfig.applyOverrides({EnvironmentConfig.CORE_URL__NAME: 'https://core.example.com'});
    return withLoginCubit(
      mockLogin(const LoginState(processing: true)),
      const LoginModeSelectScreen(appGreetingL10n: 'WebTrit', launchButtons: [_signUp]),
    );
  });
  looks('landing_demo-build', (_) async {
    final harness = LoginHarness();
    addTearDown(harness.release);
    return harness.wrap(const LoginModeSelectScreen(appGreetingL10n: 'WebTrit', launchButtons: [_signUp]));
  });

  // Custom core
  looks('core-url', (_) async {
    final harness = LoginHarness();
    addTearDown(harness.release);
    return harness.wrap(const LoginCoreUrlAssignScreen());
  });
  looks('core-url_unreachable', (_) async {
    return withLoginCubit(
      mockLogin(
        LoginState(coreUrlInput: const UrlInput.dirty('https://cloud.exmple.com'), coreUrlAssignError: Exception()),
      ),
      const LoginCoreUrlAssignScreen(),
    );
  });

  // Ways in and the forms
  for (final (name, types) in [
    ('ways-in', const [LoginType.passwordSignin, LoginType.otpSignin, LoginType.signup]),
    ('ways-in_two', const [LoginType.passwordSignin, LoginType.otpSignin]),
  ]) {
    looks(name, (_) async {
      final harness = LoginHarness();
      addTearDown(harness.release);
      return harness.wrap(
        LoginSwitchScreen(
          appBar: null,
          header: null,
          body: const SizedBox.shrink(),
          currentLoginType: types.first,
          supportedLoginTypes: types,
          onLoginTypeChanged: (_) {},
        ),
      );
    });
  }
  for (final (name, screen) in [
    ('otp-request', const LoginOtpSigninRequestScreen()),
    ('password', const LoginPasswordSigninScreen()),
    ('signup-request', const LoginSignupRequestScreen()),
  ]) {
    looks('form_$name', (_) async {
      final harness = LoginHarness();
      addTearDown(harness.release);
      return harness.wrap(Scaffold(body: screen));
    });
  }
  looks('form_password-filled', (_) async {
    return withLoginCubit(
      mockLogin(
        const LoginState(
          passwordSigninUserRefInput: UserRefInput.dirty('555004'),
          passwordSigninPasswordInput: PasswordInput.dirty('secret1'),
        ),
      ),
      const Scaffold(body: LoginPasswordSigninScreen()),
    );
  });
  looks('form_otp-code', (_) async {
    return withLoginCubit(
      mockLogin(LoginState(otpSigninSessionOtpProvisionalWithDateTime: otpSession())),
      const Scaffold(body: LoginOtpSigninVerifyScreen()),
    );
  });
  looks('form_signup-code', (_) async {
    return withLoginCubit(
      mockLogin(LoginState(signupSessionOtpProvisionalWithDateTime: otpSession())),
      const Scaffold(body: LoginSignupVerifyScreen(bodySafeAreaSides: {})),
    );
  });

  // Consent
  Widget consent(Widget screen) => ConsentHarness().wrap(screen);
  const terms = UserAgreementScreen(appTermsAndConditionsUrl: 'https://example.com/terms', appName: 'WebTrit');
  looks('terms', (_) async => consent(terms));
  looks(
    'terms_accepted',
    (_) async => consent(terms),
    act: (tester) async {
      await tester.tap(find.byKey(userAgreementCheckboxKey));
      await tester.pump();
    },
  );
  looks('contacts-consent', (_) async => consent(const ContactsAgreementScreen()));
  looks(
    'contacts-consent_end',
    (_) async => consent(const ContactsAgreementScreen()),
    act: (tester) async {
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
    },
  );
  looks('permissions', (_) async => consent(const PermissionsScreen()));
  looks(
    'permission-tips',
    (_) async => consent(
      PermissionTips(
        title: 'Manage Full-Screen Notification Permissions',
        instruction: const ['Open the app settings', 'Allow full-screen notifications'],
        onGoToAppSettings: () {},
        onPop: () {},
        note: 'You can continue without this.',
        dismissLabel: 'Not now',
      ),
    ),
  );

  // Main screen and keypad
  const tabs = <BottomMenuTab>[
    RecentsBottomMenuTab(
      supportsCallHistory: false,
      enabled: true,
      initial: false,
      titleL10n: 'main_BottomNavigationBarItemLabel_recents',
      icon: Icons.history,
    ),
    FavoritesBottomMenuTab(
      enabled: true,
      initial: false,
      titleL10n: 'main_BottomNavigationBarItemLabel_contacts',
      icon: Icons.account_circle_outlined,
    ),
    KeypadBottomMenuTab(
      enabled: true,
      initial: true,
      titleL10n: 'main_BottomNavigationBarItemLabel_keypad',
      icon: Icons.dialpad,
    ),
    MessagingBottomMenuTab(
      enabled: true,
      initial: false,
      titleL10n: 'main_BottomNavigationBarItemLabel_chats',
      icon: Icons.chat_bubble_outline,
    ),
    VoicemailBottomMenuTab(
      enabled: true,
      initial: false,
      titleL10n: 'main_BottomNavigationBarItemLabel_voicemail',
      icon: Icons.voicemail,
    ),
  ];
  Widget hub({DestinationPickPurpose? pickPurpose}) {
    final sessionStatus = _MockSessionStatusCubit();
    when(() => sessionStatus.state).thenReturn(const SessionStatusState());
    return BlocProvider<SessionStatusCubit>.value(
      value: sessionStatus,
      child: withShippedTheme(
        withRootStackRouter(
          MainScreen(
            body: const SizedBox.shrink(),
            tabs: tabs,
            currentIndex: 2,
            onTabSelected: (_) {},
            decorateTabIcon: (tab, icon) => switch (tab) {
              MessagingBottomMenuTab() => Badge(label: const Text('3'), child: icon),
              RecentsBottomMenuTab() => Badge(label: const Text('2'), child: icon),
              _ => icon,
            },
            pickPurpose: pickPurpose,
            onCancelPick: pickPurpose == null ? null : () {},
          ),
        ),
      ),
    );
  }

  looks('hub', (_) async => hub());
  looks('hub_picking', (_) async => hub(pickPurpose: _LookPurpose()));

  Future<Widget> keypad(WidgetTester tester) async {
    final harness = KeypadHarness();
    addTearDown(harness.release);
    return withShippedTheme((harness.build() as MaterialApp).home!);
  }

  looks('keypad', keypad);
  looks(
    'keypad_typed',
    keypad,
    act: (tester) async {
      await tester.longPress(find.bySemanticsIdentifier(keypadKeyId('0')));
      for (final digit in '12025550142'.split('')) {
        await tester.tap(find.bySemanticsIdentifier(keypadKeyId(digit)));
      }
      await tester.pump(const Duration(milliseconds: 300));
    },
  );
}

class _MockSessionStatusCubit extends MockCubit<SessionStatusState> implements SessionStatusCubit {}

class _LookPurpose implements DestinationPickPurpose {
  @override
  String get announcement => 'Choose who to transfer the call to';

  @override
  bool offeredBy(MainFlavor flavor) => true;

  @override
  bool accepts(DestinationCandidate candidate) => true;

  @override
  bool get closedByChoice => true;

  @override
  DestinationPickPrecedence get precedence => DestinationPickPrecedence.ordinary;

  @override
  bool get cancellable => true;

  @override
  IconData get pickIcon => Icons.phone_forwarded;

  @override
  String pickLabel(DestinationCandidate candidate) => 'Transfer to ${candidate.number}';

  @override
  void submit(DestinationCandidate candidate) {}
}
