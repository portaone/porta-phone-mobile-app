import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'keypad_harness.dart';

void main() {
  late KeypadHarness harness;

  setUp(() => harness = KeypadHarness());
  tearDown(() => harness.release());

  group('KeypadView - on a short screen', () {
    // A 16:9 phone with on-screen navigation buttons: 360x640 dp, of which the
    // buttons take 48 dp. The status bar is 24 dp, the app bar 48 dp, the tabs
    // 58 dp - the Sony Xperia X the defect was reported on.
    const screen = Size(360, 592);
    const statusBar = 24.0;
    const toolbar = 48.0;
    const tabs = 58.0;

    testWidgets('the number is below the app bar the body is drawn behind', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = screen;
      tester.view.padding = const FakeViewPadding(top: statusBar);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        harness.build(
          appBar: AppBar(toolbarHeight: toolbar),
          bottomNavigationBar: const SizedBox(height: tabs),
        ),
      );

      final appBar = tester.getRect(find.byType(AppBar));
      final number = tester.getRect(find.byType(TextField));
      expect(appBar.bottom, statusBar + toolbar);
      expect(number.top, greaterThanOrEqualTo(appBar.bottom));

      await teardownKeypad(tester);
    });
  });
}
