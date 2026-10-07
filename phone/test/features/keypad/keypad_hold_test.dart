import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'keypad_harness.dart';

void main() {
  late KeypadHarness harness;

  setUp(() => harness = KeypadHarness());
  tearDown(() => harness.release());

  String number(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField)).controller!.text;

  Future<void> press(WidgetTester tester, String key, {Duration hold = const Duration(milliseconds: 60)}) async {
    final finger = await tester.startGesture(tester.getCenter(find.byKey(Key(key))));
    await tester.pump(hold);
    await finger.up();
    await tester.pump();
  }

  group('KeypadView - the zero key', () {
    testWidgets('a short press enters a zero, a long one a plus', (tester) async {
      await tester.pumpWidget(harness.build());

      await press(tester, '0', hold: const Duration(milliseconds: 700));
      await press(tester, '1');
      await press(tester, '0');
      expect(number(tester), '+10');

      await teardownKeypad(tester);
    });

    testWidgets('a long press shows the zero first and then the plus in its place', (tester) async {
      await tester.pumpWidget(harness.build());
      await press(tester, '4');

      final finger = await tester.startGesture(tester.getCenter(find.byKey(const Key('0'))));
      await tester.pump();
      expect(number(tester), '40');

      await tester.pump(const Duration(milliseconds: 700));
      expect(number(tester), '4+');

      await finger.up();
      await tester.pump();
      expect(number(tester), '4+');

      await teardownKeypad(tester);
    });

    // WT-1722: held, slid off the key, lifted late - it entered nothing.
    testWidgets('a press that slides away and lifts late still enters the zero', (tester) async {
      await tester.pumpWidget(harness.build());

      final finger = await tester.startGesture(tester.getCenter(find.byKey(const Key('0'))));
      await tester.pump(const Duration(milliseconds: 300));
      await finger.moveBy(const Offset(120, 0));
      await tester.pump(const Duration(milliseconds: 400));
      await finger.up();
      await tester.pump();
      expect(number(tester), '0');

      await teardownKeypad(tester);
    });

    testWidgets('a zero pressed while another finger is still down keeps its place', (tester) async {
      await tester.pumpWidget(harness.build());

      final first = await tester.startGesture(tester.getCenter(find.byKey(const Key('0'))), pointer: 1);
      await tester.pump(const Duration(milliseconds: 40));
      final second = await tester.startGesture(tester.getCenter(find.byKey(const Key('*'))), pointer: 2);
      await tester.pump(const Duration(milliseconds: 30));
      await first.up();
      await second.up();
      await tester.pump();
      expect(number(tester), '0*');

      await teardownKeypad(tester);
    });
  });

  // The next edit ends the previous key: a long press may exchange only the
  // zero its own touch entered, and only while nothing else has happened to
  // the field since.
  group('KeypadView - a zero held while the number changes', () {
    TextEditingController field(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField)).controller!;

    Future<TestGesture> touch(WidgetTester tester, String key, int pointer) =>
        tester.startGesture(tester.getCenter(find.byKey(Key(key))), pointer: pointer);

    const pastLongPress = Duration(milliseconds: 600);

    Future<void> finish(WidgetTester tester, TestGesture finger) async {
      await finger.up();
      await teardownKeypad(tester);
    }

    testWidgets('another key pressed during the hold keeps the zero and adds no plus', (tester) async {
      await tester.pumpWidget(harness.build());

      final held = await touch(tester, '0', 1);
      await tester.pump(const Duration(milliseconds: 60));
      final other = await touch(tester, '1', 2);
      await other.up();
      await tester.pump(pastLongPress);
      expect(number(tester), '01');

      await finish(tester, held);
    });

    testWidgets('a second zero pressed during the hold is not the one exchanged', (tester) async {
      await tester.pumpWidget(harness.build());

      final held = await touch(tester, '0', 1);
      await tester.pump(const Duration(milliseconds: 60));
      final other = await touch(tester, '0', 2);
      await other.up();
      await tester.pump(pastLongPress);
      expect(number(tester), '00');

      await finish(tester, held);
    });

    testWidgets('the second of two held zeros becomes the plus, the first stays', (tester) async {
      await tester.pumpWidget(harness.build());

      final first = await touch(tester, '0', 1);
      await tester.pump(const Duration(milliseconds: 60));
      final second = await touch(tester, '0', 2);
      await tester.pump(pastLongPress);
      expect(number(tester), '0+');

      await second.up();
      await finish(tester, first);
    });

    testWidgets('a caret moved during the hold leaves every zero alone', (tester) async {
      await tester.pumpWidget(harness.build());
      field(tester).value = const TextEditingValue(text: '70', selection: TextSelection.collapsed(offset: 2));

      final held = await touch(tester, '0', 1);
      expect(number(tester), '700');
      field(tester).selection = const TextSelection.collapsed(offset: 2);
      await tester.pump(pastLongPress);
      expect(number(tester), '700');

      await finish(tester, held);
    });

    testWidgets('a selection made during the hold is not overwritten', (tester) async {
      await tester.pumpWidget(harness.build());
      field(tester).value = const TextEditingValue(text: '123', selection: TextSelection.collapsed(offset: 3));

      final held = await touch(tester, '0', 1);
      field(tester).selection = const TextSelection(baseOffset: 0, extentOffset: 2);
      await tester.pump(pastLongPress);
      expect(number(tester), '1230');

      await finish(tester, held);
    });

    testWidgets('a number cleared during the hold stays empty', (tester) async {
      await tester.pumpWidget(harness.build());

      final held = await touch(tester, '0', 1);
      field(tester).clear();
      await tester.pump(pastLongPress);
      expect(number(tester), '');

      await finish(tester, held);
    });

    testWidgets('the same text put back during the hold is not the entry any more', (tester) async {
      await tester.pumpWidget(harness.build());

      final held = await touch(tester, '0', 1);
      final same = field(tester).value;
      field(tester).clear();
      field(tester).value = same;
      await tester.pump(pastLongPress);
      expect(number(tester), '0');

      await finish(tester, held);
    });

    testWidgets('a zero entered over a selection is exchanged where it landed', (tester) async {
      await tester.pumpWidget(harness.build());
      field(tester).value = const TextEditingValue(
        text: '123',
        selection: TextSelection(baseOffset: 1, extentOffset: 3),
      );

      final held = await touch(tester, '0', 1);
      expect(number(tester), '10');
      await tester.pump(pastLongPress);
      expect(number(tester), '1+');

      await finish(tester, held);
    });

    testWidgets('the phone confirms a long press only when it gave the plus', (tester) async {
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call.method);
        return null;
      });
      await tester.pumpWidget(harness.build());

      // Settled by another key: no plus, nothing to confirm.
      final held = await touch(tester, '0', 1);
      await tester.pump(const Duration(milliseconds: 60));
      final other = await touch(tester, '1', 2);
      await other.up();
      await tester.pump(pastLongPress);
      await held.up();
      expect(number(tester), '01');
      expect(haptics, isEmpty);

      final again = await touch(tester, '0', 3);
      await tester.pump(pastLongPress);
      expect(number(tester), '01+');
      expect(haptics, hasLength(1));

      await finish(tester, again);
    });

    testWidgets('a zero entered in the middle is exchanged in the middle', (tester) async {
      await tester.pumpWidget(harness.build());
      field(tester).value = const TextEditingValue(text: '12', selection: TextSelection.collapsed(offset: 1));

      final held = await touch(tester, '0', 1);
      await tester.pump(pastLongPress);
      expect(number(tester), '1+2');
      expect(field(tester).selection, const TextSelection.collapsed(offset: 2));

      await finish(tester, held);
    });
  });
}
