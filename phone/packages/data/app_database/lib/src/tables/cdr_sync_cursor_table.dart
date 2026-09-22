import 'package:drift/drift.dart';

/// Which watermark of the CDR store a row holds.
enum CdrCursorKindEnum {
  /// When the last successful sync cycle completed, even one that fetched zero
  /// records. This row's PRESENCE is what tells "never synced yet" apart from
  /// "synced, and the history is genuinely empty".
  sync,

  /// How far BACK the archive has been asked for. It records what was ASKED
  /// FOR rather than what came back, so a stretch of days holding no calls
  /// moves it exactly as far as a full one.
  historyWalk,
}

/// The watermarks of the CDR store, one row per kind.
///
/// One table rather than one per watermark: they are the same shape - a kind
/// and an instant - so a new one should cost a row, not a table with its own
/// migration and schema dump. What differs between them is not the storage but
/// the rule for moving them, and that lives in the DAO: the sync cursor is set
/// outright, while the history watermark moves only further back.
@DataClassName('CdrSyncCursorData')
class CdrSyncCursorTable extends Table {
  @override
  String get tableName => 'cdr_sync_cursors';

  @override
  Set<Column> get primaryKey => {kind};

  TextColumn get kind => textEnum<CdrCursorKindEnum>()();

  IntColumn get timestampUsec => integer()();
}
