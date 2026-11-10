import 'package:material_ui/material_ui.dart';

import 'package:collection/collection.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// Where one of the user's own messages stands: an SMS is delivered, a chat
/// message is read.
enum ConversationWatchMark { pending, sent, delivered, read }

/// One message as a conversation on a watch shows it, whichever kind of
/// conversation it comes from.
class ConversationWatchMessage {
  const ConversationWatchMessage({
    required this.key,
    required this.text,
    required this.mine,
    this.time,
    this.senderId,
    this.mark,
    this.note,
  });

  /// Stable across rebuilds: the message's id key.
  final String key;
  final String text;
  final bool mine;

  /// Null for one still on its way out.
  final DateTime? time;

  /// Who wrote it, where a group names its senders.
  final String? senderId;

  final ConversationWatchMark? mark;

  /// What went wrong with it ("Not sent").
  final String? note;
}

/// A conversation on a watch: the name at the top, the messages scrolling
/// over it - newest at the bottom, the user's own on the right - and Reply as
/// the edge button, which opens the watch keyboard over the whole face; its
/// send key posts the message. Older messages load as the top comes near.
///
/// On its way a loading page, failed a state page with Try again on the
/// edge, with no messages a state page with Reply on the edge. Editing,
/// deleting, replying to one message, forwarding and the conversation's
/// details stay on the phone.
class ConversationWatchThread extends StatefulWidget {
  const ConversationWatchThread({
    super.key,
    required this.title,
    required this.messages,
    required this.onSend,
    this.failed = false,
    this.onRetry,
    this.onTyping,
    this.onFetchHistory,
    this.onRead,
    this.readUntil,
    this.senderName,
    this.maxLength,
  });

  final String title;

  /// Newest first; null while the conversation is on its way.
  final List<ConversationWatchMessage>? messages;

  final ValueChanged<String> onSend;

  /// The conversation could not be opened.
  final bool failed;
  final VoidCallback? onRetry;

  /// The user is typing: the other side is told.
  final VoidCallback? onTyping;

  /// Asks for older messages; null when there are none left or a fetch is
  /// under way.
  final VoidCallback? onFetchHistory;

  /// The other side's messages up to this time have been seen.
  final ValueChanged<DateTime>? onRead;

  /// Where the user's read cursor stands: the thread moves it on, never back
  /// - a thread read up on the phone first is not marked again.
  final DateTime? readUntil;

  /// Wraps a bubble of a group with its sender's name.
  final Widget Function(BuildContext context, String senderId, Widget Function(String name) bubble)? senderName;

  final int? maxLength;

  @override
  State<ConversationWatchThread> createState() => _ConversationWatchThreadState();
}

class _ConversationWatchThreadState extends State<ConversationWatchThread> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  DateTime? _readUntil;

  /// How near the top older messages are asked for.
  static const _historyThreshold = 300.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeFetch);
    _markRead();
    _fetchUntilFilled();
  }

  @override
  void didUpdateWidget(ConversationWatchThread oldWidget) {
    super.didUpdateWidget(oldWidget);
    _markRead();
    _fetchUntilFilled();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _maybeFetch() {
    final position = _scroll.position;
    if (position.maxScrollExtent - position.pixels < _historyThreshold) widget.onFetchHistory?.call();
  }

  /// A first page too short to scroll never moves the list, so the older
  /// messages are asked for once it is laid out.
  void _fetchUntilFilled() {
    if (widget.onFetchHistory == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) _maybeFetch();
    });
  }

  void _send(String value) {
    final content = value.trim();
    _controller.clear();
    if (content.isEmpty) return;
    widget.onSend(content);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  /// The newest of the other side's messages is on the face as soon as the
  /// thread is: the bottom of the list.
  void _markRead() {
    final onRead = widget.onRead;
    final messages = widget.messages;
    if (onRead == null || messages == null || widget.failed) return;
    final newest = messages.where((message) => !message.mine && message.time != null).firstOrNull?.time;
    final seen = [?_readUntil, ?widget.readUntil].maxOrNull;
    if (newest == null || (seen != null && !newest.isAfter(seen))) return;
    _readUntil = newest;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) onRead(newest);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final messages = widget.messages;

    if (widget.failed) {
      return WatchStatePage(
        title: widget.title,
        icon: const Icon(Icons.error_outline),
        message: l10n.messaging_Conversation_failure,
        action: WatchAction(label: l10n.messaging_ActionBtn_retry, onPressed: widget.onRetry),
      );
    }

    if (messages == null) {
      return WatchStatePage.loading(title: widget.title, progressLabel: l10n.common_SemanticsLabel_loading);
    }

    // The time today, the date before: a bubble of three days ago does not read as today's.
    final timeFormat = context.read<AppTime>().timeOrDateFormat(Localizations.localeOf(context));

    return WatchKeyboardInput(
      controller: _controller,
      onChanged: widget.onTyping == null ? null : (_) => widget.onTyping!(),
      onSubmitted: _send,
      textInputAction: TextInputAction.send,
      maxLength: widget.maxLength,
      fieldKey: conversationWatchReplyInputKey,
      builder: (context, open) {
        final reply = WatchAction(
          label: l10n.messaging_MessageView_reply,
          identifier: conversationWatchReplyId,
          onPressed: open,
        );
        if (messages.isEmpty) {
          return WatchStatePage(
            title: widget.title,
            icon: const Icon(Icons.chat_bubble_outline),
            message: l10n.messaging_Conversations_tile_empty,
            action: reply,
          );
        }
        return WatchScrollList.builder(
          title: widget.title,
          reverse: true,
          controller: _scroll,
          spacing: context.adaptiveMetrics.gap,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final senderId = message.senderId;
            final senderName = widget.senderName;
            final time = switch (message.time) {
              final time? => timeFormat.format(time.toLocal()),
              null => null,
            };
            final mark = switch (message.mark) {
              ConversationWatchMark.pending => l10n.messaging_Watch_markPending,
              ConversationWatchMark.sent => l10n.messaging_Watch_markSent,
              ConversationWatchMark.delivered => l10n.messaging_Watch_markDelivered,
              ConversationWatchMark.read => l10n.messaging_Watch_markRead,
              null => null,
            };
            Widget bubble([String? name]) => WatchBubble(
              text: message.text,
              mine: message.mine,
              sender: name,
              time: time,
              // Whose it is and where it stands, which the eye reads from the
              // side and the mark.
              semanticsLabel: [
                if (message.mine) l10n.messaging_Watch_mine,
                ?name,
                message.text,
                ?time,
                ?mark,
                ?message.note,
              ].join(', '),
              mark: switch (message.mark) {
                ConversationWatchMark.pending => const Icon(Icons.schedule),
                ConversationWatchMark.sent => const Icon(Icons.done),
                ConversationWatchMark.delivered || ConversationWatchMark.read => const Icon(Icons.done_all),
                null => null,
              },
              note: message.note,
            );
            // The rows are matched by index, and a new message takes index 0:
            // keyed by the message, a row's state - the sender's name being
            // looked up - is never handed on to the message now at its index.
            return KeyedSubtree(
              key: ValueKey(message.key),
              child: senderId == null || senderName == null || message.mine
                  ? bubble()
                  : senderName(context, senderId, bubble),
            );
          },
          edge: (context, overlay) => reply.buildButton(overlay),
        );
      },
    );
  }
}
