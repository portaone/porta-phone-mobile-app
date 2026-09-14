import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:webtrit_phone/extensions/datetime.dart';
import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'message_body.dart';
import 'message_bubble.dart';

enum NameViewMode { none, show }

enum AvatarViewMode { none, space, show }

class SmsMessageView extends StatefulWidget {
  const SmsMessageView({
    super.key,
    required this.userNumber,
    this.message,
    this.outboxMessage,
    this.outboxDeleteEntry,
    this.userReadedUntil,
    this.membersReadedUntil,
    this.avatarViewMode = AvatarViewMode.none,
    this.nameViewMode = NameViewMode.none,
    required this.handleDelete,
    this.onRendered,
  });

  final String? userNumber;
  final SmsMessage? message;
  final SmsOutboxMessageEntry? outboxMessage;
  final SmsOutboxMessageDeleteEntry? outboxDeleteEntry;

  /// Timestamp of the last message read by the user
  /// Used to display the read status of the message that user didnt see
  final DateTime? userReadedUntil;

  /// Timestamp of the last message read by the members
  /// Used to display the read status of the message sent by the user
  final DateTime? membersReadedUntil;

  /// Controls the visibility of the sender's avatar in the message view
  final AvatarViewMode avatarViewMode;

  /// Controls the visibility of the sender's name in the message view
  final NameViewMode nameViewMode;

  /// Callback function on popup menu delete item selected
  final Function(SmsMessage refMessage) handleDelete;

  /// Callback function that is called when the message is mounted by flutter framework
  /// using [PostFrameCallback] to ensure that the message is rendered before calling the function
  final Function()? onRendered;

  @override
  State<SmsMessageView> createState() => _SmsMessageViewState();
}

class _SmsMessageViewState extends State<SmsMessageView> {
  @override
  void initState() {
    super.initState();
    // Call the onRendered callback after the message is mounted by flutter framework
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onRendered?.call());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final message = widget.message;
    final outboxMessage = widget.outboxMessage;
    final outboxDeleteEntry = widget.outboxDeleteEntry;
    final userReadedUntil = widget.userReadedUntil;
    final membersReadedUntil = widget.membersReadedUntil;

    final content = outboxMessage?.content ?? message?.content ?? '';
    final hasContent = (content.isNotEmpty == true) && content != '-';

    final senderNumber = message?.fromPhoneNumber ?? widget.userNumber;
    final isMine = senderNumber == widget.userNumber;
    final isSended = message != null;
    final isDeleted = outboxDeleteEntry != null || message?.deletedAt != null;

    var isViewedByMembers = false;
    var isViewedByUser = false;

    if (isSended && membersReadedUntil != null) isViewedByMembers = !message.createdAt.isAfter(membersReadedUntil);
    if (isSended && userReadedUntil != null) isViewedByUser = !message.createdAt.isAfter(userReadedUntil);

    final playFadeForNewMessage = isSended && !isViewedByUser && !isViewedByMembers;

    final popupItems = [
      if (hasContent)
        PopupMenuItem(
          onTap: () => Clipboard.setData(ClipboardData(text: message!.content)),
          child: ListTile(
            title: Text(context.l10n.messaging_MessageView_textcopy),
            leading: const Icon(Icons.copy_rounded),
            dense: true,
          ),
        ),
      if (isMine && isSended && !isDeleted)
        PopupMenuItem(
          onTap: () => widget.handleDelete(message),
          child: ListTile(
            title: Text(context.l10n.messaging_MessageView_delete),
            leading: const Icon(Icons.remove),
            dense: true,
          ),
        ),
    ];

    return MessageBubble(
      isMine: isMine,
      decoration: theme.messageDecoration(isMine, isViewedByUser),
      padding: const EdgeInsets.all(12),
      actions: popupItems,
      fadeIn: playFadeForNewMessage,
      leading: isMine
          ? null
          : switch (widget.avatarViewMode) {
              AvatarViewMode.show => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: LeadingAvatar(username: senderNumber?.substring(senderNumber.length - 2) ?? '', radius: 20),
              ),
              AvatarViewMode.space => const SizedBox(width: 48),
              AvatarViewMode.none => null,
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.nameViewMode == NameViewMode.show) ...[
            Text(senderNumber ?? '', style: theme.userNameStyle),
            const SizedBox(height: 4),
          ],
          if (!isDeleted) ...[MessageBody(text: content, isMine: isMine, style: theme.contentStyle)],
          if (isDeleted) ...[Text(context.l10n.messaging_MessageView_deleted, style: theme.subContentStyle)],
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isMine && isSended) ...[
                Text(message.sendingStatus.nameL10n(context), style: theme.subContentStyle),
                const SizedBox(width: 2),
              ],
              if (isMine && !isSended) CircularProgressTemplate(color: colorScheme.onSurface, size: 12, width: 1),
              if (isMine && isSended && !isViewedByMembers) Icon(Icons.done, color: colorScheme.tertiary, size: 12),
              if (isMine && isViewedByMembers) Icon(Icons.done_all, color: colorScheme.tertiary, size: 12),
              const SizedBox(width: 2),
              if (message?.createdAt != null) Text(message!.createdAt.toHHmm, style: theme.subContentStyle),
            ],
          ),
        ],
      ),
    );
  }
}
