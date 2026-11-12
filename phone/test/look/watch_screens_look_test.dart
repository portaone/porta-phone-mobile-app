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
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/features/contacts_agreement/contacts_agreement.dart';
import 'package:webtrit_phone/features/login/login.dart';
import 'package:webtrit_phone/features/main/main.dart';
import 'package:webtrit_phone/features/permissions/permissions.dart';
import 'package:webtrit_phone/features/permissions/widgets/permission_tips.dart';
import 'package:webtrit_phone/features/session_status/session_status.dart';
import 'package:webtrit_phone/features/user_agreement/user_agreement.dart';
import 'package:webtrit_phone/models/models.dart';

import '../features/consent_harness.dart';
import '../features/call/view/call_active_scaffold_harness.dart';
import '../features/call/widgets/call_watch_harness.dart';
import '../features/keypad/keypad_harness.dart';
import '../features/login/login_harness.dart';
import '../helpers/look.dart';
import '../helpers/screen_presets.dart';
import '../helpers/shipped_theme.dart';
import '../helpers/stack_router.dart';

class _MockLoginCubit extends MockCubit<LoginState> implements LoginCubit {}

class _MockCallBloc extends MockBloc<CallEvent, CallState> implements CallBloc {}

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

  // Ways in and the forms
  for (final (name, types) in [
    ('ways-in', const [LoginType.passwordSignin, LoginType.otpSignin, LoginType.signup]),
    ('ways-in_two', const [LoginType.passwordSignin, LoginType.otpSignin]),
  ]) {
    looks(name, (_) async {
      final harness = LoginHarness();
      addTearDown(harness.release);
      return harness.wrap(
        LoginSwitchWatch(
          body: LoginTypeSelectScreen(supportedLoginTypes: types, onChosen: (_) {}),
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

  // Consent
  Widget consent(Widget screen) => ConsentHarness().wrap(screen);
  const terms = UserAgreementScreen(appTermsAndConditionsUrl: 'https://example.com/terms', appName: 'PortaPhone');
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

  // Call
  final callActive = watchActiveCall();
  final callHeld = watchActiveCall(callId: 'held', name: 'Anna Ross', held: true);
  final callRinging = makeCall(
    callId: 'ringing',
    processingStatus: CallProcessingStatus.incomingFromOffer,
    displayName: 'Thomas Anderson',
  );
  final callOutgoing = makeCall(
    callId: 'outgoing',
    direction: CallDirection.outgoing,
    processingStatus: CallProcessingStatus.outgoingRinging,
    displayName: 'Thomas Anderson',
  );
  final legA = watchActiveCall(callId: 'a');
  final legB = watchActiveCall(callId: 'b', name: 'Anna Ross');
  const room = ConferenceState(phase: ConferencePhase.active, legs: {'a': 0, 'b': 1});
  const conferences = CallCapabilitiesConfig(isConferenceEnabled: true);

  Widget call(Widget face) => withShippedTheme(CallWatchBackground(child: CallWatchRouter(child: face)));
  Future<void> tapIcon(WidgetTester tester, IconData icon) async {
    await tester.ensureVisible(find.byIcon(icon));
    await tester.tap(find.byIcon(icon));
    await tester.pumpAndSettle();
  }

  looks('call_incoming', (_) async => call(callWatchFace(calls: [callRinging], sent: CallWatchSent())));
  looks(
    'call_incoming_over-a-call',
    (_) async => call(callWatchFace(calls: [callActive, callRinging], focused: callRinging, sent: CallWatchSent())),
  );
  looks('call_outgoing', (_) async => call(callWatchFace(calls: [callOutgoing], sent: CallWatchSent())));
  looks('call_active', (_) async => call(callWatchFace(calls: [callActive], sent: CallWatchSent())));
  looks(
    'call_active_muted',
    (_) async => call(callWatchFace(calls: [callActive.copyWith(muted: true)], sent: CallWatchSent())),
  );
  looks('call_held', (_) async => call(callWatchFace(calls: [callHeld], sent: CallWatchSent())));
  looks(
    'call_bluetooth',
    (_) async => call(
      callWatchFace(
        calls: [callActive],
        devices: const [watchBuds, watchEarpiece, watchSpeaker],
        audioDevice: watchBuds,
        sent: CallWatchSent(),
      ),
    ),
  );
  looks(
    'call_more',
    (_) async => call(callWatchFace(calls: [callActive, callHeld], callConfig: conferences, sent: CallWatchSent())),
    act: (tester) async => tapIcon(tester, Icons.more_horiz),
  );
  looks(
    'call_audio',
    (_) async => call(
      callWatchFace(
        calls: [callActive],
        devices: const [watchBuds, watchEarpiece, watchSpeaker],
        audioDevice: watchBuds,
        sent: CallWatchSent(),
      ),
    ),
    act: (tester) async => tapIcon(tester, Icons.bluetooth_audio),
  );
  looks(
    'call_transfer',
    (_) async => call(callWatchFace(calls: [callActive], sent: CallWatchSent())),
    act: (tester) async {
      await tapIcon(tester, Icons.more_horiz);
      await tapIcon(tester, Icons.phone_forwarded);
    },
  );
  looks(
    'call_calls',
    (_) async => call(callWatchFace(calls: [callActive, callHeld], callConfig: conferences, sent: CallWatchSent())),
    act: (tester) async {
      await tapIcon(tester, Icons.more_horiz);
      await tapIcon(tester, Icons.call_split);
    },
  );
  looks(
    'call_conference',
    (_) async =>
        call(callWatchFace(calls: [legA, legB], callConfig: conferences, conference: room, sent: CallWatchSent())),
    act: (tester) async {
      await tapIcon(tester, Icons.more_horiz);
      await tapIcon(tester, Icons.groups);
    },
  );
  looks(
    'call_participant',
    (_) async =>
        call(callWatchFace(calls: [legA, legB], callConfig: conferences, conference: room, sent: CallWatchSent())),
    act: (tester) async {
      await tapIcon(tester, Icons.more_horiz);
      await tapIcon(tester, Icons.groups);
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anna Ross'));
      await tester.pumpAndSettle();
    },
  );
  looks('call_keypad', (_) async => call(callWatchFace(calls: [callActive], keypadShown: true, sent: CallWatchSent())));

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
  CallBloc calls(CallState state) {
    final bloc = _MockCallBloc();
    whenListen(bloc, const Stream<CallState>.empty(), initialState: state);
    return bloc;
  }

  Widget hub({CallState callState = const CallState(), DestinationPickPurpose? pickPurpose}) {
    final sessionStatus = _MockSessionStatusCubit();
    when(() => sessionStatus.state).thenReturn(const SessionStatusState());
    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionStatusCubit>.value(value: sessionStatus),
        BlocProvider<CallBloc>.value(value: calls(callState)),
      ],
      child: withShippedTheme(
        withRootStackRouter(
          Builder(
            builder: (context) => Scaffold(
              body: MainHub(
                tabs: tabs,
                onChosen: (_) {},
                decorateTabIcon: (tab, icon) => switch (tab) {
                  MessagingBottomMenuTab() => Badge(label: const Text('3'), child: icon),
                  RecentsBottomMenuTab() => Badge(label: const Text('2'), child: icon),
                  _ => icon,
                },
                pick: MainScreenPick.of(context, pickPurpose, pickPurpose == null ? null : () {}),
              ),
            ),
          ),
        ),
      ),
    );
  }

  looks('hub', (_) async => hub());
  looks('hub_in-call', (_) async => hub(callState: CallState(activeCalls: [watchActiveCall()], minimized: true)));
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
