import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';

import '../../helpers/screen_presets.dart';
import '../../helpers/semantics.dart';
import 'keypad_harness.dart';

void main() {
  late KeypadHarness harness;

  setUp(() => harness = KeypadHarness());
  tearDown(() => harness.release());

  group('KeypadView - what a screen reader gets', () {
    testWidgets('the number field says what it is and what is in it', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(harness.build());

      // It looks like plain text on the screen, so without a name of its own a
      // screen reader would announce nothing but "edit box".
      final data = numberField(tester).getSemanticsData();
      expect(data.label, 'Phone number');
      expect(data.identifier, keypadNumberInputId);
      expect(data.flagsCollection.isTextField, isTrue);

      await tester.tap(find.bySemanticsIdentifier(keypadKeyId('1')));
      await tester.tap(find.bySemanticsIdentifier(keypadKeyId('0')));
      await tester.pump();

      // The number that has been dialled is the value of that same node, so it
      // is read out with the field rather than found somewhere else.
      expect(numberField(tester).getSemanticsData().value, '10');
      await teardownKeypad(tester);
      semantics.dispose();
    });

    for (final preset in watchPresets) {
      testWidgets('on $preset the keys, backspace and the call work through semantics', (tester) async {
        final semantics = tester.ensureSemantics();
        preset.apply(tester);
        await tester.pumpWidget(harness.build());

        for (final key in ['1', '2', '3']) {
          await tapViaSemantics(tester, find.bySemanticsIdentifier(keypadKeyId(key)));
        }
        await tester.pump(const Duration(milliseconds: 300));
        expect(numberField(tester).getSemanticsData().value, '123');

        expectTapTargetSemantics(
          tester,
          find.bySemanticsIdentifier(actionPadBackspaceId),
          label: 'Backspace',
          identifier: actionPadBackspaceId,
        );
        await tapViaSemantics(tester, find.bySemanticsIdentifier(actionPadBackspaceId));
        await tester.pump(const Duration(milliseconds: 300));
        expect(numberField(tester).getSemanticsData().value, '12');

        expectTapTargetSemantics(
          tester,
          find.bySemanticsIdentifier(actionPadVoiceCallId),
          label: 'Audio call',
          identifier: actionPadVoiceCallId,
        );
        await tapViaSemantics(tester, find.bySemanticsIdentifier(actionPadVoiceCallId));
        verify(() => harness.callController.createCall(destination: '12')).called(1);

        await teardownKeypad(tester);
        semantics.dispose();
      });
    }

    testWidgets('nothing on the screen offers a press without saying what it does', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(harness.build());

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await teardownKeypad(tester);
      semantics.dispose();
    });
  });
}
