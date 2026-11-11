import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/data/app_time.dart';
import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/screen_presets.dart';
import '../../helpers/semantics.dart';

final _now = DateTime(2026, 11, 10, 22, 31);

final _thread = [
  const ConversationWatchMessage(key: 'out', text: 'On my way', mine: true, mark: ConversationWatchMark.pending),
  ConversationWatchMessage(
    key: 'm2',
    text: 'Got it, thanks',
    mine: true,
    time: _now.add(const Duration(minutes: 9)),
    mark: ConversationWatchMark.read,
  ),
  ConversationWatchMessage(key: 'm1', text: 'wt2081 a8 after-reboot #1', mine: false, time: _now, senderId: 'peer'),
];

void main() {
  Widget app(Widget thread) => ThemeProvider(
    settings: const ThemeSettings(),
    lightDynamic: null,
    darkDynamic: null,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Provider<AppTime>.value(
        value: AppTime(is24HourFormat: true),
        child: Scaffold(body: thread),
      ),
    ),
  );

  for (final preset in watchPresets) {
    testWidgets('on $preset the newest message sits at the bottom, above Reply, the name at the top', (tester) async {
      preset.apply(tester);
      expect(
        await pumpCollectingOverflows(
          tester,
          app(ConversationWatchThread(title: 'Yaroslav Zhuk', messages: _thread, onSend: (_) {})),
        ),
        isEmpty,
      );

      final newest = tester.getRect(find.text('On my way'));
      final older = tester.getRect(find.text('Got it, thanks'));
      expect(newest.top, greaterThan(older.top));
      expect(newest.bottom, lessThan(tester.getRect(find.bySemanticsIdentifier(conversationWatchReplyId)).top));
      expect(find.byType(WatchBubble), findsWidgets);
    });
  }

  testWidgets('Reply opens the keyboard; its send key posts the message, trimmed, and clears it', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    final sent = <String>[];
    await tester.pumpWidget(app(ConversationWatchThread(title: 'Yaroslav', messages: _thread, onSend: sent.add)));

    await tapViaSemantics(tester, find.bySemanticsIdentifier(conversationWatchReplyId));
    await tester.enterText(find.byKey(conversationWatchReplyInputKey), '  on my way  ');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(sent, ['on my way']);
    expect(tester.widget<TextField>(find.byKey(conversationWatchReplyInputKey)).controller!.text, isEmpty);

    // Nothing typed, nothing sent.
    await tapViaSemantics(tester, find.bySemanticsIdentifier(conversationWatchReplyId));
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    expect(sent, hasLength(1));
    handle.dispose();
  });

  testWidgets('the other side\'s newest message is marked read once, when the thread shows', (tester) async {
    watchPresets.first.apply(tester);
    final read = <DateTime>[];
    await tester.pumpWidget(
      app(ConversationWatchThread(title: 'Yaroslav', messages: _thread, onSend: (_) {}, onRead: read.add)),
    );
    await tester.pump();
    await tester.pumpWidget(
      app(ConversationWatchThread(title: 'Yaroslav', messages: [..._thread], onSend: (_) {}, onRead: read.add)),
    );
    await tester.pump();

    expect(read, [_now]);
  });

  testWidgets('a thread read up to its newest message elsewhere is not marked again', (tester) async {
    watchPresets.first.apply(tester);
    final read = <DateTime>[];
    await tester.pumpWidget(
      app(
        ConversationWatchThread(
          title: 'Yaroslav',
          messages: _thread,
          onSend: (_) {},
          onRead: read.add,
          readUntil: _now,
        ),
      ),
    );
    await tester.pump();

    expect(read, isEmpty);
  });

  testWidgets('in a group the sender is named over their bubble', (tester) async {
    watchPresets.first.apply(tester);
    await tester.pumpWidget(
      app(
        ConversationWatchThread(
          title: 'Team',
          messages: [_thread.last],
          onSend: (_) {},
          senderName: (context, senderId, bubble) => bubble('Jane Smith'),
        ),
      ),
    );

    expect(find.text('Jane Smith'), findsOneWidget);
  });

  testWidgets('a new message keeps every sender name over its own message', (tester) async {
    watchPresets.first.apply(tester);
    // A name looked up once, as the contact lookup does: its state must
    // follow its message when a new one takes the bottom row.
    Widget thread(List<ConversationWatchMessage> messages) => app(
      ConversationWatchThread(
        title: 'Team',
        messages: messages,
        onSend: (_) {},
        senderName: (context, senderId, bubble) => _LookedUpName(senderId: senderId, bubble: bubble),
      ),
    );
    final jane = ConversationWatchMessage(key: 'j', text: 'from Jane', mine: false, time: _now, senderId: 'Jane');
    final omar = ConversationWatchMessage(key: 'o', text: 'from Omar', mine: false, time: _now, senderId: 'Omar');
    final lena = ConversationWatchMessage(key: 'l', text: 'from Lena', mine: false, time: _now, senderId: 'Lena');

    await tester.pumpWidget(thread([omar, jane]));
    await tester.pumpWidget(thread([lena, omar, jane]));

    for (final name in ['Jane', 'Omar', 'Lena']) {
      final bubble = find.ancestor(
        of: find.text('from $name', skipOffstage: false),
        matching: find.byType(WatchBubble, skipOffstage: false),
      );
      expect(find.descendant(of: bubble, matching: find.text(name, skipOffstage: false)), findsOneWidget);
    }
  });

  testWidgets('a message the network refused says so under it', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    await tester.pumpWidget(
      app(
        ConversationWatchThread(
          title: '+1 202 555 0143',
          messages: [ConversationWatchMessage(key: 's', text: 'Thanks', mine: true, time: _now, note: 'Failed')],
          onSend: (_) {},
        ),
      ),
    );

    expect(find.text('Failed'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^You, Thanks, .*Failed$')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a delivered SMS is said delivered, not read', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    await tester.pumpWidget(
      app(
        ConversationWatchThread(
          title: '+1 202 555 0143',
          messages: [
            ConversationWatchMessage(
              key: 's',
              text: 'Thanks',
              mine: true,
              time: _now,
              mark: ConversationWatchMark.delivered,
            ),
          ],
          onSend: (_) {},
        ),
      ),
    );

    expect(find.bySemanticsLabel(RegExp(r'^You, Thanks, .*Delivered$')), findsOneWidget);
    expect(find.byIcon(Icons.done_all), findsOneWidget);
    handle.dispose();
  });

  for (final preset in watchPresets) {
    testWidgets('on $preset no messages is a state page with Reply on the edge', (tester) async {
      preset.apply(tester);
      var sent = 0;
      expect(
        await pumpCollectingOverflows(
          tester,
          app(ConversationWatchThread(title: 'Yaroslav Zhuk', messages: const [], onSend: (_) => sent++)),
        ),
        isEmpty,
      );

      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.bySemanticsIdentifier(conversationWatchReplyId), findsOneWidget);
    });
  }

  testWidgets('on its way a loading page; failed, Try again on the edge', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    await tester.pumpWidget(app(ConversationWatchThread(title: 'Yaroslav', messages: null, onSend: (_) {})));
    expect(find.byType(WatchSpinner), findsOneWidget);

    var retried = 0;
    await tester.pumpWidget(
      app(
        ConversationWatchThread(
          title: 'Yaroslav',
          messages: null,
          failed: true,
          onRetry: () => retried++,
          onSend: (_) {},
        ),
      ),
    );
    await tester.tap(find.byType(OutlinedButton));
    expect(retried, 1);
    handle.dispose();
  });

  testWidgets('a first page too short to scroll asks for the older messages', (tester) async {
    watchPresets.first.apply(tester);
    var fetched = 0;
    await tester.pumpWidget(
      app(
        ConversationWatchThread(
          title: 'Yaroslav',
          messages: [_thread.last],
          onSend: (_) {},
          onFetchHistory: () => fetched++,
        ),
      ),
    );
    await tester.pump();

    expect(fetched, greaterThan(0));
  });

  testWidgets('a screen reader hears whose a message is and where it stands', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    await tester.pumpWidget(app(ConversationWatchThread(title: 'Yaroslav', messages: [_thread[1]], onSend: (_) {})));

    expect(find.bySemanticsLabel(RegExp(r'^You, Got it, thanks, .*, Read$')), findsOneWidget);
    handle.dispose();
  });
}

/// The sender's name taken once, when the row is first built.
class _LookedUpName extends StatefulWidget {
  const _LookedUpName({required this.senderId, required this.bubble});

  final String senderId;
  final Widget Function(String name) bubble;

  @override
  State<_LookedUpName> createState() => _LookedUpNameState();
}

class _LookedUpNameState extends State<_LookedUpName> {
  late final _name = widget.senderId;

  @override
  Widget build(BuildContext context) => widget.bubble(_name);
}
