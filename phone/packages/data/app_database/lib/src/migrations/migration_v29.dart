import 'package:drift/drift.dart';

import '../app_database.dart';
import '../migration.dart';

import 'generated/schema_v29.dart' as v29;

class MigrationV29 extends Migration {
  const MigrationV29();

  @override
  Future<void> execute(AppDatabase db, Migrator m) async {
    // The CDR store's key widens from the call id to the call id, the connect time and the
    // direction: the backend reports several records under one Call-ID (a transfer back, a
    // retried transfer, the legs of an IVR call) and only the last one written used to survive.
    // The rows kept so far are unique by call id, so each stays a row of its own; the records the
    // old key swallowed come back with the next walk of the history.
    //
    // No stable alternative exists in drift for a primary key change.
    // ignore: experimental_member_use
    await m.alterTable(TableMigration(v29.Cdrs(db)));
  }
}
