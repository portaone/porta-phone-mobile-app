import 'package:flutter/material.dart' show Icons;
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

  test('a reload of the tabs leaves the person on the hub', () {
    const keypad = KeypadBottomMenuTab(enabled: true, initial: true, titleL10n: 'keypad', icon: Icons.dialpad);
    const favorites = FavoritesBottomMenuTab(enabled: true, initial: false, titleL10n: 'favorites', icon: Icons.star);

    int? reactivate(int? activeIndex) => BottomMenuTabHandler.reactivationIndex(
      previousTabs: const [favorites, keypad],
      previousPath: keypad.routePath,
      tabs: const [keypad, favorites],
      activeIndex: activeIndex,
    );

    expect(reactivate(1), 0, reason: 'a section is restored');
    expect(reactivate(null), isNull, reason: 'the hub is no section');
  });

  test('the positions of the sections shift by the hub and only on a watch', () {
    const phone = MainTabPositions(hasHub: false);
    const watch = MainTabPositions(hasHub: true);

    expect(phone.tabOf(2), 2);
    expect(phone.sectionOf(0), 0);
    expect(watch.tabOf(2), 3);
    expect(watch.sectionOf(3), 2);
    expect(watch.sectionOf(0), isNull, reason: 'the hub is no section');
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
