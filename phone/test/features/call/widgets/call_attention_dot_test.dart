import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/call/widgets/call_attention_dot.dart';

void main() {
  const controlSize = 64.0;
  final dot = find.byKey(const ValueKey('call-attention-dot'));

  Widget subject({required TextDirection direction}) => Directionality(
    textDirection: direction,
    child: Center(
      child: CallAttentionDot(
        shown: true,
        child: const SizedBox.square(key: ValueKey('control'), dimension: controlSize),
      ),
    ),
  );

  Future<void> expectCentreOnRim(WidgetTester tester, {required TextDirection direction}) async {
    await tester.pumpWidget(MaterialApp(home: subject(direction: direction)));

    final control = tester.getCenter(find.byKey(const ValueKey('control')));
    final centre = tester.getCenter(dot);
    expect(tester.getSize(dot), const Size.square(CallAttentionDot.size));
    expect((centre - control).distance, moreOrLessEquals(controlSize / 2));
    expect((centre.dx - control.dx).abs(), moreOrLessEquals((control.dy - centre.dy)));
    expect((centre.dx - control.dx).sign, direction == TextDirection.ltr ? 1 : -1);
  }

  testWidgets('the centre of the dot sits on the rim of the round control', (tester) async {
    await expectCentreOnRim(tester, direction: TextDirection.ltr);
  });

  testWidgets('the dot follows the reading direction to the other side of the rim', (tester) async {
    await expectCentreOnRim(tester, direction: TextDirection.rtl);
  });

  testWidgets('nothing is drawn while there is nothing to say', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CallAttentionDot(shown: false, child: SizedBox.square(dimension: controlSize)),
      ),
    );

    expect(dot, findsNothing);
  });
}
