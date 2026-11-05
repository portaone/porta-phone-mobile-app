import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

import '../../helpers/helpers.dart';
import '../../helpers/screen_presets.dart';
import 'login_harness.dart';

// A brand's dialing note, as one ships it in place of a greeting.
const _note =
    'NOTE: To make an Xphone-to-Xphone call, start dialing with 234. To make an Xphone to regular network '
    'call, start dialing with 0. To top up your account, change password, or roam for international calling, '
    'use Command App.';

const _signUp = LoginDefaultModeAction(titleL10n: 'login_Button_signUpToDemoInstance', flavor: LoginFlavor.login);

/// The landing with the greeting's route over it, as the app declares it.
class _Router extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: WatchTextScreenPageRoute.page),
    AutoRoute(
      page: PageInfo(
        'Landing',
        builder: (_) => const LoginModeSelectScreen(appGreetingL10n: _note, launchButtons: [_signUp]),
      ),
      initial: true,
    ),
  ];
}

void main() {
  late LoginHarness harness;

  setUp(() => harness = LoginHarness());

  // A branded build: its core is fixed, so the landing has no custom sign-in.
  setUp(() => EnvironmentConfig.applyOverrides({EnvironmentConfig.CORE_URL__NAME: 'https://core.example.com'}));

  tearDown(() async {
    EnvironmentConfig.clearOverrides();
    await harness.release();
  });

  Future<void> landing(WidgetTester tester, ScreenPreset preset) async {
    preset.apply(tester);
    final router = _Router();
    await tester.pumpWidget(
      harness.wrap(
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
    await tester.pumpAndSettle();
  }

  Finder noteText() => find.byWidgetPredicate((widget) => widget is Text && widget.data == _note);

  // The faces the note does not fit whole at the small size.
  for (final preset in watchPresets.where((preset) => preset.size.width < 300)) {
    testWidgets('on $preset it opens whole from its first lines and goes back to the landing', (tester) async {
      await landing(tester, preset);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.byKey(loginModeScreenSignUpButtonKey), findsNothing);
      expect(find.byType(WatchTextScreen), findsOneWidget);
      final whole = tester.widget<Text>(noteText());
      expect(whole.maxLines, isNull);
      expect(whole.style?.fontSize, 13);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(WatchTextScreen), findsNothing);
      expect(find.byKey(loginModeScreenSignUpButtonKey), findsOneWidget);
    });

    testWidgets('on $preset a second tap does not stack the text twice', (tester) async {
      await landing(tester, preset);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.chevron_right), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(WatchTextScreen), findsNothing);
    });

    testWidgets('on $preset a greeting cut short opens whole through semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await landing(tester, preset);

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await tapViaSemantics(tester, find.bySemanticsIdentifier(loginModeScreenGreetingId));
      await tester.pumpAndSettle();

      expect(find.byType(WatchTextScreen), findsOneWidget);
      expect(find.byKey(loginModeScreenGreetingKey), findsNothing);
      handle.dispose();
    });
  }
}
