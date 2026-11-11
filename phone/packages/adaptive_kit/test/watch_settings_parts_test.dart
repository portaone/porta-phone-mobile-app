import 'package:material_ui/material_ui.dart';

import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_kit/adaptive_kit.dart';

import 'helpers/screen_presets.dart';

void main() {
  Widget wrap(Widget body) => MaterialApp(
    home: Scaffold(
      body: ListView(padding: const EdgeInsets.all(24), children: [body]),
    ),
  );

  group('WatchListLabel', () {
    testWidgets('drawn in capitals, read as the words and as a heading', (tester) async {
      final handle = tester.ensureSemantics();
      watchPresets.first.apply(tester);
      await tester.pumpWidget(wrap(const WatchListLabel('Services')));

      expect(find.text('SERVICES'), findsOneWidget);
      final node = find.semantics.byLabel('Services').evaluate().single;
      expect(node.flagsCollection.isHeader, isTrue);
      handle.dispose();
    });

    for (final preset in watchPresets) {
      testWidgets('on $preset a long label stays inside the face', (tester) async {
        preset.apply(tester);
        expect(
          await pumpCollectingOverflows(tester, wrap(const WatchListLabel('A section with a rather long title'))),
          isEmpty,
        );
      });
    }
  });

  group('WatchToggleChip subtitle', () {
    testWidgets('the line under the label is part of the one node with the state', (tester) async {
      final handle = tester.ensureSemantics();
      watchPresets.first.apply(tester);
      bool? changed;
      await tester.pumpWidget(
        wrap(
          WatchToggleChip(
            label: 'Online',
            subtitle: 'Account can receive calls',
            value: true,
            identifier: 'online',
            onChanged: (value) => changed = value,
          ),
        ),
      );

      expect(find.text('Account can receive calls'), findsOneWidget);
      final node = find.semantics.byPredicate((node) => node.identifier == 'online').evaluate().single;
      expect(node.label, contains('Online'));
      expect(node.label, contains('Account can receive calls'));
      expect(node.flagsCollection.isToggled, Tristate.isTrue);

      await tester.tap(find.text('Online'));
      expect(changed, isFalse);
      handle.dispose();
    });

    for (final preset in watchPresets) {
      testWidgets('on $preset a two-line subtitle fits the pill', (tester) async {
        preset.apply(tester);
        expect(
          await pumpCollectingOverflows(
            tester,
            wrap(
              WatchToggleChip(
                label: 'Online',
                subtitle: 'Waiting for connection to the server before it can change',
                value: false,
                onChanged: null,
              ),
            ),
          ),
          isEmpty,
        );
      });
    }
  });

  group('WatchInfoRow', () {
    testWidgets('the label, then the value as a node of its own carrying its id', (tester) async {
      final handle = tester.ensureSemantics();
      watchPresets.first.apply(tester);
      await tester.pumpWidget(wrap(const WatchInfoRow(label: 'Core version', value: '1.9.2', valueIdentifier: 'core')));

      expect(find.bySemanticsLabel('Core version'), findsOneWidget);
      final value = find.semantics.byLabel('1.9.2').evaluate().single;
      expect(value.identifier, 'core');
      handle.dispose();
    });

    for (final preset in watchPresets) {
      testWidgets('on $preset a long value wraps inside the face', (tester) async {
        preset.apply(tester);
        expect(
          await pumpCollectingOverflows(
            tester,
            wrap(
              const WatchInfoRow(
                label: 'FCM token',
                value: 'fZ2kQm9xT0aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789abcdefghijklmnopqrstuvwxyz',
              ),
            ),
          ),
          isEmpty,
        );
      });
    }
  });

  testWidgets('a read-only WatchListTile is drawn at full strength and read as text, not a button', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    await tester.pumpWidget(
      wrap(const WatchListTile(title: 'Pixel Watch 3', subtitle: 'Active now', readOnly: true, selected: true)),
    );

    expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 1);
    final node = find.semantics.byLabel('Pixel Watch 3, Active now').evaluate().single;
    expect(node.flagsCollection.isButton, isFalse);
    handle.dispose();
  });

  group('WatchNoticeCard', () {
    for (final preset in watchPresets) {
      testWidgets('on $preset the title, three lines of the text and the time stay inside the face', (tester) async {
        preset.apply(tester);
        expect(
          await pumpCollectingOverflows(
            tester,
            wrap(
              WatchNoticeCard(
                leading: const Icon(Icons.campaign_outlined),
                title: 'Scheduled maintenance tonight',
                body: 'Calls may drop on Sunday 02:00-03:00 while the service is updated. Messages are kept. ' * 3,
                time: '14:02',
                unread: true,
                onTap: () {},
              ),
            ),
          ),
          isEmpty,
        );
        final body = tester.widget<Text>(find.textContaining('Calls may drop'));
        expect(body.maxLines, 3);
      });
    }

    testWidgets('one node: title, text and time, a tap and a long press; the long press does what it is given, named', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      watchPresets.first.apply(tester);
      var opened = 0;
      var deleted = 0;
      await tester.pumpWidget(
        wrap(
          WatchNoticeCard(
            title: 'New feature',
            body: 'Voicemail can be forwarded.',
            time: 'Mon',
            onTap: () => opened++,
            onLongPress: () => deleted++,
            longPressHint: 'Delete',
          ),
        ),
      );

      final node = find.semantics.byLabel('New feature, Voicemail can be forwarded., Mon').evaluate().single;
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(node.getSemanticsData().hasAction(SemanticsAction.longPress), isTrue);
      expect(node.flagsCollection.isButton, isTrue);
      await tester.tap(find.text('New feature'));
      await tester.longPress(find.text('New feature'));
      expect((opened, deleted), (1, 1));
      handle.dispose();
    });
  });
}
