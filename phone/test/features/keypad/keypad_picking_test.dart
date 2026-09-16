import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/models/models.dart';

import 'keypad_harness.dart';

// The pad has no rows, so what it offers turns on what is typed. Two things
// went wrong here and both are pinned below: the control appeared for a number
// the purpose would refuse, and it was gated on the call-transfer setting.
void main() {
  late KeypadHarness harness;

  setUp(() {
    harness = KeypadHarness();
  });

  tearDown(() => harness.release());

  Finder pickControl() => find.bySemanticsIdentifier(actionPadTransferId);

  Future<void> pump(WidgetTester tester, {DestinationPickPurpose? purpose, bool transferEnabled = false}) async {
    await tester.pumpWidget(harness.build(purpose: purpose, transferEnabled: transferEnabled));
    await tester.pump();
  }

  testWidgets('a number the purpose takes can be handed over', (tester) async {
    harness.keypadCubit.setValue('1001');

    await pump(tester, purpose: _Purpose());

    expect(pickControl(), findsOneWidget);
    await teardownKeypad(tester);
  });

  testWidgets('a number it refuses cannot', (tester) async {
    // Offering the section is not acceptance of everything typed into it. The
    // pad used to ask only the first question and hand over whatever was
    // there.
    harness.keypadCubit.setValue('1001');

    await pump(tester, purpose: _Purpose(takes: false));

    expect(pickControl(), findsNothing);
    await teardownKeypad(tester);
  });

  testWidgets('the control follows what is typed, not merely whether anything is', (tester) async {
    // Both values are nonempty, so a pad watching only "is there a number"
    // would never notice the difference.
    harness.keypadCubit.setValue('2002');
    await pump(tester, purpose: _Purpose(takes: false, only: '1001'));
    expect(pickControl(), findsNothing);

    harness.keypadCubit.setValue('1001');
    await tester.pumpAndSettle();

    expect(pickControl(), findsOneWidget);
    await teardownKeypad(tester);
  });

  testWidgets('answering a choice does not need call transfer switched on', (tester) async {
    // That setting is permission to hand a call over, nothing else. Gating on
    // it left another purpose unanswerable wherever transfers are disabled.
    harness.keypadCubit.setValue('1001');

    await pump(tester, purpose: _Purpose(), transferEnabled: false);

    expect(pickControl(), findsOneWidget);
    await teardownKeypad(tester);
  });

  testWidgets('with no choice being made the pad is unchanged', (tester) async {
    harness.keypadCubit.setValue('1001');

    await pump(tester);

    expect(pickControl(), findsNothing);
    await teardownKeypad(tester);
  });
}

class _Purpose implements DestinationPickPurpose {
  _Purpose({this.takes = true, this.only});

  final bool takes;

  /// The one number this purpose will take, when it is choosy.
  final String? only;

  final submitted = <DestinationCandidate>[];

  @override
  String get announcement => 'Pick somebody';

  @override
  bool offeredBy(MainFlavor flavor) => true;

  @override
  bool accepts(DestinationCandidate candidate) {
    if (only != null) return candidate.number == only;
    return takes && candidate.number != null;
  }

  @override
  bool get closedByChoice => true;

  @override
  DestinationPickPrecedence get precedence => DestinationPickPrecedence.ordinary;

  @override
  bool get cancellable => false;

  @override
  IconData get pickIcon => Icons.phone_forwarded;

  @override
  String pickLabel(DestinationCandidate candidate) => 'Choose ${candidate.number}';

  @override
  void submit(DestinationCandidate candidate) => submitted.add(candidate);
}
