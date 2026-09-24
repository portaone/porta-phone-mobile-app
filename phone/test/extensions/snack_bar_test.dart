import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/extensions/extensions.dart';

void main() {
  Future<void> pumpHost(
    WidgetTester tester,
    void Function(BuildContext context) show, {
    bool screenReaderOn = false,
  }) async {
    await tester.pumpWidget(
      // WidgetsApp keeps an ambient MediaQuery when it finds one, so this is
      // how a screen reader is switched on for the whole host.
      MediaQuery(
        data: MediaQueryData(accessibleNavigation: screenReaderOn),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(onPressed: () => show(context), child: const Text('show')),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
  }

  testWidgets('a message with something to do waits instead of timing out', (tester) async {
    await pumpHost(
      tester,
      (context) => context.showErrorSnackBar(
        'Failed',
        action: SnackBarAction(label: 'Retry', onPressed: () {}),
      ),
    );

    // Three seconds was not enough to notice the action, let alone reach it.
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Failed'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Failed'), findsNothing);
  });

  testWidgets('a message with nothing to do still goes away on its own', (tester) async {
    await pumpHost(tester, (context) => context.showSnackBar('Saved'));

    expect(find.text('Saved'), findsOneWidget);

    // The dismiss timer only starts once the bar has finished sliding in.
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('a message asked not to wait goes away on its own, action and all', (tester) async {
    // An undo after a confirmation is an offer, not a question: the message
    // reads like the confirmations around it and leaves with them.
    await pumpHost(
      tester,
      (context) => context.showSnackBar(
        'Moved to trash',
        action: SnackBarAction(label: 'Undo', onPressed: () {}),
        persist: false,
      ),
    );

    expect(find.text('Moved to trash'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Moved to trash'), findsNothing);
  });

  testWidgets('under a screen reader a message with something to do waits whatever was asked', (tester) async {
    // Three seconds is not enough to reach anything by touch exploration.
    await pumpHost(
      tester,
      (context) => context.showSnackBar(
        'Moved to trash',
        action: SnackBarAction(label: 'Undo', onPressed: () {}),
        persist: false,
      ),
      screenReaderOn: true,
    );

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
    expect(find.text('Moved to trash'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('a message with nothing to do cannot be made to wait', (tester) async {
    // There would be nothing to close it with.
    await pumpHost(tester, (context) => context.showSnackBar('Saved', persist: true));

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsNothing);
  });
}
