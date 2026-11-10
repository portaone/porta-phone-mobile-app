import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The conversations on a watch: the section's title, one row of the search
/// and the list pill (Messages, SMS - in place of the tabs), the bar, and a
/// row per conversation; New chat (New SMS) closes the list. No app bar, no
/// floating button, no swipe: deleting or leaving a conversation stays on the
/// phone.
///
/// On its way the list is a loading page, saying how the chat connection
/// stands while it is not up; with no conversations, a state page with the
/// pill under it and New chat on the edge; a search that finds nothing stays
/// the list, a line saying so, so the field being typed in is not rebuilt.
class ConversationsWatchBody extends StatelessWidget {
  const ConversationsWatchBody({
    super.key,
    required this.section,
    required this.query,
    required this.onSearch,
    required this.onNew,
  });

  final WatchSection<ConversationsTab> section;

  /// What the list is narrowed by.
  final String query;

  final ValueChanged<String> onSearch;

  /// Starts a conversation of the kind shown.
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tab = section.selected;
    final chip = section.choosable ? ConversationsWatchListChip(section: section) : null;
    // A short word on the face; the pill's full name for a screen reader.
    final (newLabel, newName) = switch (tab) {
      ConversationsTab.chat => (l10n.messaging_Watch_newChat, l10n.messaging_SemanticsLabel_newChat),
      ConversationsTab.sms => (l10n.messaging_Watch_newSms, l10n.messaging_SemanticsLabel_newSms),
    };
    final header = [
      WatchSearchRow(
        initialQuery: query,
        onChanged: onSearch,
        chooser: chip == null ? null : ({required round}) => ConversationsWatchListChip(section: section, round: round),
        searchLabel: switch (tab) {
          ConversationsTab.chat => l10n.messaging_Watch_search,
          ConversationsTab.sms => l10n.messaging_Watch_searchSms,
        },
        clearLabel: l10n.contacts_SemanticsLabel_clearSearch,
        fieldKey: conversationsSearchInputKey,
        searchIdentifier: conversationsSearchInputId,
        clearKey: conversationsSearchInputClearKey,
        clearIdentifier: conversationsSearchInputClearId,
      ),
      const WatchSeparator(),
    ];

    // Whether there is any conversation is asked of the whole list, not of
    // the rows the search left: the lists narrow a moment after the query
    // changes, so the letter that clears the query would otherwise find no
    // rows yet, show the empty page and close the keyboard with its field.
    final (loading, none, count, IndexedWidgetBuilder tile) = switch (tab) {
      ConversationsTab.chat => switch (context.watch<ChatConversationsCubit>().state) {
        final state => (
          state.initialising,
          state.conversations.isEmpty,
          state.conversationsToShow.length,
          (context, index) {
            final item = state.conversationsToShow[index];
            return ChatConversationsWatchTile(key: ValueKey(item.chat.id), chat: item.chat, message: item.message);
          },
        ),
      },
      ConversationsTab.sms => switch (context.watch<SmsConversationsCubit>().state) {
        final state => (
          state.initialising,
          state.conversations.isEmpty,
          state.conversationsToShow.length,
          (context, index) {
            final (conversation, message) = state.conversationsToShow[index];
            return SmsConversationsWatchTile(
              key: ValueKey(conversation.id),
              conversation: conversation,
              message: message,
            );
          },
        ),
      },
    };
    final status = context.select((MessagingBloc bloc) => bloc.state.status);

    if (loading) {
      return WatchStatePage.loading(
        title: section.title,
        footer: [?chip],
        hint: status.l10n(l10n),
        progressLabel: l10n.common_SemanticsLabel_loading,
      );
    }

    if (none) {
      return WatchStatePage(
        title: section.title,
        footer: [?chip],
        icon: const Icon(Icons.chat_bubble_outline),
        message: l10n.messaging_ConversationsScreen_empty,
        hint: status.l10n(l10n),
        action: WatchAction(label: newLabel, identifier: conversationsNewId, onPressed: onNew),
      );
    }

    return WatchScrollList.builder(
      title: section.title,
      header: header,
      spacing: context.adaptiveMetrics.gap,
      itemCount: count + 1,
      itemBuilder: (context, index) {
        if (index < count) return tile(context, index);
        if (count == 0) return WatchListNote(l10n.messaging_Watch_notFound);
        return WatchPillButton(
          identifier: conversationsNewId,
          icon: Icons.add,
          label: newLabel,
          semanticsLabel: newName,
          onPressed: onNew,
        );
      },
    );
  }
}

/// The list pill of the conversations on a watch, in place of the tabs: one
/// pill naming the list shown, Messages or SMS; a tap shows the other.
class ConversationsWatchListChip extends StatelessWidget {
  const ConversationsWatchListChip({super.key, required this.section, this.round = false});

  final WatchSection<ConversationsTab> section;

  /// Only the list's icon, in a round button: beside a query, which takes the
  /// rest of the row.
  final bool round;

