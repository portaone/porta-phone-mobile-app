import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/login/login.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/screen_presets.dart';
import 'login_harness.dart';

void main() {
  late LoginHarness harness;

  setUp(() => harness = LoginHarness());
  tearDown(() => harness.release());

  for (final preset in allScreenPresets) {
    testWidgets('the custom-core screen fits on $preset', (tester) async {
      preset.apply(tester);

      expect(await pumpCollectingOverflows(tester, harness.wrap(const LoginCoreUrlAssignScreen())), isEmpty);
    });
  }

  for (final preset in watchPresets) {
    testWidgets('on $preset Proceed fills the bottom of the face, with no app bar', (tester) async {
      preset.apply(tester);
      await pumpCollectingOverflows(tester, harness.wrap(const LoginCoreUrlAssignScreen()));

      expect(find.byType(AppBar), findsNothing, reason: 'a watch goes back with a swipe');
      expect(find.byType(WatchEdgeButton), findsOneWidget);
      final button = tester.getRect(find.byKey(coreUrlButtonKey));
      expect(button.bottom, closeTo(preset.size.height, 6));
      expect(button.height, greaterThanOrEqualTo(kMinInteractiveDimension));
    });

    testWidgets('on $preset the field and Proceed are what automation finds', (tester) async {
      final handle = tester.ensureSemantics();
      preset.apply(tester);
      await pumpCollectingOverflows(tester, harness.wrap(const LoginCoreUrlAssignScreen()));

      expect(find.bySemanticsIdentifier(loginCoreUrlScreenId), findsOneWidget);
      expect(find.bySemanticsIdentifier(coreUrlInputId), findsOneWidget);
      // Proceed waits for a URL, as on the phone.
      expect(
        tester.getSemantics(find.bySemanticsIdentifier(coreUrlButtonId)),
        isSemantics(label: 'Proceed', identifier: coreUrlButtonId, hasTapAction: false),
      );

      handle.dispose();
    });
  }

  for (final preset in [...handsetPresets, ...largePresets]) {
    testWidgets('on $preset the phone arrangement is kept', (tester) async {
      preset.apply(tester);
      await pumpCollectingOverflows(tester, harness.wrap(const LoginCoreUrlAssignScreen()));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(WatchEdgeButton), findsNothing);
    });
  }
}
