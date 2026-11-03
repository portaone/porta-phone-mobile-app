import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/screen_presets.dart';
import '../contact/contact_screen_harness.dart' show buildContact;
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

  for (final preset in watchPresets) {
    testWidgets('on $preset the screen itself fits, with no app bar and the call on the bezel', (tester) async {
      preset.apply(tester);

      expect(await pumpCollectingOverflows(tester, harness.buildScreen()), isEmpty);
      expect(find.byType(AppBar), findsNothing);
      expect(
        tester.getRect(find.byType(WatchEdgeButton)).bottom,
        tester.view.physicalSize.height / tester.view.devicePixelRatio,
      );

      await teardownKeypad(tester);
    });

    testWidgets('on $preset backspace and the call answer the press right after a key', (tester) async {
      final handle = tester.ensureSemantics();
      preset.apply(tester);
      await pumpCollectingOverflows(tester, harness.buildScreen());

      // No debounce wait: the cubit has not seen the digit yet.
      await tester.tap(find.bySemanticsIdentifier(keypadKeyId('7')));
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsIdentifier(actionPadBackspaceId)),
        isSemantics(identifier: actionPadBackspaceId, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsIdentifier(actionPadVoiceCallId)),
        isSemantics(identifier: actionPadVoiceCallId, hasTapAction: true),
      );

      handle.dispose();
      await teardownKeypad(tester);
    });

    testWidgets('on $preset a found contact takes its line without moving the keys', (tester) async {
      preset.apply(tester);
      final found = KeypadHarness(contact: buildContact(number: '12'));
      addTearDown(found.release);
      expect(await pumpCollectingOverflows(tester, found.build()), isEmpty);
      final before = tester.getRect(find.bySemanticsIdentifier(keypadKeyId('5')));

      await tester.tap(find.bySemanticsIdentifier(keypadKeyId('1')));
      await tester.tap(find.bySemanticsIdentifier(keypadKeyId('2')));
      // The number's debounce, then the lookup's.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('Anna Marchenko'), findsOneWidget);
      expect(tester.getRect(find.bySemanticsIdentifier(keypadKeyId('5'))), before);
      expect(tester.takeException(), isNull);

      await teardownKeypad(tester);
    });

    testWidgets('on $preset backspace is off with nothing to erase', (tester) async {
      final handle = tester.ensureSemantics();
      preset.apply(tester);
      await pumpCollectingOverflows(tester, pad(preset));

      expect(
        tester.getSemantics(find.bySemanticsIdentifier(actionPadBackspaceId)),
        isSemantics(identifier: actionPadBackspaceId, hasTapAction: false),
      );

      await tester.tap(find.bySemanticsIdentifier(keypadKeyId('7')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.getSemantics(find.bySemanticsIdentifier(actionPadBackspaceId)),
        isSemantics(identifier: actionPadBackspaceId, hasTapAction: true),
      );

      handle.dispose();
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
