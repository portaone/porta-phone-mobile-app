import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/features/login/login.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/helpers.dart';
import '../../helpers/screen_presets.dart';
import 'login_harness.dart';

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
  late LoginHarness harness;

  setUp(() => harness = LoginHarness());

  // A branded build: its core is fixed, so the landing has no custom sign-in.
  setUp(() => EnvironmentConfig.applyOverrides({EnvironmentConfig.CORE_URL__NAME: 'https://core.example.com'}));

  tearDown(() async {
    EnvironmentConfig.clearOverrides();
    await harness.release();
  });

  // The landing as the shipped theme and config show it: the logo, the
  // greeting and the configured buttons.
  Widget landing({List<LoginModeAction> launchButtons = const [_signUp], String greeting = 'WebTrit'}) {
    return harness.wrap(LoginModeSelectScreen(appGreetingL10n: greeting, launchButtons: launchButtons));
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
        final title = find.descendant(of: find.byKey(loginModeScreenSignUpButtonKey), matching: find.byType(Text));
        final label = tester.getRect(title);
        expect(tester.widget<Text>(title).maxLines, 1, reason: 'the edge narrows with the face');
        expect(label.left, greaterThanOrEqualTo(button.left + 12), reason: 'it keeps off the curved sides');
        expect(label.right, lessThanOrEqualTo(button.right - 12));
        expect(label.bottom, lessThanOrEqualTo(button.bottom));

        // On a round face the ends of the line stay inside the circle, where
        // the rectangle of the button says nothing. Measured on the baseline
        // the glyphs and the ellipsis stand on: the empty corners of the line
        // box below it may touch the bezel.
        if (preset.size.width == preset.size.height) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: title, matching: find.byType(RichText)),
          );
          final painter = TextPainter(text: paragraph.text, textDirection: TextDirection.ltr, maxLines: 1)..layout();
          addTearDown(painter.dispose);
          final baseline = label.top + painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
          final radius = preset.size.width / 2;
          final center = Offset(radius, radius);
          for (final end in [Offset(label.left, baseline), Offset(label.right, baseline)]) {
            expect((end - center).distance, lessThanOrEqualTo(radius), reason: 'past the bezel at $end');
          }
        }
      });
    }
  });

  group('a doubled font scale', () {
    for (final preset in watchPresets) {
      testWidgets('on $preset the brand shrinks and the button keeps its size', (tester) async {
        preset.apply(tester);
        await pumpCollectingOverflows(tester, landing());
        final button = tester.getRect(find.byKey(loginModeScreenSignUpButtonKey));

        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        expect(await pumpCollectingOverflows(tester, landing()), isEmpty);
        expect(tester.getRect(find.byKey(loginModeScreenSignUpButtonKey)), button);
        final brand = tester.getRect(find.byType(FittedBox).first);
        expect(brand.bottom, lessThanOrEqualTo(button.top), reason: 'the brand stays above the button');
      });
    }
  });

  group('a greeting that is a paragraph', () {
    // A brand's dialing note, as one ships it in place of a greeting.
    const note =
        'NOTE: To make an Xphone-to-Xphone call, start dialing with 234. To make an Xphone to regular network '
        'call, start dialing with 0. To top up your account, change password, or roam for international calling, '
        'use Command App.';

    Finder noteText() => find.byWidgetPredicate((widget) => widget is Text && widget.data == note);

    for (final preset in watchPresets) {
      testWidgets('on $preset its first lines stay above the button at their own size', (tester) async {
        preset.apply(tester);

        expect(await pumpCollectingOverflows(tester, landing(greeting: note)), isEmpty);

        final button = tester.getRect(find.byKey(loginModeScreenSignUpButtonKey));
        expect(tester.getRect(noteText()).bottom, lessThanOrEqualTo(button.top));
        final text = tester.widget<Text>(noteText());
        expect(text.style?.fontSize, 11, reason: 'smaller than a greeting that fits');
        expect(text.maxLines, greaterThanOrEqualTo(3), reason: 'as many lines as the room holds');
        final brand = find.byType(FittedBox).first;
        final content = find.descendant(of: brand, matching: find.byType(ConstrainedBox)).first;
        expect(tester.getSize(content).height, tester.getSize(brand).height, reason: 'measured to fit, not shrunk');
      });

      testWidgets('on $preset it opens whole from its first lines and goes back to the landing', (tester) async {
        preset.apply(tester);
        await pumpCollectingOverflows(tester, landing(greeting: note));

        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();
        expect(find.byKey(loginModeScreenSignUpButtonKey), findsNothing);
        final whole = tester.widget<Text>(noteText());
        expect(whole.maxLines, isNull);
        expect(whole.style?.fontSize, 13);
        await tester.scrollUntilVisible(noteText(), 40);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(loginModeScreenSignUpButtonKey), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('on $preset assistive technology reads it whole', (tester) async {
        final handle = tester.ensureSemantics();
        preset.apply(tester);
        await pumpCollectingOverflows(tester, landing(greeting: note));

        expectTapTargetSemantics(
          tester,
          find.bySemanticsIdentifier(loginModeScreenGreetingId),
          label: note,
          identifier: loginModeScreenGreetingId,
        );
        handle.dispose();
      });

      testWidgets('on $preset a doubled font scale keeps the button and the face whole', (tester) async {
        preset.apply(tester);
        await pumpCollectingOverflows(tester, landing(greeting: note));
        final button = tester.getRect(find.byKey(loginModeScreenSignUpButtonKey));

        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        expect(await pumpCollectingOverflows(tester, landing(greeting: note)), isEmpty);
        expect(tester.getRect(find.byKey(loginModeScreenSignUpButtonKey)), button);
        expect(tester.getRect(noteText()).bottom, lessThanOrEqualTo(button.top));
      });

      testWidgets('on $preset a greeting that fits keeps its size and has no way on', (tester) async {
        preset.apply(tester);
        await pumpCollectingOverflows(tester, landing());

        final text = tester.widget<Text>(find.text('WebTrit'));
        expect(text.style?.fontSize, preset.size.width < 200 ? 16 : 18);
        expect(text.maxLines, isNull);
        expect(find.byIcon(Icons.chevron_right), findsNothing);
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
        expect(harness.cubit.isDemoModeEnabled, isTrue, reason: 'no core is configured, so this is a demo build');

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

        // Drawn in the colour the style gives what sits on the page, faded
        // whole - text and outline - while a sign-in is in progress.
        final context = tester.element(find.byKey(loginModeScreenUrlButtonKey));
        final color = Theme.of(context).extension<LoginModeSelectScreenStyles>()!.primary!.secondaryActionColor!;
        final style = tester.widget<OutlinedButton>(find.byKey(loginModeScreenUrlButtonKey)).style!;
        expect(style.foregroundColor!.resolve({}), color);
        final disabled = {WidgetState.disabled};
        expect(style.foregroundColor!.resolve(disabled), color.withValues(alpha: 0.38));
        expect(style.side!.resolve(disabled)!.color.a, lessThan(style.side!.resolve({})!.color.a));

        handle.dispose();
      });
    }
  });
}
