import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' show SessionOtpProvisional;

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/login/login.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/screen_presets.dart';
import 'login_harness.dart';

class _MockLoginCubit extends MockCubit<LoginState> implements LoginCubit {}

void main() {
  late LoginHarness harness;

  setUp(() => harness = LoginHarness());
  tearDown(() => harness.release());

  // The forms as the sign-in flow shows them: inside a scaffold, below the
  // ways in.
  Widget form(Widget screen) => harness.wrap(Scaffold(body: screen));

  // The code forms read the session the request opened, so they stand on a
  // cubit already in that state.
  Widget formInState(LoginState state, Widget screen) {
    final cubit = _MockLoginCubit();
    whenListen(cubit, const Stream<LoginState>.empty(), initialState: state);
    when(() => cubit.isDemoModeEnabled).thenReturn(false);
    return LoginHarness.wrapCubit(cubit, Scaffold(body: screen));
  }

  // A code sent just now, so Resend shows its longest label, the countdown.
  (SessionOtpProvisional, DateTime) otpSession() => (const SessionOtpProvisional(otpId: 'otp'), DateTime.now());

  final forms = <String, (Widget Function(), Key)>{
    'OTP request': (() => form(const LoginOtpSigninRequestScreen()), otpButtonKey),
    'OTP code': (
      () => formInState(
        LoginState(otpSigninSessionOtpProvisionalWithDateTime: otpSession()),
        const LoginOtpSigninVerifyScreen(),
      ),
      otpVerifyButtonKey,
    ),
    'password sign-in': (() => form(const LoginPasswordSigninScreen()), passwordButtonKey),
    'sign-up request': (() => form(const LoginSignupRequestScreen()), signupEmailButtonKey),
    'sign-up code': (
      () => formInState(
        LoginState(signupSessionOtpProvisionalWithDateTime: otpSession()),
        const LoginSignupVerifyScreen(bodySafeAreaSides: {}),
      ),
      signupVerifyButtonKey,
    ),
  };

  for (final MapEntry(key: name, value: (screen, buttonKey)) in forms.entries) {
    group('the $name form', () {
      for (final preset in allScreenPresets) {
        testWidgets('fits on $preset', (tester) async {
          preset.apply(tester);

          expect(await pumpCollectingOverflows(tester, screen()), isEmpty);
        });
      }

      for (final preset in watchPresets) {
        testWidgets('on $preset has its main button along the bottom of the face', (tester) async {
          preset.apply(tester);
          await pumpCollectingOverflows(tester, screen());

          expect(find.byType(WatchEdgeButton), findsOneWidget);
          final button = tester.getRect(find.byKey(buttonKey));
          expect(button.bottom, closeTo(preset.size.height, 6));
          expect(button.height, greaterThanOrEqualTo(kMinInteractiveDimension));
        });
      }

      testWidgets('keeps the phone arrangement on a phone', (tester) async {
        handsetPresets.first.apply(tester);
        await pumpCollectingOverflows(tester, screen());

        expect(find.byType(WatchEdgeButton), findsNothing);
      });
    });
  }

  group('the ways in on a watch', () {
    LoginType? chosen;

    Widget ways(List<LoginType> supported, {bool processing = false, bool handled = true}) {
      chosen = null;
      return LoginSwitchScreen(
        appBar: null,
        header: null,
        body: const Text('the form', key: Key('form')),
        currentLoginType: supported.first,
        supportedLoginTypes: supported,
        onLoginTypeChanged: handled ? (type) => chosen = type : null,
        processing: processing,
      );
    }

    Widget switchScreen(List<LoginType> supported, {bool handled = true}) =>
        harness.wrap(ways(supported, handled: handled));

    // A page under the ways in, so leaving them shows on the navigator.
    Widget pushedOver(Widget screen) => harness.wrap(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen)),
          child: const Text('push'),
        ),
      ),
    );

    const all = [LoginType.passwordSignin, LoginType.otpSignin, LoginType.signup];

    for (final preset in watchPresets) {
      testWidgets('on $preset are a grid, each with the id of its phone segment', (tester) async {
        final handle = tester.ensureSemantics();
        preset.apply(tester);

        expect(await pumpCollectingOverflows(tester, switchScreen(all)), isEmpty);
        expect(find.byType(SegmentedButton<LoginType>), findsNothing);
        expect(find.byKey(const Key('form')), findsNothing, reason: 'the grid comes first');
        for (final type in all) {
          await tester.scrollUntilVisible(find.byKey(type.toLoginSegmentKey()), 40);
          expect(find.bySemanticsIdentifier(type.toLoginSegmentId()), findsOneWidget);
        }

        handle.dispose();
      });
    }

    testWidgets('choosing one opens its form, and going back returns to the grid', (tester) async {
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(tester, switchScreen(all));

      await tester.tap(find.byKey(LoginType.otpSignin.toLoginSegmentKey()));
      await tester.pumpAndSettle();
      expect(chosen, LoginType.otpSignin);
      expect(find.byKey(const Key('form')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('form')), findsNothing);
      expect(find.byKey(LoginType.passwordSignin.toLoginSegmentKey()), findsOneWidget);
    });

    testWidgets('QR sign-in is not offered: a watch has no camera', (tester) async {
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(tester, switchScreen(const [...all, LoginType.qrSignin]));

      expect(find.byKey(LoginType.qrSignin.toLoginSegmentKey()), findsNothing);
      expect(find.byKey(LoginType.passwordSignin.toLoginSegmentKey()), findsOneWidget);
    });

    testWidgets('a brand that leads with QR still opens on the grid, not on the QR form', (tester) async {
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(tester, switchScreen(const [LoginType.qrSignin, LoginType.passwordSignin]));

      expect(find.byKey(const Key('form')), findsNothing);
      expect(find.byKey(LoginType.passwordSignin.toLoginSegmentKey()), findsOneWidget);
    });

    testWidgets('while a request is in flight going back keeps the form', (tester) async {
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(tester, pushedOver(ways(all, processing: true)));
      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(LoginType.otpSignin.toLoginSegmentKey()));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('form')), findsOneWidget);
    });

    testWidgets('while a request is in flight a single way in does not leave', (tester) async {
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(tester, pushedOver(ways(const [LoginType.passwordSignin], processing: true)));
      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('form')), findsOneWidget);
    });

    testWidgets('without a handler the ways in are disabled', (tester) async {
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(tester, switchScreen(all, handled: false));

      await tester.tap(find.byKey(LoginType.otpSignin.toLoginSegmentKey()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('form')), findsNothing);
    });

    testWidgets('with a single way in the form opens directly', (tester) async {
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(tester, switchScreen(const [LoginType.passwordSignin]));

      expect(find.byKey(const Key('form')), findsOneWidget);
    });
  });
}
