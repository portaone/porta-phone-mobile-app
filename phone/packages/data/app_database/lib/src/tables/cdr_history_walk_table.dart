import 'package:drift/drift.dart';

/// Single-row table holding how far BACK the CDR archive has been fetched.
///
/// Kept apart from the sync cursor although both are watermarks of the same
/// store, because that one's presence carries a meaning of its own - a row
/// there means the first sync cycle completed - and a walk that starts before
/// any cycle finishes must not be able to claim it did.
///
/// It records what was ASKED FOR, not what came back: a stretch of days that
/// held no calls moves it just as far as a full one, which is the whole point
/// of keeping it.
@DataClassName('CdrHistoryWalkData')
class CdrHistoryWalkTable extends Table {
  @override
  String get tableName => 'cdr_history_walk';

  @override
  Set<Column> get primaryKey => {id};

  /// Always 0: the table stores a single global watermark.
  IntColumn get id => integer()();

  IntColumn get walkedToUsec => integer()();
}
