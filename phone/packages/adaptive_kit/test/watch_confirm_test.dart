import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_kit/adaptive_kit.dart';

import 'helpers/screen_presets.dart';

void main() {
  Widget wrap(Widget body) => MaterialApp(home: Scaffold(body: body));

  WatchConfirm confirm({
    VoidCallback? onCancel,
    VoidCallback? onConfirm,
    bool destructive = false,
    String question = 'Log out?',
  }) => WatchConfirm(
    question: question,
    detail: 'Calls stop',
    cancelLabel: 'No',
    confirmLabel: 'Yes',
    onCancel: onCancel ?? () {},
    onConfirm: onConfirm ?? () {},
    destructive: destructive,
    cancelIdentifier: 'no-id',
    confirmIdentifier: 'yes-id',
    cancelKey: const Key('no'),
    confirmKey: const Key('yes'),
  );

  group('WatchConfirm', () {
    for (final preset in watchPresets) {
      testWidgets('on $preset the question sits above the two answers, no on the left', (tester) async {
        preset.apply(tester);
        expect(await pumpCollectingOverflows(tester, wrap(confirm())), isEmpty);

        final question = tester.getRect(find.text('Log out?'));
        final detail = tester.getRect(find.text('Calls stop'));
        final no = tester.getRect(find.byKey(const Key('no')));
        final yes = tester.getRect(find.byKey(const Key('yes')));
        expect(question.bottom, lessThanOrEqualTo(detail.top));
        expect(detail.bottom, lessThanOrEqualTo(no.top));
        expect(no.right, lessThanOrEqualTo(yes.left));
        expect((no.center.dy - yes.center.dy).abs(), lessThan(1));
      });
    }

    testWidgets('each button answers for itself', (tester) async {
      watchPresets.first.apply(tester);
      final answers = <String>[];
      await pumpCollectingOverflows(
        tester,
        wrap(confirm(onCancel: () => answers.add('no'), onConfirm: () => answers.add('yes'))),
      );

      await tester.tap(find.byKey(const Key('no')));
      await tester.tap(find.byKey(const Key('yes')));

      expect(answers, ['no', 'yes']);
    });

    testWidgets('a destructive yes takes the error colours, a plain one the theme filled button', (tester) async {
      watchPresets.first.apply(tester);
      ButtonStyle? style() => tester
          .widget<ButtonStyleButton>(
            find.descendant(of: find.byKey(const Key('yes')), matching: find.bySubtype<ButtonStyleButton>()).first,
          )
          .style;
      Color? background() => style()?.backgroundColor?.resolve({});
      Color? icon() => style()?.foregroundColor?.resolve({});
      WatchConfirm coloured(Color fill, {bool destructive = false}) => WatchConfirm(
        question: 'Log out?',
        cancelLabel: 'No',
        confirmLabel: 'Yes',
        onCancel: () {},
        onConfirm: () {},
        destructive: destructive,
        confirmColor: fill,
        confirmKey: const Key('yes'),
      );

      await pumpCollectingOverflows(tester, wrap(confirm(destructive: true)));
      final error = Theme.of(tester.element(find.byType(WatchConfirm))).colorScheme.error;
      expect(background(), error);

      // A colour of its own wins over the scheme's, its icon in whichever of
      // black and white reads on it.
      await pumpCollectingOverflows(tester, wrap(coloured(const Color(0xFFB71C1C), destructive: true)));
      expect(background(), const Color(0xFFB71C1C));
      expect(icon(), Colors.white);

      await pumpCollectingOverflows(tester, wrap(coloured(const Color(0xFFFF8A80), destructive: true)));
      expect(icon(), Colors.black);

      await pumpCollectingOverflows(tester, wrap(coloured(const Color(0xFF1565C0))));
      expect(background(), const Color(0xFF1565C0));

      // No colour of its own: the theme's filled button decides.
      await pumpCollectingOverflows(tester, wrap(confirm()));
      expect(background(), isNull);
    });

    testWidgets('a question too long for the face scrolls and the answers stay', (tester) async {
      watchPresets.first.apply(tester);
      final long = List.filled(10, 'Delete every message of this conversation').join(' ');

      expect(await pumpCollectingOverflows(tester, wrap(confirm(question: long))), isEmpty);
      final scroll = tester.state<ScrollableState>(
        find.descendant(of: find.byType(WatchConfirm), matching: find.byType(Scrollable)),
      );
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      expect(find.byKey(const Key('no')).hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('yes')).hitTestable(), findsOneWidget);
    });

    testWidgets('the question and detail take the colours given for the surface', (tester) async {
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(
        tester,
        wrap(
          WatchConfirm(
            question: 'Log out?',
            detail: 'Calls stop',
            cancelLabel: 'No',
            confirmLabel: 'Yes',
            onCancel: () {},
            onConfirm: () {},
            questionColor: const Color(0xFFFFFFFF),
            detailColor: const Color(0xFFCCCCCC),
          ),
        ),
      );

      expect(tester.widget<Text>(find.text('Log out?')).style?.color, const Color(0xFFFFFFFF));
      expect(tester.widget<Text>(find.text('Calls stop')).style?.color, const Color(0xFFCCCCCC));
    });

    testWidgets('it stands on a bare page with no Material above it', (tester) async {
      watchPresets.first.apply(tester);
      await tester.pumpWidget(MaterialApp(home: confirm()));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('yes')), findsOneWidget);
    });

    testWidgets('the question is a header and the buttons carry their ids and names', (tester) async {
      final handle = tester.ensureSemantics();
      watchPresets.first.apply(tester);
      await pumpCollectingOverflows(tester, wrap(confirm()));

      expect(tester.getSemantics(find.text('Log out?')).flagsCollection.isHeader, isTrue);
      expect(find.bySemanticsIdentifier('no-id'), findsOneWidget);
      expect(find.bySemanticsIdentifier('yes-id'), findsOneWidget);
      expect(find.bySemanticsLabel('Yes'), findsOneWidget);
      handle.dispose();
    });
  });
}
