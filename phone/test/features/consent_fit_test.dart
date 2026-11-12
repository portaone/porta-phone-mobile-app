import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/contacts_agreement/contacts_agreement.dart';
import 'package:webtrit_phone/features/permissions/permissions.dart';
import 'package:webtrit_phone/features/permissions/widgets/permission_tips.dart';
import 'package:webtrit_phone/features/user_agreement/user_agreement.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../helpers/screen_presets.dart';
import 'consent_harness.dart';

void main() {
  late ConsentHarness harness;

  setUp(() => harness = ConsentHarness());

  Widget wrap(Widget screen) => harness.wrap(screen);

  final screens = <String, (Widget, Key)>{
    'terms': (
      const UserAgreementScreen(appTermsAndConditionsUrl: 'https://example.com/terms', appName: 'PortaPhone'),
      userAgreementAcceptButtonKey,
    ),
    'contacts consent': (const ContactsAgreementScreen(), contactsAgreementAcceptButtonKey),
    'permissions': (const PermissionsScreen(), permissionsInitButtonKey),
    'permission tips': (
      PermissionTips(
        title: 'Manage Full-Screen Notification Permissions',
        instruction: const ['Open the settings', 'Allow full-screen notifications'],
        onGoToAppSettings: () {},
        onPop: () {},
        note: 'You can continue without this.',
        dismissLabel: 'Not now',
      ),
      permissionTipsButtonKey,
    ),
  };

  for (final MapEntry(key: name, value: (screen, _)) in screens.entries) {
    for (final preset in allScreenPresets) {
      testWidgets('the $name screen fits on $preset', (tester) async {
        preset.apply(tester);

        expect(await pumpCollectingOverflows(tester, wrap(screen)), isEmpty);
      });
    }

    for (final preset in watchPresets) {
      testWidgets('on $preset the $name screen has its main action along the bottom of the face', (tester) async {
        preset.apply(tester);
        await pumpCollectingOverflows(tester, wrap(screen));

        expect(find.byType(WatchEdgeButton), findsOneWidget);
      });
    }
  }

  for (final preset in watchPresets) {
    testWidgets('on $preset the terms consent is a toggle that enables Continue', (tester) async {
      preset.apply(tester);
      await pumpCollectingOverflows(tester, wrap(screens['terms']!.$1));

      final button = find.byKey(userAgreementAcceptButtonKey);
      expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
      // The test font is about twice as wide as a real one, so the label
      // wraps further here; what holds is that the toggle starts in view,
      // above the edge button, without scrolling.
      expect(
        tester.getRect(find.byKey(userAgreementCheckboxKey)).top,
        lessThan(tester.getRect(button).top - 24),
        reason: 'the consent comes before the terms link, in view',
      );

      // Its top, which is in view on every face; the rest may sit under the
      // edge button where the label wraps.
      await tester.tapAt(tester.getRect(find.byKey(userAgreementCheckboxKey)).topCenter + const Offset(0, 12));
      await tester.pump();
      expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
    });
  }

  for (final preset in watchPresets) {
    testWidgets('on $preset the contacts consent is in view beside Continue, which declines without it', (
      tester,
    ) async {
      preset.apply(tester);
      await pumpCollectingOverflows(tester, wrap(screens['contacts consent']!.$1));

      // Continue is always pressable and declines when the toggle is off, so
      // the toggle has to be seen with Continue, without scrolling. As above,
      // the test font wraps the label further than a real one does.
      final toggle = tester.getRect(find.byKey(contactsAgreementCheckboxKey));
      expect(toggle.top, lessThan(tester.getRect(find.byKey(contactsAgreementAcceptButtonKey)).top - 24));

      await tester.tapAt(toggle.topCenter + const Offset(0, 12));
      await tester.pump();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    testWidgets('on $preset the permission tips are left with the edge button, without scrolling', (tester) async {
      preset.apply(tester);
      await pumpCollectingOverflows(tester, wrap(screens['permission tips']!.$1));

      expect(
        find.descendant(of: find.byType(WatchEdgeButton), matching: find.byKey(permissionTipsButtonKey)),
        findsOneWidget,
      );
      expect(find.byKey(permissionTipsButtonKey).hitTestable(), findsOneWidget);
    });
  }

  testWidgets('the watch consent toggle is one node: its label, its state and the tap', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    await pumpCollectingOverflows(tester, wrap(screens['terms']!.$1));

    expect(
      tester.getSemantics(find.bySemanticsIdentifier(userAgreementCheckboxId)),
      isSemantics(
        label: 'I have read and accept the terms',
        identifier: userAgreementCheckboxId,
        hasToggledState: true,
        isToggled: false,
        hasTapAction: true,
      ),
    );

    handle.dispose();
  });
}
