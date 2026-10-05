import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/keypad/view/keypad_view.dart';

import 'keypad_harness.dart';

void main() {
  late KeypadHarness harness;

  setUp(() => harness = KeypadHarness());
  tearDown(() => harness.release());

  /// A point of the invisible area above the field, well away from the field
  /// itself.
  Offset background(WidgetTester tester) => tester.getTopLeft(find.byType(KeypadView)) + const Offset(24, 24);

  group('KeypadView - long press on the area behind the field', () {
    testWidgets('offers Paste without reading what the clipboard holds', (tester) async {
      harness.withClipboard('1001');
      await tester.pumpWidget(harness.build());

      await tester.longPressAt(background(tester));
      await tester.pumpAndSettle();

      expect(find.text('Paste'), findsOneWidget);
      // Reading the content is what the platform reports to the person as a
      // paste, so it must wait for the Paste button.
      expect(harness.clipboardCalls, isNot(contains('Clipboard.getData')));
      expect(find.text('1001'), findsNothing);
      await teardownKeypad(tester);
    });

    testWidgets('reads the clipboard once Paste is tapped', (tester) async {
      harness.withClipboard('1001');
      await tester.pumpWidget(harness.build());

      await tester.longPressAt(background(tester));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();

      expect(harness.clipboardCalls, contains('Clipboard.getData'));
      expect(find.text('1001'), findsOneWidget);
      await teardownKeypad(tester);
    });

    testWidgets('with no text on the clipboard it leaves the field unfocused', (tester) async {
      harness.withClipboard(null);
      await tester.pumpWidget(harness.build());

      await tester.longPressAt(background(tester));
      await tester.pumpAndSettle();

      expect(find.text('Paste'), findsNothing);
      expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus, isFalse);
      expect(harness.clipboardCalls, isNot(contains('Clipboard.getData')));
      await teardownKeypad(tester);
    });
  });
}
