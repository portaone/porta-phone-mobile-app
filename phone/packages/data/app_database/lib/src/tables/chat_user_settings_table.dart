import 'package:app_database/src/tables/chats_table.dart';
import 'package:drift/drift.dart';

/// What the current user, rather than the chat, holds about one chat.
///
/// A table of its own, and named for the category rather than for the mute
/// that is its only occupant today, because the reason it exists is general:
/// the core sends a chat to every member at once (`chat_info_update`), so
/// anything that is one member's own cannot ride on the chat row. The chat row
/// is also written whole on every such update, which would clear a column
/// living there - a group rename would unmute the chat.
///
/// Extend it with a column, not with another table. Every column carries a
/// default so that a later setting can create the row without knowing about
/// the mute, and each writer touches only its own columns - see
/// `ChatsDao.upsertChatNotificationMute`.
@DataClassName('ChatUserSettingsData')
class ChatUserSettingsTable extends Table {
  @override
  String get tableName => 'chat_user_settings';

  @override
  Set<Column> get primaryKey => {chatId};

  IntColumn get chatId => integer().references(ChatsTable, #id, onDelete: KeyAction.cascade)();

  /// Whether the user muted this chat's notifications.
  BoolColumn get muted => boolean().withDefault(const Constant(false))();

  /// When the mute lapses, or null when it was set to last forever.
  ///
  /// Nothing runs at that moment - the core sends no event - so a reader has
  /// to compare it against the current time rather than trust [muted] alone.
  IntColumn get mutedUntilUsec => integer().nullable()();
}
