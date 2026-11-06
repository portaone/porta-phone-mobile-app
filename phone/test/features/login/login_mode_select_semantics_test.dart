import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/login/login.dart';
import 'package:webtrit_phone/models/models.dart';

import '../../helpers/helpers.dart';
import '../../helpers/screen_presets.dart';
import 'login_harness.dart';

class _MockLoginCubit extends MockCubit<LoginState> implements LoginCubit {}

const _signUp = LoginDefaultModeAction(titleL10n: 'login_Button_signUpToDemoInstance', flavor: LoginFlavor.login);

void main() {
  _MockLoginCubit login({required bool demo}) {
    final cubit = _MockLoginCubit();
    whenListen(cubit, const Stream<LoginState>.empty(), initialState: const LoginState());
    when(() => cubit.isDemoModeEnabled).thenReturn(demo);
    return cubit;
  }

  Widget landing(LoginCubit cubit, {String greeting = 'WebTrit'}) =>
      LoginHarness.wrapCubit(cubit, LoginModeSelectScreen(appGreetingL10n: greeting, launchButtons: const [_signUp]));

  for (final preset in [...watchPresets, handsetPresets.first]) {
    testWidgets('on $preset the launch button acts through semantics', (tester) async {
      final handle = tester.ensureSemantics();
      preset.apply(tester);
      final cubit = login(demo: false);
      await pumpCollectingOverflows(tester, landing(cubit));

      await tapViaSemantics(tester, find.bySemanticsIdentifier(loginModeScreenSignUpButtonId));

      verify(() => cubit.loginModeSelectSubmitted(LoginMode.core)).called(1);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('on $preset the custom sign-in acts through semantics', (tester) async {
      final handle = tester.ensureSemantics();
      preset.apply(tester);
      final cubit = login(demo: true);
      await pumpCollectingOverflows(tester, landing(cubit));

      // The last entry of the list on a watch; in the app bar on a phone.
      if (watchPresets.contains(preset)) {
        await tester.scrollUntilVisible(find.byKey(loginModeScreenUrlButtonKey), 40);
        await tester.pumpAndSettle();
      }
      await tapViaSemantics(tester, find.bySemanticsIdentifier(loginModeScreenUrlButtonId));

      verify(() => cubit.loginModeSelectSubmitted(LoginMode.customCore)).called(1);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }

  // A wide face holds the note whole, with nothing to open.
  for (final preset in watchPresets.where((preset) => preset.size.width < 300)) {
    testWidgets('on $preset a greeting cut short opens whole through semantics', (tester) async {
      const note =
          'NOTE: To make an Xphone-to-Xphone call, start dialing with 234. To make an Xphone to regular network '
          'call, start dialing with 0. To top up your account, change password, or roam for international calling, '
          'use Command App.';
      final handle = tester.ensureSemantics();
      preset.apply(tester);
      await pumpCollectingOverflows(tester, landing(login(demo: false), greeting: note));

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await tapViaSemantics(tester, find.bySemanticsIdentifier(loginModeScreenGreetingId));

      expect(find.byKey(loginModeScreenSignUpButtonKey), findsNothing);
      expect(find.byKey(loginModeScreenGreetingKey), findsNothing);
      handle.dispose();
    });
  }
}
