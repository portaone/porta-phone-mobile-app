import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/models/models.dart';

import '../../helpers/screen_presets.dart';
import 'main_shell_harness.dart';

void main() {
  setUpAll(registerHarnessFallbacks);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<MainShellHarness> open(WidgetTester tester) async {
    watchPresets.first.apply(tester);
    final appTime = await AppTime.init();
    final harness = MainShellHarness(initialSupported: ['extensions']);
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.build(appTime));
    await settle(tester);
    return harness;
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await settle(tester);
  }

  // Unmounted while the test is alive, so the shell cancels its timers.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 5));
    }
  }

  testWidgets('the app starts on a section, as a phone does, and back goes to the hub', (tester) async {
    await open(tester);
    expect(find.byType(MainHub), findsNothing);

    await back(tester);
    expect(find.byType(MainHub), findsOneWidget);

    await close(tester);
  });

  testWidgets('a section opens from the hub and keeps what it holds across a trip back', (tester) async {
    final harness = await open(tester);
    final keypad = find.byKey(
      harness.initialFeatureAccess.bottomMenuConfig.tabs.whereType<KeypadBottomMenuTab>().single.navBarKey,
    );
    await back(tester);

    await tester.tap(keypad);
    await settle(tester);
    expect(find.byType(MainHub), findsNothing);
    final section = tester.element(find.byType(KeypadScreenPage));

    await back(tester);
    expect(find.byType(MainHub), findsOneWidget);
    expect(find.byType(KeypadScreenPage), findsNothing);

    await tester.tap(keypad);
    await settle(tester);
    expect(tester.element(find.byType(KeypadScreenPage)), same(section), reason: 'the tab stays built under the hub');

    await close(tester);
  });

  testWidgets('back on the hub leaves the app', (tester) async {
    final harness = await open(tester);
    await back(tester);

    expect(await harness.appRouter.topMostRouter().maybePop<void>(), isFalse);

    await close(tester);
  });

  testWidgets('a section opened from elsewhere shows on the face', (tester) async {
    final harness = await open(tester);

    await back(tester);

    await harness.appRouter.navigate(const MainScreenPageRoute(children: [KeypadScreenPageRoute()]));
    await settle(tester);

    expect(find.byType(MainHub), findsNothing);
    expect(find.byType(KeypadScreenPage), findsOneWidget);

    await close(tester);
  });
}
