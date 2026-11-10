import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/features/messaging/features/conversations/view/conversations_screen_styles.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/utils/utils.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class ChatConversationScreen extends StatefulWidget {
  const ChatConversationScreen({super.key});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  late final messagingBloc = context.read<MessagingBloc>();
  late final conversationCubit = context.read<ConversationCubit>();
  late final userId = messagingBloc.state.userId;

  /// Whether there is anything behind the menu yet.
  ///
  /// A group chat only knows it is one after it has loaded, and until then the
  /// menu had nothing to open - it was a button that did nothing when pressed.
  bool canOpenInfo(ConversationState state) =>
      state.credentials.participantId != null || (state is CVSReady && state.chat?.type == ChatType.group);

  void onMenuTap() {
    final state = conversationCubit.state;
    final isDialog = state.credentials.participantId != null;
    final isGroup = state is CVSReady && state.chat?.type == ChatType.group;
    // The sheet sits on its own route, so what it needs from this screen's
    // scope goes with it: the conversation, the user's settings on it, and
    // whether the core can answer a mute at all.
    final isMuteEnabled = context.read<FeatureAccess>().conversationMuteAvailable;
    final userSettingsCubit = context.read<ConversationUserSettingsCubit?>();

    Widget provide(Widget info) {
      final withConversation = BlocProvider.value(value: conversationCubit, child: info);
      if (userSettingsCubit == null) return withConversation;
      return BlocProvider.value(value: userSettingsCubit, child: withConversation);
    }

    if (isDialog) {
      context.showModalBottomSheet(
        useSafeArea: true,
        isScrollControlled: true,
        builder: (context) => provide(
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: DialogChatInfo(
              userId,
              state.credentials.participantId!,
              isAudioCallEnabled: true,
              isVideoCallEnabled: messagingBloc.state.messagingConfig.contactInfoVideoCallSupport,
              isMuteEnabled: isMuteEnabled,
            ),
          ),
        ),
      );
    }

    if (isGroup) {
      context.showModalBottomSheet(
        useSafeArea: true,
        isScrollControlled: true,
        builder: (context) => provide(
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: GroupChatInfo(userId, isMuteEnabled: isMuteEnabled),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatTypingCubit(messagingBloc.state.client),
      child: BlocConsumer<ConversationCubit, ConversationState>(
        listener: (context, state) {
          if (state is CVSReady && state.chat != null) {
            context.read<ChatTypingCubit>().init(state.chat!.id);
          }
          if (state is CVSLeft) {
            context.router.navigate(const MainScreenPageRoute(children: [ConversationsScreenPageRoute()]));
          }
        },
        builder: (context, state) =>
            AdaptiveLayout(handset: (context) => _handset(context, state), watch: (context) => _watch(context, state)),
      ),
    );
  }

  /// The thread with Reply on the edge; no menu: the conversation's details
  /// stay on the phone.
  Widget _watch(BuildContext context, ConversationState state) {
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

  Widget _handset(BuildContext context, ConversationState state) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // A thread is part of the conversations section, so its bar is
        // frosted the way the conversations list is.
        flexibleSpace: BlurredSurface.fromStyle(
          Theme.of(context).extension<ConversationsScreenStyles>()?.primary?.appBarBlurredSurface,
        ),
        // Themes that configure no bar color keep a translucent bar instead
        // of the opaque framework default.
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Colors.transparent,
        centerTitle: true,
        title: FadeIn(
          child: Builder(
            builder: (context) {
              if (state is CVSReady) {
                final chatName = state.chat?.name;
                if (chatName != null) return textTitle(chatName);

                final (:chatId, :participantId) = state.credentials;
                if (participantId != null) return dialogTitle(participantId);

                // A group with no name of its own: the same title it
                // carries in the list and in Group info, never the bare
                // number.
                final id = state.chat?.id ?? chatId;
                return textTitle(id == null ? '' : context.l10n.messaging_GroupInfo_titlePrefix(id));
              }

              return const SizedBox();
            },
          ),
        ),
        actions: [
          SemanticAction(
            label: context.l10n.messaging_SemanticsLabel_conversationDetails,
            identifier: conversationMenuId,
            child: IconButton(onPressed: canOpenInfo(state) ? onMenuTap : null, icon: const Icon(Icons.menu)),
          ),
        ],
      ),
      // Anchor of the screen: a flow can tell it is inside a chat before
      // it touches anything, whichever conversation is open.
      body: SemanticId(
        identifier: chatConversationScreenId,
        child: Builder(
          builder: (context) {
            if (state is CVSReady) {
              return ChatMessageListView(
                userId: userId,
                isGroup: state.chat?.type == ChatType.group,
                messages: state.messages,
                outboxMessages: state.outboxMessages,
                outboxMessageEdits: state.outboxMessageEdits,
                outboxMessageDeletes: state.outboxMessageDeletes,
                readCursors: state.readCursors,
                fetchingHistory: state.fetchingHistory,
                historyEndReached: state.historyEndReached,
                onSendMessage: (content) => conversationCubit.sendMessage(content),
                onSendReply: (content, refMessage) => conversationCubit.sendReply(content, refMessage),
                onSendForward: (content, refMessage) => conversationCubit.sendForward(refMessage),
                onSendEdit: (content, refMessage) => conversationCubit.sendEdit(content, refMessage),
                onDelete: (refMessage) => conversationCubit.deleteMessage(refMessage),
                userReadedUntilUpdate: (until) => conversationCubit.userReadedUntilUpdate(until),
                onFetchHistory: conversationCubit.fetchHistory,
              );
            }

            if (state is CVSError) {
              return NoDataPlaceholder(
                content: Text(context.l10n.messaging_Conversation_failure),
                actions: [
                  TextButton(onPressed: conversationCubit.restart, child: Text(context.l10n.messaging_ActionBtn_retry)),
                ],
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget dialogTitle(String participant) {
    return ContactInfoBuilder(
      source: ContactSourceId(ContactSourceType.external, participant),
      builder: (context, contact) {
        final colorScheme = Theme.of(context).colorScheme;
        final hybridPresenceSupport = PresenceViewParams.of(context).hybridPresenceSupport;
        const nameTextStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.bold);
        const noteTextStyle = TextStyle(fontSize: 10);

        return switch ((hybridPresenceSupport, contact)) {
          (_, null) => Text(
            context.l10n.messaging_ParticipantName_unknown,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: nameTextStyle,
          ),
          (false, Contact contact) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (contact.thumbnail != null || contact.thumbnailUrl != null) ...[
                LeadingAvatar(
                  username: contact.displayTitle,
                  thumbnail: contact.thumbnail,
                  thumbnailUrl: contact.thumbnailUrl,
                  style: LeadingAvatarStyle(
                    backgroundColor: colorScheme.primaryFixedDim,
                    initialsTextStyle: TextStyle(color: colorScheme.onPrimary),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  children: [
                    Text(contact.displayTitle, maxLines: 1, overflow: TextOverflow.fade, style: nameTextStyle),
                    if (contact.registered == true)
                      Text(
                        context.l10n.messaging_ConversationScreen_titleAvailable,
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          (true, Contact contact) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LeadingAvatar(
                username: contact.displayTitle,
                thumbnail: contact.thumbnail,
                thumbnailUrl: contact.thumbnailUrl,
                badge: AvatarStatusBadge.maybe(presenceInfo: contact.presenceInfo, dialogInfo: contact.dialogInfo),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  children: [
                    Text(
                      '${contact.displayTitle} ${contact.presenceInfo.primaryStatusIcon ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      style: nameTextStyle,
                    ),
                    if (contact.presenceInfo.primaryNote?.isNotEmpty ?? false)
                      Text(
                        '${contact.presenceInfo.primaryNote}',
                        style: noteTextStyle,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                      ),
                  ],
                ),
              ),
            ],
          ),
        };
      },
    );
  }

  Widget textTitle(String name) {
    return Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
