import 'package:drift/drift.dart';

import '../app_database.dart';
import '../migration.dart';

import 'generated/schema_v26.dart' as v26;

class MigrationV26 extends Migration {
  const MigrationV26();

  @override
  Future<void> execute(AppDatabase db, Migrator m) async {
    final voicemailTable = v26.Voicemails(db);

    // Both nullable and both left null for messages already stored: the flags
    // describe what the mailbox reports, and the next refresh is what fills
    // them in. A `saved` backfilled as false would claim the control applies
    // to a message the backend may say nothing about.
    await m.addColumn(voicemailTable, voicemailTable.saved);
    await m.addColumn(voicemailTable, voicemailTable.forwardedBy);
  }
}
