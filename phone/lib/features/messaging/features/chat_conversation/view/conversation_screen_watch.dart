import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// A chat on a watch: the thread with Reply on the edge; no menu: the
/// conversation's details stay on the phone.
class ChatConversationScreenWatch extends StatelessWidget {
  const ChatConversationScreenWatch({super.key, required this.state, required this.userId});

  final ConversationState state;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    final l10n = context.l10n;
    ConversationWatchChat thread(String title) => ConversationWatchChat(state: state, title: title, userId: userId);
    final body = switch (state) {
      CVSReady(chat: Chat(:final name?)) => thread(name),
      _ when state.credentials.participantId != null => ContactInfoBuilder(
        source: ContactSourceId(ContactSourceType.external, state.credentials.participantId!),
        builder: (context, contact) => thread(contact?.displayTitle ?? l10n.messaging_ParticipantName_unknown),
      ),
      _ => switch ((state is CVSReady ? state.chat?.id : null) ?? state.credentials.chatId) {
        final id? => thread(l10n.messaging_GroupInfo_titlePrefix(id)),
        null => thread(''),
      },
    };
    return Scaffold(
      body: SemanticId(identifier: chatConversationScreenId, child: body),
    );
  }
}

/// A chat as a thread on a watch, under the [title] the screen worked out:
/// the messages newest first with the edits and deletions under way applied,
/// the group's senders by name, and the user's read cursor moved on as the
/// other side's messages come into view.
class ConversationWatchChat extends StatelessWidget {
  const ConversationWatchChat({super.key, required this.state, required this.title, required this.userId});

  final ConversationState state;
  final String title;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ConversationCubit>();
    final state = this.state;
    return ConversationWatchThread(
      title: title,
      messages: state is CVSReady ? _messages(context, state) : null,
      failed: state is CVSError,
      onRetry: cubit.restart,
      onSend: cubit.sendMessage,
      onTyping: context.read<ChatTypingCubit>().sendTyping,
      onFetchHistory: state is CVSReady && !state.historyEndReached && !state.fetchingHistory
          ? cubit.fetchHistory
          : null,
      onRead: cubit.userReadedUntilUpdate,
      readUntil: state is CVSReady ? state.readCursors.userReadedUntil(userId) : null,
      senderName: state is CVSReady && state.chat?.type == ChatType.group
          ? (context, senderId, bubble) => ContactInfoBuilder(
              source: ContactSourceId(ContactSourceType.external, senderId),
              builder: (context, contact) => bubble(contact?.displayTitle ?? l10n.messaging_ParticipantName_unknown),
            )
          : null,
      maxLength: kAppMessagingMaxLength,
    );
  }

  /// Newest first, as the thread draws them: what is still going out, then
  /// what the server has, with the edits and deletions under way applied.
  List<ConversationWatchMessage> _messages(BuildContext context, CVSReady state) {
    final l10n = context.l10n;
    final readByOthers = state.readCursors.participantsReadedUntil(userId);
    final outgoing = {for (final entry in state.outboxMessages) entry.idKey};
    final edits = {for (final entry in state.outboxMessageEdits) entry.idKey: entry.newContent};
    final deletes = {for (final entry in state.outboxMessageDeletes) entry.idKey};
    final group = state.chat?.type == ChatType.group;

    return [
      for (final entry in state.outboxMessages.reversed)
        ConversationWatchMessage(
          key: entry.idKey,
          text: entry.content,
          mine: true,
          mark: ConversationWatchMark.pending,
        ),
      for (final message in state.messages)
        if (!outgoing.contains(message.idKey))
          ConversationWatchMessage(
            key: message.idKey,
            text: message.deletedAt != null || deletes.contains(message.idKey)
                ? l10n.messaging_MessageView_deleted
                : edits[message.idKey] ?? message.content,
            mine: message.senderId == userId,
            time: message.createdAt,
            senderId: group ? message.senderId : null,
            mark: message.senderId != userId
                ? null
                : readByOthers != null && !message.createdAt.isAfter(readByOthers)
                ? ConversationWatchMark.read
                : ConversationWatchMark.sent,
          ),
    ];
  }
}
