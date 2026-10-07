import 'package:flutter/gestures.dart';
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
    await tester.pumpWidget(
      wrap(KeypadKeyButton(text: '0', subtext: '+', alternate: '+', onKeyPressed: pressed.add, onKeyHeld: (_, _) {})),
    );

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
    /// What the key reported, in order: `0` for an entered character,
    /// `0>+` for a long press asking to exchange it for the alternate.
    late List<String> log;

    Future<void> pumpKey(WidgetTester tester, String text, String subtext, {bool held = true}) {
      log = [];
      return tester.pumpWidget(
        wrap(
          SizedBox.square(
            dimension: 96,
            child: KeypadKeyButton(
              text: text,
              subtext: subtext,
              onKeyPressed: log.add,
              alternate: subtext.length == 1 ? subtext : null,
              onKeyHeld: held ? (entered, alternate) => log.add('$entered>$alternate') : null,
            ),
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
      expect(log, ['5']);

      await tester.pump(short);
      await finger.up();
      await tester.pumpAndSettle();
      expect(log, ['5']);
    });

    testWidgets('a digit stays entered when the finger slides off the key', (tester) async {
      await pumpKey(tester, '5', 'J K L');

      final finger = await touch(tester);
      await tester.pump(short);
      await finger.moveBy(const Offset(0, 120));
      await finger.up();
      await tester.pumpAndSettle();
      expect(log, ['5']);
    });

    testWidgets('a digit held for long is entered once', (tester) async {
      await pumpKey(tester, '5', 'J K L');

      final finger = await touch(tester);
      await tester.pump(pastLongPress);
      await finger.up();
      await tester.pumpAndSettle();
      expect(log, ['5']);
    });

    testWidgets('zero is entered on the touch like any digit', (tester) async {
      await pumpKey(tester, '0', '+');

      final finger = await touch(tester);
      expect(log, ['0']);

      await tester.pump(short);
      await finger.up();
      await tester.pumpAndSettle();
      expect(log, ['0']);
    });

    testWidgets('of two fingers on the zero only the later one is a long press', (tester) async {
      await pumpKey(tester, '0', '+');
      final centre = tester.getCenter(find.byType(KeypadKeyButton));

      final first = await tester.startGesture(centre, pointer: 1);
      await tester.pump(const Duration(milliseconds: 100));
      final second = await tester.startGesture(centre, pointer: 2);
      expect(log, ['0', '0']);

      // Past the first finger's long press, short of the second one's.
      await tester.pump(const Duration(milliseconds: 450));
      expect(log, ['0', '0']);

      await tester.pump(const Duration(milliseconds: 100));
      expect(log, ['0', '0', '0>+']);

      await first.up();
      await second.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a finger that lifted is no long press even if the key is touched again', (tester) async {
      await pumpKey(tester, '0', '+');
      final centre = tester.getCenter(find.byType(KeypadKeyButton));

      final first = await tester.startGesture(centre, pointer: 1);
      await tester.pump(short);
      await first.up();
      final second = await tester.startGesture(centre, pointer: 2);
      await tester.pump(short);
      await second.up();
      await tester.pump(pastLongPress);
      expect(log, ['0', '0']);
    });

    testWidgets('a mouse that drifts a little while held is still a long press', (tester) async {
      await pumpKey(tester, '0', '+');

      final mouse = await tester.startGesture(
        tester.getCenter(find.byType(KeypadKeyButton)),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await mouse.moveBy(const Offset(3, 0));
      await tester.pump(pastLongPress);
      expect(log, ['0', '0>+']);

      await mouse.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a stylus with its button held enters the key like a finger', (tester) async {
      await pumpKey(tester, '5', 'J K L');

      final stylus = await tester.startGesture(
        tester.getCenter(find.byType(KeypadKeyButton)),
        kind: PointerDeviceKind.stylus,
        buttons: kPrimaryButton | kPrimaryStylusButton,
      );
      expect(log, ['5']);

      await stylus.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a key taken off the screen mid-hold leaves no long press behind', (tester) async {
      await pumpKey(tester, '0', '+');

      await touch(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(pastLongPress);
      expect(log, ['0']);
    });

    testWidgets('zero held becomes a plus, once', (tester) async {
      await pumpKey(tester, '0', '+');

      final finger = await touch(tester);
      await tester.pump(pastLongPress);
      expect(log, ['0', '0>+']);

      await finger.up();
      await tester.pumpAndSettle();
      expect(log, ['0', '0>+']);
    });

    // WT-1722: this gesture used to enter nothing at all.
    testWidgets('zero stays a zero when the finger slides away before the long press', (tester) async {
      for (final slide in const [Offset(0, 24), Offset(0, 120)]) {
        await pumpKey(tester, '0', '+');

        final finger = await touch(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await finger.moveBy(slide);
        await tester.pump(const Duration(milliseconds: 400));
        await finger.up();
        await tester.pumpAndSettle();
        expect(log, ['0'], reason: 'slide by $slide');
      }
    });

    testWidgets('a slide inside the touch slop does not stop the long press', (tester) async {
      await pumpKey(tester, '0', '+');

      final finger = await touch(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await finger.moveBy(const Offset(0, 12));
      await tester.pump(const Duration(milliseconds: 400));
      await finger.up();
      await tester.pumpAndSettle();
      expect(log, ['0', '0>+']);
    });

    testWidgets('a touch the system takes away has still entered its character', (tester) async {
      await pumpKey(tester, '0', '+');

      final finger = await touch(tester);
      await tester.pump(short);
      await finger.cancel();
      await tester.pumpAndSettle();
      expect(log, ['0']);
    });

    testWidgets('without a hold handler zero has no long press', (tester) async {
      await pumpKey(tester, '0', '+', held: false);

      final finger = await touch(tester);
      await tester.pump(pastLongPress);
      await finger.up();
      await tester.pumpAndSettle();
      expect(log, ['0']);
    });

    testWidgets('two fingers enter their keys in the order they touched', (tester) async {
      final entered = <String>[];
      await tester.pumpWidget(
        wrap(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (text, subtext) in const [('0', '+'), ('*', '')])
                SizedBox.square(
                  dimension: 96,
                  child: KeypadKeyButton(text: text, subtext: subtext, onKeyPressed: entered.add, onKeyHeld: (_, _) {}),
                ),
            ],
          ),
        ),
      );

      // The second thumb lands before the first one lifts.
      final first = await tester.startGesture(tester.getCenter(find.byKey(const Key('0'))), pointer: 1);
      await tester.pump(const Duration(milliseconds: 40));
      final second = await tester.startGesture(tester.getCenter(find.byKey(const Key('*'))), pointer: 2);
      await tester.pump(const Duration(milliseconds: 30));
      await first.up();
      await tester.pump(const Duration(milliseconds: 40));
      await second.up();
      await tester.pumpAndSettle();
      expect(entered, ['0', '*']);
    });
  });

  testWidgets('zero key without a hold handler offers no long press and no alternate', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(wrap(KeypadKeyButton(text: '0', subtext: '', alternate: '+', onKeyPressed: (_) {})));

    final node = tester.getSemantics(find.bySemanticsIdentifier(keypadKeyId('0')));
    expect(node.getSemanticsData().hasAction(SemanticsAction.longPress), isFalse);
    expect(node.label, '0');

    handle.dispose();
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
