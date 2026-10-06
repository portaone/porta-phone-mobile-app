import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/widgets/keypad_key_button.dart';

import '../helpers/helpers.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('digit key is one named node and semantic activation enters the digit once', (tester) async {
    final handle = tester.ensureSemantics();

    final pressed = <String>[];
    await tester.pumpWidget(wrap(KeypadKeyButton(text: '2', subtext: 'A B C', onKeyPressed: pressed.add)));

    final finder = find.bySemanticsIdentifier(keypadKeyId('2'));
    expectTapTargetSemantics(tester, finder, label: '2 A B C', identifier: keypadKeyId('2'), isButton: true);

    await tapViaSemantics(tester, finder);
    expect(pressed, ['2']);

    handle.dispose();
  });

  testWidgets('pointer input path still enters the digit exactly once', (tester) async {
    final pressed = <String>[];
    await tester.pumpWidget(wrap(KeypadKeyButton(text: '7', subtext: 'P Q R S', onKeyPressed: pressed.add)));

    await tester.tap(find.byType(KeypadKeyButton));
    await tester.pumpAndSettle();
    expect(pressed, ['7']);
  });

  testWidgets('zero key: semantic long press enters the plus', (tester) async {
    final handle = tester.ensureSemantics();

    final pressed = <String>[];
    await tester.pumpWidget(wrap(KeypadKeyButton(text: '0', subtext: '+', onKeyPressed: pressed.add)));

    final finder = find.bySemanticsIdentifier(keypadKeyId('0'));
    final node = tester.getSemantics(finder);
    expect(node.getSemanticsData().hasAction(SemanticsAction.longPress), isTrue);

    node.owner!.performAction(node.id, SemanticsAction.longPress);
    await tester.pump();
    expect(pressed, ['+']);

    await tapViaSemantics(tester, finder);
    expect(pressed, ['+', '0']);

    handle.dispose();
  });

  group('a finger on a key', () {
    late List<String> entered;

    Future<void> pumpKey(WidgetTester tester, String text, String subtext) {
      entered = [];
      return tester.pumpWidget(
        wrap(
          SizedBox.square(
            dimension: 96,
            child: KeypadKeyButton(text: text, subtext: subtext, onKeyPressed: entered.add),
          ),
        ),
      );
    }

    Future<TestGesture> touch(WidgetTester tester) =>
        tester.startGesture(tester.getCenter(find.byType(KeypadKeyButton)));

    const short = Duration(milliseconds: 80);
    const pastLongPress = Duration(milliseconds: 700);

    testWidgets('a digit is entered on the touch, before the lift', (tester) async {
      await pumpKey(tester, '5', 'J K L');

      final finger = await touch(tester);
      expect(entered, ['5']);

      await tester.pump(short);
      await finger.up();
      await tester.pumpAndSettle();
      expect(entered, ['5']);
    });

    testWidgets('a digit stays entered when the finger slides off the key', (tester) async {
      await pumpKey(tester, '5', 'J K L');

      final finger = await touch(tester);
      await tester.pump(short);
      await finger.moveBy(const Offset(0, 120));
      await finger.up();
      await tester.pumpAndSettle();
      expect(entered, ['5']);
    });

    testWidgets('a digit held for long is entered once', (tester) async {
      await pumpKey(tester, '5', 'J K L');

      final finger = await touch(tester);
      await tester.pump(pastLongPress);
      await finger.up();
      await tester.pumpAndSettle();
      expect(entered, ['5']);
    });

    testWidgets('zero is entered on the lift of a short press', (tester) async {
      await pumpKey(tester, '0', '+');

      final finger = await touch(tester);
      await tester.pump(short);
      expect(entered, isEmpty);

      await finger.up();
      await tester.pumpAndSettle();
      expect(entered, ['0']);
    });

    testWidgets('zero held enters a plus, once', (tester) async {
      await pumpKey(tester, '0', '+');

      final finger = await touch(tester);
      await tester.pump(pastLongPress);
      expect(entered, ['+']);

      await finger.up();
      await tester.pumpAndSettle();
      expect(entered, ['+']);
    });

    testWidgets('a short press of zero that slides off the key still enters the zero', (tester) async {
      await pumpKey(tester, '0', '+');

      final finger = await touch(tester);
      await tester.pump(short);
      await finger.moveBy(const Offset(0, 120));
      await tester.pump(short);
      await finger.up();
      await tester.pumpAndSettle();
      expect(entered, ['0']);
    });

    testWidgets('a slide inside the touch slop does not stop the long press', (tester) async {
      await pumpKey(tester, '0', '+');

      final finger = await touch(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await finger.moveBy(const Offset(0, 12));
      await tester.pump(const Duration(milliseconds: 400));
      await finger.up();
      await tester.pumpAndSettle();
      expect(entered, ['+']);
    });

    testWidgets('a touch of zero the system takes away enters nothing', (tester) async {
      await pumpKey(tester, '0', '+');

      final finger = await touch(tester);
      await tester.pump(short);
      await finger.cancel();
      await tester.pumpAndSettle();
      expect(entered, isEmpty);
    });

    // WT-1722, as it is today: the slide cancels the long press and the lift
    // comes too late for the zero.
    testWidgets('zero that slides away before the long press and lifts after it enters nothing', (tester) async {
      for (final slide in const [Offset(0, 24), Offset(0, 120)]) {
        await pumpKey(tester, '0', '+');

        final finger = await touch(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await finger.moveBy(slide);
        await tester.pump(const Duration(milliseconds: 400));
        await finger.up();
        await tester.pumpAndSettle();
        expect(entered, isEmpty, reason: 'slide by $slide');
      }
    });

    // As it is today: the zero is entered on its lift, the next key on its
    // touch, so a second thumb landing early gets ahead of the zero.
    testWidgets('a key touched while zero is still down is entered before the zero', (tester) async {
      final entered = <String>[];
      await tester.pumpWidget(
        wrap(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (text, subtext) in const [('0', '+'), ('*', '')])
                SizedBox.square(
                  dimension: 96,
                  child: KeypadKeyButton(text: text, subtext: subtext, onKeyPressed: entered.add),
                ),
            ],
          ),
        ),
      );

      final first = await tester.startGesture(tester.getCenter(find.byKey(const Key('0'))), pointer: 1);
      await tester.pump(const Duration(milliseconds: 40));
      final second = await tester.startGesture(tester.getCenter(find.byKey(const Key('*'))), pointer: 2);
      await tester.pump(const Duration(milliseconds: 30));
      await first.up();
      await tester.pump(const Duration(milliseconds: 40));
      await second.up();
      await tester.pumpAndSettle();
      expect(entered, ['*', '0']);
    });
  });

  testWidgets('star and pound keys get readable stable ids', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      wrap(
        Row(
          children: [
            KeypadKeyButton(text: '*', subtext: '', onKeyPressed: (_) {}),
            KeypadKeyButton(text: '#', subtext: '', onKeyPressed: (_) {}),
          ],
        ),
      ),
    );

    expectTapTargetSemantics(tester, find.bySemanticsIdentifier(keypadKeyStarId), label: '*', isButton: true);
    expectTapTargetSemantics(tester, find.bySemanticsIdentifier(keypadKeyPoundId), label: '#', isButton: true);

    handle.dispose();
  });
}
