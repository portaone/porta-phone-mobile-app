import 'package:equatable/equatable.dart';

import '../notification_mute.dart';

import 'sms_conversation.dart';

/// An SMS conversation as `sms:conversation:get` returns it, with the part of
/// the reply that is the asking user's own - see [ChatConversationSnapshot].
///
/// A shared phone number can put several users on one conversation, so this
/// separation is not a nicety here: the conversation is common to them, the
/// mute is not.
class SmsConversationSnapshot extends Equatable {
  const SmsConversationSnapshot({required this.conversation, required this.mute});

  final SmsConversation conversation;

  /// The asking user's mute, or null when the core did not say; see
  /// [ChatConversationSnapshot.mute].
  final NotificationMute? mute;

  @override
  List<Object?> get props => [conversation, mute];

  @override
  String toString() {
    return 'SmsConversationSnapshot(conversation: $conversation, mute: $mute)';
  }
}
