import 'package:equatable/equatable.dart';

import 'notification_mute.dart';

/// What the current user holds about one conversation - a chat or an SMS
/// thread - as opposed to what the conversation is.
///
/// The distinction is the core's, not a nicety: a conversation is sent to
/// every member at once and written whole on every update, while this is one
/// member's own and never rides on that broadcast. Today it is the
/// notification mute alone. Whatever else turns out to be the user's own
/// rather than the conversation's - a pin, an archive - is a field here, so
/// that every reader of the user's state has one place to read it from.
class ConversationUserSettings extends Equatable {
  const ConversationUserSettings({this.mute = NotificationMute.none});

  /// A conversation the user has set nothing on - also what a core that
  /// does not carry the mute reports, which reads the same way.
  static const none = ConversationUserSettings();

  final NotificationMute mute;

  @override
  List<Object?> get props => [mute];

  @override
  String toString() {
    return 'ConversationUserSettings(mute: $mute)';
  }
}
