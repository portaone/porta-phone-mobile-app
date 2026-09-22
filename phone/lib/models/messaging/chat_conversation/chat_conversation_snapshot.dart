import 'package:equatable/equatable.dart';

import '../notification_mute.dart';

import 'chat.dart';

/// A chat as `chat:get` returns it: the chat itself, and the part of the reply
/// that belongs to the asking user rather than to the chat.
///
/// The two arrive together and are stored apart - the chat is the same for
/// every member and is written whole on every update, the user's own state is
/// not - so they are named apart here instead of being merged into [Chat].
/// Whatever else turns out to be the user's own joins this class, not that
/// one.
class ChatConversationSnapshot extends Equatable {
  const ChatConversationSnapshot({required this.chat, required this.mute});

  final Chat chat;

  /// The asking user's mute, or null when the core did not say - it does not
  /// carry the functionality at all. Null is not "not muted": it is nothing
  /// to store.
  final NotificationMute? mute;

  @override
  List<Object?> get props => [chat, mute];

  @override
  String toString() {
    return 'ChatConversationSnapshot(chat: $chat, mute: $mute)';
  }
}
