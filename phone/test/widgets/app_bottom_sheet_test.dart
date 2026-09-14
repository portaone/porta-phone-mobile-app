import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/widgets/app_bottom_sheet.dart';

void main() {
  group('showAppBottomSheet', () {
    Widget app({required VoidCallback onOpen}) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(onPressed: onOpen, child: const Text('open')),
          ),
        ),
      );
    }

    testWidgets('names the barrier for what a tap on it does, not for what it is', (tester) async {
      final semantics = tester.ensureSemantics();
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                context = ctx;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      showAppBottomSheet<void>(
        context: context,
        builder: (_) => const SizedBox(height: 100, child: Text('sheet')),
      );
      await tester.pumpAndSettle();

      expect(find.text('sheet'), findsOneWidget);
      // Flutter's own default would be here otherwise.
      expect(find.bySemanticsLabel('Scrim'), findsNothing);
      final barrier = find.bySemanticsLabel(MaterialLocalizations.of(context).modalBarrierDismissLabel);
      expect(barrier, findsOneWidget);

      // Named as a way out, it has to be one.
      await tester.tap(barrier, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('sheet'), findsNothing);
      semantics.dispose();
    });

    testWidgets('forwards the sheet options the app relies on', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(app(onOpen: () {}));
      context = tester.element(find.text('open'));

      showAppBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => const SizedBox(height: 100, child: Text('sheet')),
      );
      await tester.pumpAndSettle();

      final route = ModalRoute.of(tester.element(find.text('sheet'))) as ModalBottomSheetRoute<void>;
      expect(route.isScrollControlled, isTrue);
      expect(route.useSafeArea, isTrue);
      expect(route.showDragHandle, isTrue);
    });

    test('every modal bottom sheet in the app goes through it', () {
      // The label lives in one place only while nothing bypasses it. A sheet
      // opened with showModalBottomSheet directly would be back to "Scrim".
      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart') && !file.path.endsWith('app_bottom_sheet.dart'))
          .where((file) => file.readAsStringSync().contains('showModalBottomSheet('))
          .map((file) => file.path)
          .toList();
      expect(offenders, isEmpty, reason: 'use showAppBottomSheet instead');
    });
  });
}
