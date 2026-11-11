import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// An SMS conversation on a watch: the thread with Reply on the edge; no
/// menu: muting and deleting the conversation stay on the phone.
class SmsConversationScreenWatch extends StatelessWidget {
  const SmsConversationScreenWatch({
    super.key,
    required this.state,
    required this.userId,
    required this.userNumber,
    required this.title,
  });

  final SmsConversationState state;
  final String userId;

  /// The user's own number of the two, when it is known.
  final String? userNumber;

  final String title;

  @override
  Widget build(BuildContext context) {
    final conversationCubit = context.read<SmsConversationCubit>();
    final state = this.state;
    final ready = state is SCSReady ? state : null;
    return Scaffold(
      body: SemanticId(
        identifier: smsConversationScreenId,
        child: ConversationWatchThread(
          title: title,
          messages: ready == null ? null : _messages(context, ready),
          failed: state is SCSError,
          onRetry: conversationCubit.restart,
          onSend: conversationCubit.sendMessage,
          onTyping: () => context.read<SmsTypingCubit>().sendTyping(),
          onFetchHistory: ready != null && !ready.historyEndReached && !ready.fetchingHistory
              ? conversationCubit.fetchHistory
              : null,
          onRead: conversationCubit.userReadedUntilUpdate,
          readUntil: ready?.readCursors.userReadedUntil(userId),
          maxLength: kAppMessagingMaxLength,
        ),
      ),
    );
  }

  /// Newest first, as the thread draws them: what is still going out, then
  /// what the server has; a message the network refused says so under it.
  List<ConversationWatchMessage> _messages(BuildContext context, SCSReady state) {
    final outgoing = {for (final entry in state.outboxMessages) entry.idKey};
    final deletes = {for (final entry in state.outboxMessageDeletes) entry.idKey};
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
                ? context.l10n.messaging_MessageView_deleted
                : message.content,
            mine: message.fromPhoneNumber == userNumber,
            time: message.createdAt,
            mark: message.fromPhoneNumber != userNumber
                ? null
                : switch (message.sendingStatus) {
                    SmsSendingStatus.waiting => ConversationWatchMark.pending,
                    SmsSendingStatus.sent => ConversationWatchMark.sent,
                    // Not sent: the note says so, and no mark says otherwise.
                    SmsSendingStatus.failed => null,
                    SmsSendingStatus.delivered => ConversationWatchMark.delivered,
                  },
            note: message.sendingStatus == SmsSendingStatus.failed ? message.sendingStatus.nameL10n(context) : null,
          ),
    ];
  }
}
