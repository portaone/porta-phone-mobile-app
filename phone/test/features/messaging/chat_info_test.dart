import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/messaging/features/chat_conversation/widgets/dialog_info.dart';
import 'package:webtrit_phone/features/messaging/features/chat_conversation/widgets/group_info.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

import 'conversation_screen_harness.dart';

void main() {
  late ConversationScreenHarness harness;

  setUpAll(() => registerFallbackValue(ContactSourceType.external));
  setUp(() => harness = ConversationScreenHarness());

  /// Every piece of text on the screen, as the eye and a screen reader get it.
  Iterable<String> visibleTexts(WidgetTester tester) =>
      tester.widgetList<Text>(find.byType(Text)).map((text) => text.data ?? text.textSpan?.toPlainText() ?? '');

  /// The screens carry a progress indicator somewhere, so settling is given
  /// a length rather than waited out.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('Contact info', () {
    testWidgets('shows who it is and not the chat record id', (tester) async {
      // WT-1884: an "id: N" line - the chat's id on the messaging backend -
      // was printed under the name, small and right-aligned, and read out by
      // screen readers. It is nothing to the user.
      harness.withDialogReady(chatId: 6);
      await tester.pumpWidget(
        harness.wrap(const DialogChatInfo('user-1', 'user-2', isAudioCallEnabled: true, isVideoCallEnabled: true)),
      );
      await settle(tester);

      final l10n = tester.element(find.byType(DialogChatInfo)).l10n;
      expect(find.text(l10n.messaging_DialogInfo_title), findsOneWidget);
      expect(find.text(l10n.messaging_ParticipantName_unknown), findsOneWidget);
      expect(visibleTexts(tester).where((text) => text.startsWith('id:')), isEmpty);
      expect(find.textContaining('6'), findsNothing);
    });
  });

  group('Group info', () {
    testWidgets('shows the group and not its record id', (tester) async {
      harness.withGroupReady(chatId: 42, name: 'Team');
      await tester.pumpWidget(harness.wrap(const GroupChatInfo('user-1')));
      await settle(tester);

      final l10n = tester.element(find.byType(GroupChatInfo)).l10n;
      expect(find.text(l10n.messaging_GroupInfo_title), findsOneWidget);
      expect(find.text('Team'), findsOneWidget);
      expect(visibleTexts(tester).where((text) => text.startsWith('id:')), isEmpty);
      expect(find.textContaining('42'), findsNothing);
    });
  });
}
