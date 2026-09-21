import 'package:app_database/src/tables/sms_conversations_table.dart';
import 'package:drift/drift.dart';

/// What the current user holds about one SMS conversation, mirroring
/// [ChatUserSettingsTable] and existing for the same reason: a shared phone
/// number can put several users on one conversation, so nothing here belongs
/// on the conversation row, which is written whole whenever the core sends it
/// again.
@DataClassName('SmsConversationUserSettingsData')
class SmsConversationUserSettingsTable extends Table {
  @override
  String get tableName => 'sms_conversation_user_settings';

  @override
  Set<Column> get primaryKey => {conversationId};

  IntColumn get conversationId => integer().references(SmsConversationsTable, #id, onDelete: KeyAction.cascade)();

  /// Whether the user muted this conversation's notifications.
  BoolColumn get muted => boolean().withDefault(const Constant(false))();

  /// When the mute lapses, or null when it was set to last forever.
  IntColumn get mutedUntilUsec => integer().nullable()();
}
