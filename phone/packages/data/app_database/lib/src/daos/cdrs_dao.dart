import 'package:drift/drift.dart';
import 'package:app_database/src/app_database.dart';

part 'cdrs_dao.g.dart';

@DriftAccessor(tables: [CdrTable, CdrSyncCursorTable])
class CdrsDao extends DatabaseAccessor<AppDatabase> with _$CdrsDaoMixin {
  CdrsDao(super.db);

  /// Upserts by `callId`, last write winning.
  ///
  /// The backend can report ONE call twice under the same `callId`: an IVR call
  /// comes back as an outgoing leg and as the leg the IVR created onward, which
  /// carries no direction at all and reaches us as `unknown`. Only one of them
  /// can survive the primary key, and nothing here chooses between them - the
  /// row written last wins.
  ///
  /// What that means in practice, so the next reader does not have to work it
  /// out from a bug report:
  ///
  /// * within one page the attributed copy wins, but only as a side effect.
  ///   The API returns a page newest-first and the sync worker upserts it
  ///   reversed, because repository events have to run oldest to newest; that
  ///   reversal puts the attributed leg last. Change either and the surviving
  ///   direction changes with it.
  /// * across pages nothing protects it at all. History pages 50 records at a
  ///   time, so the two legs can land in different calls to this method, and if
  ///   the unattributed one lands second the call is stored - and shown - with
  ///   no direction.
  ///
  /// `cdrs_dao_test.dart` pins both cases as they behave today.
  Future<void> upsertCdrs(List<CdrRecordData> cdrs) {
    return batch((batch) => batch.insertAllOnConflictUpdate(cdrTable, cdrs));
  }

  /// Rows newest first. [olderThan] and [newerThan] say which side of a moment
  /// to keep, which is what a descending list paginates by; neither is a range
  /// bound, and neither matches the remote `timeFrom`/`timeTo` pair.
  Future<List<CdrRecordData>> getHistory({
    String? number,
    String? destination,
    DateTime? olderThan,
    DateTime? newerThan,
    int? limit,
    CdrStatusData? status,
    CallDirectionData? direction,
  }) {
    final query = select(cdrTable);
    query.orderBy([(t) => OrderingTerm.desc(t.connectTimeUsec)]);

    if (number != null) query.where((tbl) => tbl.callerNumber.equals(number) | tbl.calleeNumber.equals(number));
    if (destination != null) query.where((tbl) => tbl.caller.equals(destination) | tbl.callee.equals(destination));
    if (status != null) query.where((tbl) => tbl.status.equals(status.name));
    if (direction != null) query.where((tbl) => tbl.direction.equals(direction.name));
    if (olderThan != null) {
      query.where((tbl) => tbl.connectTimeUsec.isSmallerThanValue(olderThan.microsecondsSinceEpoch));
    }
    if (newerThan != null) {
      query.where((tbl) => tbl.connectTimeUsec.isBiggerThanValue(newerThan.microsecondsSinceEpoch));
    }
    if (limit != null) query.limit(limit);

    return query.get();
  }

  Future<DateTime?> getLastUpdate() async {
    final query = select(cdrTable)
      ..orderBy([(t) => OrderingTerm.desc(t.connectTimeUsec)])
      ..limit(1);
    final result = await query.getSingleOrNull();
    return result?.connectTimeUsec != null ? DateTime.fromMicrosecondsSinceEpoch(result!.connectTimeUsec) : null;
  }

  Future<DateTime?> getFirstRecordTime() async {
    final query = select(cdrTable)
      ..orderBy([(t) => OrderingTerm.asc(t.connectTimeUsec)])
      ..limit(1);
    final result = await query.getSingleOrNull();
    return result?.connectTimeUsec != null ? DateTime.fromMicrosecondsSinceEpoch(result!.connectTimeUsec) : null;
  }

  /// Time of the last successfully completed remote sync cycle, or null if the
  /// initial sync has never finished (distinguishes it from a synced-but-empty
  /// history, which keeps a cursor while having no records).
  Future<DateTime?> getSyncCursor() => _cursor(CdrCursorKindEnum.sync);

  Future<void> setSyncCursor(DateTime time) => _writeCursor(CdrCursorKindEnum.sync, time);

  /// How far back the archive has been fetched, or null when nobody has walked
  /// it yet.
  Future<DateTime?> getHistoryWalkedTo() => _cursor(CdrCursorKindEnum.historyWalk);

  /// Moves the watermark to [time] if that reaches further back than where it
  /// already stands.
  ///
  /// Only backwards: a walk resumed from a newer cursor - a second list, a
  /// screen opened again - must not shorten what another one already covered.
  Future<void> markHistoryWalkedTo(DateTime time) {
    final usec = time.microsecondsSinceEpoch;
    return transaction(() async {
      final current = await _cursorRow(CdrCursorKindEnum.historyWalk);
      if (current != null && current.timestampUsec <= usec) return;
      await _writeCursor(CdrCursorKindEnum.historyWalk, time);
    });
  }

  Future<CdrSyncCursorData?> _cursorRow(CdrCursorKindEnum kind) {
    return (select(cdrSyncCursorTable)..where((t) => t.kind.equals(kind.name))).getSingleOrNull();
  }

  Future<DateTime?> _cursor(CdrCursorKindEnum kind) async {
    final row = await _cursorRow(kind);
    return row != null ? DateTime.fromMicrosecondsSinceEpoch(row.timestampUsec) : null;
  }

  Future<void> _writeCursor(CdrCursorKindEnum kind, DateTime time) {
    return into(
      cdrSyncCursorTable,
    ).insertOnConflictUpdate(CdrSyncCursorData(kind: kind, timestampUsec: time.microsecondsSinceEpoch));
  }

  Future<void> wipeData() async {
    await transaction(() async {
      await delete(cdrTable).go();
      // One delete takes both watermarks: they are rows of one table.
      await delete(cdrSyncCursorTable).go();
    });
  }
}
