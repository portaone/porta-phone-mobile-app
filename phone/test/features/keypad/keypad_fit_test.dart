import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/screen_presets.dart';
import 'keypad_harness.dart';

void main() {
  late KeypadHarness harness;

  setUp(() => harness = KeypadHarness());
  tearDown(() => harness.release());

  // The pad as the main screen holds it on a phone: under an app bar the body
  // is drawn behind, above the tabs. A watch has neither.
  Widget pad(ScreenPreset preset) => preset.formFactor == FormFactor.watch
      ? harness.build()
      : harness.build(
          appBar: AppBar(toolbarHeight: kToolbarHeight),
          bottomNavigationBar: const SizedBox(height: kBottomNavigationBarHeight),
        );

  for (final preset in allScreenPresets) {
    testWidgets('the pad fits on $preset', (tester) async {
      preset.apply(tester);

      expect(await pumpCollectingOverflows(tester, pad(preset)), isEmpty);

      await teardownKeypad(tester);
    });
  }

  for (final preset in watchPresets) {
    testWidgets('on $preset every key is there under its id and the call is the edge button', (tester) async {
      final handle = tester.ensureSemantics();
      preset.apply(tester);
      await pumpCollectingOverflows(tester, pad(preset));

      for (final key in KeypadKey.numbers) {
        expect(find.bySemanticsIdentifier(keypadKeyId(key.text)), findsOneWidget, reason: key.text);
      }
      expect(find.byType(WatchEdgeButton), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsIdentifier(actionPadVoiceCallId)),
        isSemantics(identifier: actionPadVoiceCallId, hasTapAction: false),
        reason: 'nothing to call yet',
      );

      handle.dispose();
      await teardownKeypad(tester);
    });

    testWidgets('on $preset keys type the number and a held 0 types +', (tester) async {
      preset.apply(tester);
      await pumpCollectingOverflows(tester, pad(preset));

      await tester.longPress(find.bySemanticsIdentifier(keypadKeyId('0')));
      await tester.tap(find.bySemanticsIdentifier(keypadKeyId('1')));
      await tester.tap(find.bySemanticsIdentifier(keypadKeyId('2')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '+12');
      final handle = tester.ensureSemantics();
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsIdentifier(actionPadVoiceCallId)),
        isSemantics(identifier: actionPadVoiceCallId, hasTapAction: true),
        reason: 'a number to call',
      );
      handle.dispose();

      await tester.tap(find.bySemanticsIdentifier(actionPadBackspaceId));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '+1');

      await teardownKeypad(tester);
    });
  }

  testWidgets('a phone keeps its pad', (tester) async {
    handsetPresets.first.apply(tester);
    await pumpCollectingOverflows(tester, pad(handsetPresets.first));

    expect(find.byType(WatchEdgeButton), findsNothing);

    await teardownKeypad(tester);
  });
}
