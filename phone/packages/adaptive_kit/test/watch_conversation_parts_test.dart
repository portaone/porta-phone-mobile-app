import 'dart:async';
import 'dart:ui' show SemanticsFlag;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_kit/adaptive_kit.dart';

import 'helpers/screen_presets.dart';

void main() {
  Widget wrap(Widget body) => MaterialApp(home: Scaffold(body: body));

  group('WatchScrollList.builder reverse', () {
    for (final preset in watchPresets) {
      testWidgets('on $preset row 0 sits at the bottom, above the edge button, and the title at the top', (
        tester,
      ) async {
        preset.apply(tester);
        expect(
          await pumpCollectingOverflows(
            tester,
            wrap(
              WatchScrollList.builder(
                title: 'Thread',
                reverse: true,
                itemCount: 2,
                itemBuilder: (context, index) => SizedBox(height: 40, child: Text('row $index')),
                edge: (context, overlay) =>
                    OutlinedButton(onPressed: () {}, style: overlay, child: const Text('Reply')),
              ),
            ),
          ),
          isEmpty,
        );

        final newest = tester.getRect(find.text('row 0'));
        final older = tester.getRect(find.text('row 1'));
        final reply = tester.getRect(find.text('Reply'));
        expect(newest.top, greaterThan(older.top));
        expect(newest.bottom, lessThan(reply.top));
        expect(tester.getRect(find.text('Thread')).top, lessThan(older.top));
      });
    }
  });

  testWidgets('a short reversed list keeps its title at the top of the face, not over its rows', (tester) async {
    watchPresets.first.apply(tester);
    await tester.pumpWidget(
      wrap(
        WatchScrollList.builder(
          title: 'Thread',
          reverse: true,
          itemCount: 1,
          itemBuilder: (context, index) => const SizedBox(height: 40, child: Text('row 0')),
          edge: (context, overlay) => OutlinedButton(onPressed: () {}, style: overlay, child: const Text('Reply')),
        ),
      ),
    );

    final face = tester.getRect(find.byType(Scaffold));
    final title = tester.getRect(find.text('Thread'));
    final row = tester.getRect(find.text('row 0'));
    final reply = tester.getRect(find.text('Reply'));
    expect(title.top, lessThan(face.height * 0.25));
    // The row stays down by the edge button, a gap of the fade above it.
    expect(row.bottom, lessThan(reply.top));
    expect(row.top - title.bottom, greaterThan(0));
    expect(reply.top - row.bottom, lessThan(80));
  });

  group('WatchKeyboardInput', () {
    testWidgets('open focuses the hidden field; the action key hands the text over and closes it', (tester) async {
      watchPresets.first.apply(tester);
      final sent = <String>[];
      await tester.pumpWidget(
        wrap(
          WatchKeyboardInput(
            fieldKey: const Key('field'),
            onSubmitted: sent.add,
            builder: (context, open) => TextButton(onPressed: open, child: const Text('Reply')),
          ),
        ),
      );
      FocusNode focus() => tester.widget<TextField>(find.byKey(const Key('field'))).focusNode!;

      await tester.tap(find.text('Reply'));
      await tester.pump();
      expect(focus().hasFocus, isTrue);

      await tester.enterText(find.byKey(const Key('field')), 'on my way');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(sent, ['on my way']);
      expect(focus().hasFocus, isFalse);
    });

    testWidgets('the field takes no part in semantics: the button is what a screen reader meets', (tester) async {
      final handle = tester.ensureSemantics();
      watchPresets.first.apply(tester);
      await tester.pumpWidget(
        wrap(
          WatchKeyboardInput(
            builder: (context, open) => TextButton(onPressed: open, child: const Text('Reply')),
          ),
        ),
      );
      expect(find.semantics.byFlag(SemanticsFlag.isTextField), findsNothing);
      handle.dispose();
    });

    testWidgets('a route over it takes the focus with it: closing it brings no keyboard back', (tester) async {
      watchPresets.first.apply(tester);
      await tester.pumpWidget(
        wrap(
          WatchKeyboardInput(
            fieldKey: const Key('field'),
            builder: (context, open) => TextButton(onPressed: open, child: const Text('Reply')),
          ),
        ),
      );
      await tester.tap(find.text('Reply'));
      await tester.pump();

      final context = tester.element(find.text('Reply'));
      unawaited(showDialog<void>(context: context, builder: (_) => const Text('over')));
      await tester.pumpAndSettle();
      Navigator.of(context).pop();
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(find.byKey(const Key('field'))).focusNode!.hasFocus, isFalse);
    });
  });

  group('WatchBubble', () {
    for (final preset in watchPresets) {
      testWidgets('on $preset mine sits right, theirs left, a long text wraps inside the face', (tester) async {
        preset.apply(tester);
        expect(
          await pumpCollectingOverflows(
            tester,
            wrap(
              const SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    WatchBubble(text: 'A long message that has to wrap over several lines on a face', mine: false),
                    WatchBubble(text: 'Thanks', mine: true, time: '22:40', mark: Icon(Icons.done_all)),
                  ],
                ),
              ),
            ),
          ),
          isEmpty,
        );

        final theirs = tester.getRect(find.byType(WatchBubble).first);
        final mine = tester.getRect(find.text('Thanks'));
        final width = tester.getRect(find.byType(Column).first).width;
        expect(mine.center.dx, greaterThan(width / 2));
        expect(tester.getRect(find.textContaining('A long')).left, lessThan(width / 2));
        expect(theirs.width, lessThanOrEqualTo(width));
      });
    }

    testWidgets('one node for a screen reader: sender, text, time and what went wrong', (tester) async {
      final handle = tester.ensureSemantics();
      watchPresets.first.apply(tester);
      await tester.pumpWidget(
        wrap(
          const WatchBubble(
            text: 'Thanks',
            mine: true,
            sender: 'Jane',
            time: '09:13',
            mark: Icon(Icons.done, semanticLabel: 'sent'),
            note: 'Not sent',
          ),
        ),
      );

      expect(find.bySemanticsLabel('Jane, Thanks, 09:13, Not sent'), findsOneWidget);
      expect(find.bySemanticsLabel('sent'), findsNothing);
      handle.dispose();
    });
  });
}
