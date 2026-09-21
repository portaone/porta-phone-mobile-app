import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/view_params/view_params.dart';

import '../../helpers/helpers.dart';
import 'conversation_screen_harness.dart';

class MockUnreadCountCubit extends MockCubit<UnreadCountState> implements UnreadCountCubit {}

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
        harness.wrap(
          const DialogChatInfo(
            'user-1',
            'user-2',
            isAudioCallEnabled: true,
            isVideoCallEnabled: true,
            isMuteEnabled: false,
          ),
        ),
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
      await tester.pumpWidget(harness.wrap(const GroupChatInfo('user-1', isMuteEnabled: false)));
      await settle(tester);

      final l10n = tester.element(find.byType(GroupChatInfo)).l10n;
      expect(find.text(l10n.messaging_GroupInfo_title), findsOneWidget);
      expect(find.text('Team'), findsOneWidget);
      expect(visibleTexts(tester).where((text) => text.startsWith('id:')), isEmpty);
      expect(find.textContaining('42'), findsNothing);
    });

    testWidgets('a group without a name is titled from its number, the same as everywhere else', (tester) async {
      harness.withGroupReady(chatId: 42, name: null);
      await tester.pumpWidget(harness.wrap(const GroupChatInfo('user-1', isMuteEnabled: false)));
      await settle(tester);

      // The name field is left empty for the user to fill; the avatar takes
      // its letters from the shared title, not from the bare number.
      expect(tester.widget<GroupAvatar>(find.byType(GroupAvatar)).name, 'Group 42');
      expect(visibleTexts(tester).where((text) => text.startsWith('id:')), isEmpty);
      expect(visibleTexts(tester).where((text) => text.trim() == '42'), isEmpty);
    });
  });

  group('Conversation list, a group row', () {
    testWidgets('an unnamed group is titled from its number, not "Chat N"', (tester) async {
      final unreadCount = MockUnreadCountCubit();
      when(() => unreadCount.state).thenReturn(UnreadCountState.initial());
      await tester.pumpWidget(
        harness.wrap(
          BlocProvider<UnreadCountCubit>.value(
            value: unreadCount,
            child: Scaffold(
              body: ChatConversationsTile(
                conversation: groupChat(id: 7, name: null),
                lastMessage: null,
                userId: 'user-1',
              ),
            ),
          ),
        ),
      );
      await settle(tester);

      expect(find.text('Group 7'), findsOneWidget);
      expect(find.textContaining('Chat 7'), findsNothing);
      expect(tester.widget<GroupAvatar>(find.byType(GroupAvatar)).name, 'Group 7');
    });
  });

  // The row is offered only where the core can answer it, and shows the mute
  // in force now - not the stored one, which outlives a timed mute.
  group('the Notifications row', () {
    final at = DateTime(2026, 9, 21, 12);

    Future<void> pumpDialog(WidgetTester tester, {bool isMuteEnabled = true}) async {
      harness.withDialogReady(chatId: 6);
      await tester.pumpWidget(
        harness.wrap(
          DialogChatInfo(
            'user-1',
            'user-2',
            isAudioCallEnabled: true,
            isVideoCallEnabled: true,
            isMuteEnabled: isMuteEnabled,
          ),
        ),
      );
      await settle(tester);
    }

    testWidgets('is absent on a core without the mute', (tester) async {
      await pumpDialog(tester, isMuteEnabled: false);

      expect(find.bySemanticsIdentifier(chatInfoNotificationsId), findsNothing);
      expect(find.text('Notifications'), findsNothing);
    });

    testWidgets('is present in the contact info and in the group info once the core has it', (tester) async {
      await pumpDialog(tester);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('On'), findsOneWidget);

      harness.withGroupReady(chatId: 42);
      await tester.pumpWidget(harness.wrap(const GroupChatInfo('user-1', isMuteEnabled: true)));
      await settle(tester);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('On'), findsOneWidget);
    });

    testWidgets('says muted, and until when, for a mute in force', (tester) async {
      harness.withChatMute(6, const NotificationMute(muted: true));
      await pumpDialog(tester);
      expect(find.text('Muted'), findsOneWidget);

      // The wording of the moment is pinned on the function itself, where the
      // clock can be fixed; a widget build runs outside a test's clock zone.
      harness.withChatMute(6, NotificationMute(muted: true, mutedUntil: DateTime.now().add(const Duration(hours: 6))));
      await pumpDialog(tester);
      expect(find.textContaining('Muted until '), findsOneWidget);
    });

    testWidgets('a mute that has lapsed reads as on, whatever is stored', (tester) async {
      // The stored value still says muted until an hour ago; the cubit has
      // taken it out of the set, and the row follows the set.
      when(() => harness.userSettingsCubit.state).thenReturn(
        ConversationUserSettingsState(
          chatSettings: {
            6: ConversationUserSettings(
              mute: NotificationMute(muted: true, mutedUntil: at.subtract(const Duration(hours: 1))),
            ),
          },
        ),
      );
      await pumpDialog(tester);

      expect(find.text('On'), findsOneWidget);
      expect(find.textContaining('Muted'), findsNothing);
    });

    testWidgets('opens the sheet, and a choice reaches the cubit', (tester) async {
      final handle = tester.ensureSemantics();
      when(() => harness.conversationCubit.muteFor(any())).thenAnswer((_) async {});
      when(() => harness.conversationCubit.unmute()).thenAnswer((_) async {});
      await pumpDialog(tester);

      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(chatInfoNotificationsId),
        identifier: chatInfoNotificationsId,
      );
      await tapViaSemantics(tester, find.bySemanticsIdentifier(chatInfoNotificationsId));
      await settle(tester);

      expect(find.bySemanticsIdentifier(notificationMuteSheetId), findsOneWidget);
      // Nothing is muted, so there is nothing to unmute.
      expect(find.bySemanticsIdentifier(notificationMuteOptionId(MuteChoice.unmute)), findsNothing);
      await tapViaSemantics(tester, find.bySemanticsIdentifier(notificationMuteOptionId(MuteChoice.eightHours)));
      await settle(tester);

      verify(() => harness.conversationCubit.muteFor(const Duration(hours: 8))).called(1);
      expect(find.bySemanticsIdentifier(notificationMuteSheetId), findsNothing);

      handle.dispose();
    });

    testWidgets('offers the way back first while a mute is in force', (tester) async {
      final handle = tester.ensureSemantics();
      harness.withChatMute(6, const NotificationMute(muted: true));
      when(() => harness.conversationCubit.unmute()).thenAnswer((_) async {});
      await pumpDialog(tester);

      await tapViaSemantics(tester, find.bySemanticsIdentifier(chatInfoNotificationsId));
      await settle(tester);
      await tapViaSemantics(tester, find.bySemanticsIdentifier(notificationMuteOptionId(MuteChoice.unmute)));
      await settle(tester);

      verify(() => harness.conversationCubit.unmute()).called(1);
      verifyNever(() => harness.conversationCubit.muteFor(any()));

      handle.dispose();
    });

    testWidgets('leaves nothing on the info unnamed', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDialog(tester);

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });
  });

  // The mark in the list follows what is muted now, and needs no capability
  // check of its own: a mute can only be stored where the core reports one.
  group('Conversation list, the muted mark', () {
    Future<void> pumpTile(WidgetTester tester, Chat chat) async {
      final unreadCount = MockUnreadCountCubit();
      when(() => unreadCount.state).thenReturn(UnreadCountState.initial());
      await tester.pumpWidget(
        harness.wrap(
          BlocProvider<UnreadCountCubit>.value(
            value: unreadCount,
            child: PresenceViewParams(
              hybridPresenceSupport: false,
              blfViaSipSupport: false,
              presenceViaSipSupport: false,
              child: Scaffold(
                body: ChatConversationsTile(conversation: chat, lastMessage: null, userId: 'user-1'),
              ),
            ),
          ),
        ),
      );
      await settle(tester);
    }

    testWidgets('a group row carries it while muted, and says so', (tester) async {
      final handle = tester.ensureSemantics();
      harness.withChatMute(7, const NotificationMute(muted: true));
      await pumpTile(tester, groupChat(id: 7, name: 'Team'));

      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
      // The row merges its words into one node; the mark's word is among them.
      expect(find.bySemanticsLabel(RegExp('Muted')), findsOneWidget);

      handle.dispose();
    });

    testWidgets('a dialog row carries it too', (tester) async {
      harness.withNoContactCards();
      harness.withChatMute(6, const NotificationMute(muted: true));
      await pumpTile(tester, dialogChat(id: 6));

      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
    });

    testWidgets('a row without a mute carries nothing', (tester) async {
      harness.withChatMute(8, const NotificationMute(muted: true));
      await pumpTile(tester, groupChat(id: 7, name: 'Team'));

      expect(find.byIcon(Icons.notifications_off_outlined), findsNothing);
    });
  });
}
