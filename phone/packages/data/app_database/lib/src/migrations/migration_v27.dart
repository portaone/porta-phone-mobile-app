import 'package:drift/drift.dart';

import '../app_database.dart';
import '../migration.dart';

import 'generated/schema_v27.dart' as v27;

class MigrationV27 extends Migration {
  const MigrationV27();

  @override
  Future<void> execute(AppDatabase db, Migrator m) async {
    // No backfill: an existing store has fetched whatever it fetched, and the
    // walk has no way to know how far back that reached. An absent watermark
    // means "nobody has walked yet", which starts the next walk at the oldest
    // record there is - exactly where it would have started anyway.
    await m.createTable(v27.CdrHistoryWalk(db));
  }
}
