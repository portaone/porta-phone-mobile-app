import 'package:drift/drift.dart';

import '../app_database.dart';
import '../migration.dart';

import 'generated/schema_v27.dart' as v27;

class MigrationV27 extends Migration {
  const MigrationV27();

  @override
  Future<void> execute(AppDatabase db, Migrator m) async {
    // The CDR store gains a second watermark - how far BACK the archive has
    // been asked for - and it is the same shape as the sync cursor already
    // here: one instant. So the table stops being a single global row and
    // becomes one row per kind, rather than a second table appearing beside it.
    //
    // The row an existing store holds is the sync cursor, and it must survive:
    // its presence is what says the first cycle completed.
    //
    // Nothing backfills the history watermark. An existing store fetched
    // whatever it fetched and the walk has no way to know how far back that
    // reached; an absent watermark means "nobody has walked yet", which starts
    // the next walk at the oldest record there is - exactly where it would have
    // started anyway.
    final cursors = v27.CdrSyncCursors(db);

    // No stable alternative exists in drift (2.29.0).
    // TableMigration is the only high-level API for complex ALTER TABLE operations.
    // ignore: experimental_member_use
    await m.alterTable(
      TableMigration(
        cursors,
        columnTransformer: {cursors.kind: Constant(CdrCursorKindEnum.sync.name)},
        newColumns: [cursors.kind],
      ),
    );
  }
}