  @override
  Widget build(BuildContext context) {
    final tab = section.selected;
    final label = tab.l10n(context.l10n);
    // What the pill is as well as what it shows, as the contacts' source pill.
    final name = '${context.l10n.messaging_Watch_list}: $label';
    final icon = switch (tab) {
      ConversationsTab.chat => Icons.chat_bubble_outline,
      ConversationsTab.sms => Icons.sms_outlined,
    };
    void showNext() => section.onSelected(section.next);

    if (round) {
      return WatchRoundButton(
        buttonKey: conversationsWatchListKey,
        identifier: conversationsWatchListId,
        label: name,
        icon: Icon(icon),
        size: WatchPill.height,
        width: WatchPill.height,
        onPressed: showNext,
      );
    }
    return WatchPillButton(
      buttonKey: conversationsWatchListKey,
      identifier: conversationsWatchListId,
      icon: icon,
      label: label,
      semanticsLabel: name,
      onPressed: showNext,
    );
  }
}

/// One chat in a list on a watch: the avatar, the name (or the group's), the
/// last message, and the unread count at the end. A tap opens the chat.
class ChatConversationsWatchTile extends StatelessWidget {
  const ChatConversationsWatchTile({super.key, required this.chat, required this.message});

  final Chat chat;
  final ChatMessage? message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userId = context.select((MessagingBloc bloc) => bloc.state.userId);
    final count = context.select((UnreadCountCubit cubit) => cubit.state.unreadCountForChatConversation(chat.id));
    final preview = switch (message) {
      null => l10n.messaging_Conversations_tile_empty,
      final message when message.deletedAt != null => l10n.messaging_MessageView_deleted,
      final message => message.content,
    };

    if (chat.type == ChatType.group) {
      final title = chat.title(l10n);
      return _ConversationWatchTile(
        title: title,
        preview: preview,
        count: count,
        leading: GroupAvatar(name: title, size: 12),
        onTap: () => context.router.navigate(ChatConversationScreenPageRoute(chatId: chat.id)),
      );
    }

    final participant = chat.members.firstWhereOrNull((member) => member.userId != userId);
    return ContactInfoBuilder(
      source: ContactSourceId(ContactSourceType.external, participant?.userId ?? ''),
      builder: (context, contact) {
        final name = contact?.displayTitle ?? l10n.messaging_ParticipantName_unknown;
        return _ConversationWatchTile(
          title: name,
          preview: preview,
          count: count,
          leading: WatchContactAvatar(contact: contact),
          onTap: participant == null
              ? null
              : () => context.router.navigate(ChatConversationScreenPageRoute(participantId: participant.userId)),
        );
      },
    );
  }
}

/// One SMS conversation in a list on a watch: the other number, the last
/// message, and the unread count at the end. A tap opens the conversation.
class SmsConversationsWatchTile extends StatelessWidget {
  const SmsConversationsWatchTile({super.key, required this.conversation, required this.message});

  final SmsConversation conversation;
  final SmsMessage? message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final count = context.select(
      (UnreadCountCubit cubit) => cubit.state.unreadCountForSmsConversation(conversation.id),
    );
    final first = conversation.firstPhoneNumber;
    final second = conversation.secondPhoneNumber;

    return UserSmsNumbersBuilder(
      builder: (context, numbers, {required loading}) {
        // The number that is not one of the user's own is the other side.
        final recipient = numbers.contains(first) ? second : first;
        return _ConversationWatchTile(
          title: recipient,
          preview: message?.content ?? l10n.messaging_Conversations_tile_empty,
          count: count,
          // The last two digits, as on the phone's row; a shorter number whole.
          leading: LeadingAvatar(username: recipient.substring(math.max(0, recipient.length - 2)), radius: 12),
          onTap: () =>
              context.router.navigate(SmsConversationScreenPageRoute(firstNumber: first, secondNumber: second)),
        );
      },
    );
  }
}

/// The row both kinds of conversation share: a list tile with the unread
/// count as its trailing mark and in its name for a screen reader.
class _ConversationWatchTile extends StatelessWidget {
  const _ConversationWatchTile({
    required this.title,
    required this.preview,
    required this.count,
    required this.leading,
    required this.onTap,
  });

  final String title;
  final String preview;
  final int count;
  final Widget leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return WatchListTile(
      title: title,
      subtitle: preview,
      semanticsLabel: count == 0 ? null : '$title, $preview, ${context.l10n.common_SemanticsValue_unreadCount(count)}',
      leading: leading,
      trailing: count == 0 ? null : CountBadge(count: count),
      onTap: onTap,
    );
  }
}

extension on ConnectionStatus {
  /// What the face says of the chat connection while it is not up: a line
  /// of its own, not the phone's capitalised state bar.
  String? l10n(AppLocalizations l10n) => switch (this) {
    ConnectionStatus.initial => l10n.messaging_Watch_statusInitializing,
    ConnectionStatus.connecting => l10n.messaging_Watch_statusConnecting,
    ConnectionStatus.error => l10n.messaging_Watch_statusDisconnected,
    _ => null,
  };
}
