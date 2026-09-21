import 'package:drift/drift.dart';

import '../app_database.dart';
import '../migration.dart';

class MigrationV28 extends Migration {
  const MigrationV28();

  @override
  Future<void> execute(AppDatabase db, Migrator m) async {
    // Nothing to backfill. A mute is the core's to report, and it rides on
    // every chat:get and sms:conversation:get, so an install that upgrades
    // learns what is muted on its next sync. Writing "not muted" rows here
    // would claim knowledge this client does not have yet.
    await m.createTable(db.chatUserSettingsTable);
    await m.createTable(db.smsConversationUserSettingsTable);
  }
}
