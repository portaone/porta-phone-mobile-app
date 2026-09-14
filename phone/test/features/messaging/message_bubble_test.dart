import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/messaging/widgets/message_view/chat_message_view.dart';
import 'package:webtrit_phone/features/messaging/widgets/message_view/message_bubble.dart';
import 'package:webtrit_phone/features/messaging/widgets/message_view/sms_message_view.dart';
import 'package:webtrit_phone/l10n/app_localizations.g.dart';
import 'package:webtrit_phone/models/models.dart';

void main() {
  final created = DateTime(2026, 9, 1, 12);

  ChatMessage chatMessage({required String sender, String content = 'Hi'}) => ChatMessage(
    id: 1,
    idKey: 'm1',
    senderId: sender,
    chatId: 6,
    replyToId: null,
    forwardFromId: null,
    authorId: null,
    content: content,
    createdAt: created,
    updatedAt: created,
    editedAt: null,
    deletedAt: null,
  );

  SmsMessage smsMessage({required String from, String content = 'Hi'}) => SmsMessage(
    id: 1,
    idKey: 's1',
    externalId: 'x1',
    conversationId: 3,
    fromPhoneNumber: from,
    toPhoneNumber: from == '111' ? '222' : '111',
    sendingStatus: SmsSendingStatus.delivered,
    content: content,
    createdAt: created,
    updatedAt: created,
    deletedAt: null,
  );

  Widget app(Widget row) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: ListView(children: [row])),
  );

  Widget chatRow(ChatMessage message) => ChatMessageView(
    userId: 'me',
    message: message,
    handleSetForReply: (_) {},
    handleSetForForward: (_) {},
    handleSetForEdit: (_) {},
    handleDelete: (_) {},
  );

  Widget smsRow(SmsMessage message) => SmsMessageView(userNumber: '111', message: message, handleDelete: (_) {});

  /// The one node a screen reader lands on for the bubble: the node that
  /// offers the long press, taken from the traversal a reader would make.
  SemanticsNode? nodeWithLongPress(WidgetTester tester) => tester.semantics
      .simulatedAccessibilityTraversal()
      .where((node) => node.getSemanticsData().hasAction(SemanticsAction.longPress))
      .firstOrNull;

  SemanticsNode longPressNode(WidgetTester tester) {
    final node = nodeWithLongPress(tester);
    expect(node, isNotNull, reason: 'the bubble offers a long press');
    return node!;
  }

  Rect globalRect(SemanticsNode node) => MatrixUtils.transformRect(node.transform ?? Matrix4.identity(), node.rect);

  final menuItems = find.byWidgetPredicate((widget) => widget is PopupMenuItem);

  /// Pumps the row and lets the fade-in finish; the semantics of what faded
  /// in arrive one frame after that.
  Future<void> pumpRow(WidgetTester tester, Widget row) async {
    await tester.pumpWidget(app(row));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> longPressAndSettle(WidgetTester tester, Offset at) async {
    await tester.longPressAt(at);
    // The handler puts the keyboard away and waits 400 ms before the menu.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  group('MessageBubble - what a screen reader lands on is what a finger presses', () {
    // WT-1885: a reader's double-tap-and-hold is a real touch at the centre
    // of the focused node. The node used to span the whole row, its centre
    // falling in the empty space beside a short bubble, where nothing
    // answered. Now the node is the bubble.
    for (final (label, sender) in [('an incoming', 'them'), ('an outgoing', 'me')]) {
      testWidgets('$label chat bubble: the node is the bubble, and its centre opens the menu', (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpRow(tester, chatRow(chatMessage(sender: sender)));

        final node = longPressNode(tester);
        final bubble = tester.getRect(
          find.descendant(of: find.byType(MessageBubble), matching: find.byType(Container)).first,
        );
        final nodeRect = globalRect(node);
        expect(
          nodeRect.width,
          lessThan(tester.getSize(find.byType(MessageBubble)).width / 2),
          reason: 'a short message makes a short node, not a row-wide one',
        );
        expect(bubble.contains(nodeRect.center), isTrue, reason: 'the node is where the bubble is drawn');
        expect(node.getSemanticsData().label, contains('Hi'));

        await longPressAndSettle(tester, nodeRect.center);
        expect(menuItems, findsWidgets);
        semantics.dispose();
      });
    }

    testWidgets('an SMS bubble behaves the same', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpRow(tester, smsRow(smsMessage(from: '222')));

      final nodeRect = globalRect(longPressNode(tester));
      await longPressAndSettle(tester, nodeRect.center);
      expect(menuItems, findsWidgets);
      semantics.dispose();
    });

    testWidgets('the accessibility long-press action opens the menu as well, and says what it does', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpRow(tester, chatRow(chatMessage(sender: 'them')));

      final node = longPressNode(tester);
      expect(node.hintOverrides?.onLongPressHint, 'open the message actions');

      node.owner!.performAction(node.id, SemanticsAction.longPress);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(menuItems, findsWidgets);
      semantics.dispose();
    });

    testWidgets('a bubble with nothing to offer offers no long press', (tester) async {
      final semantics = tester.ensureSemantics();
      // Somebody else's deleted message: nothing to copy, reply to, edit or delete.
      final deleted = ChatMessage(
        id: 2,
        idKey: 'm2',
        senderId: 'them',
        chatId: 6,
        replyToId: null,
        forwardFromId: null,
        authorId: null,
        content: '',
        createdAt: created,
        updatedAt: created,
        editedAt: null,
        deletedAt: created,
      );
      await pumpRow(tester, chatRow(deleted));

      expect(
        nodeWithLongPress(tester),
        isNull,
        reason: 'a promise of a long press that does nothing is worse than none',
      );
      semantics.dispose();
    });
  });
}
