// The watch screens in their states, as pictures in build/look/ - see
// test/helpers/look.dart. LOOK=1 fvm flutter test test/look --update-goldens
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/features/login/login.dart';
import 'package:webtrit_phone/models/models.dart';

import '../features/login/login_harness.dart';
import '../helpers/look.dart';
import '../helpers/screen_presets.dart';

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
}
