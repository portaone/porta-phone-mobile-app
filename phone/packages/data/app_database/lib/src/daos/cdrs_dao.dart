import 'package:drift/drift.dart';
import 'package:app_database/src/app_database.dart';

part 'cdrs_dao.g.dart';

@DriftAccessor(tables: [CdrTable, CdrSyncCursorTable])
class CdrsDao extends DatabaseAccessor<AppDatabase> with _$CdrsDaoMixin {
  CdrsDao(super.db);

  /// Directions that name no direction. A record carrying one of these says the
  /// call could not be attributed (`unknown`, straight from the API) or that
  /// this build is older than the contract (`unrecognized`).
  ///
  /// The column is a textEnum, so what is stored - and what a comparison has to
  /// match - is the value's name.
  static final _unattributedDirectionNames = [
    CallDirectionData.unknown,
    CallDirectionData.unrecognized,
  ].map((direction) => direction.name).toList();

  /// Upserts by `callId`, refusing to replace an attributed direction with an
  /// unattributed one.
  ///
  /// The backend can report one call TWICE under the same `callId` - an IVR
  /// call comes back as an outgoing leg and as the leg the IVR created onward,
  /// which carries no direction at all. Only one of them can survive a primary
  /// key, and without this clause the survivor is whichever the batch wrote
  /// last: the sync worker reverses the page for unrelated reasons (events must
  /// run oldest to newest), so today the attributed copy happens to win. That is
  /// an accident of ordering, and it also does not hold when the two legs arrive
  /// in different pages. The rule makes it a rule.
  Future<void> upsertCdrs(List<CdrRecordData> cdrs) {
    return batch(
      (batch) => batch.insertAll(
        cdrTable,
        cdrs,
        onConflict: DoUpdate<CdrTable, CdrRecordData>.withExcluded(
          (old, excluded) => CdrRecordDataCompanion.custom(
            direction: excluded.direction,
            status: excluded.status,
            callee: excluded.callee,
            calleeNumber: excluded.calleeNumber,
            caller: excluded.caller,
            callerNumber: excluded.callerNumber,
            connectTimeUsec: excluded.connectTimeUsec,
            disconnectTimeUsec: excluded.disconnectTimeUsec,
            disconnectReason: excluded.disconnectReason,
            durationSeconds: excluded.durationSeconds,
            recordingId: excluded.recordingId,
          ),
          // Keep the stored row when the incoming one knows less: an
          // unattributed direction may only overwrite another unattributed one.
          where: (old, excluded) =>
              excluded.direction.isNotIn(_unattributedDirectionNames) | old.direction.isIn(_unattributedDirectionNames),
        ),
      ),
    );
  }

  Future<List<CdrRecordData>> getHistory({
    String? number,
    String? destination,
    DateTime? from,
    DateTime? to,
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
    if (from != null) query.where((tbl) => tbl.connectTimeUsec.isSmallerThanValue(from.microsecondsSinceEpoch));
    if (to != null) query.where((tbl) => tbl.connectTimeUsec.isBiggerThanValue(to.microsecondsSinceEpoch));
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
  Future<DateTime?> getSyncCursor() async {
    final result = await select(cdrSyncCursorTable).getSingleOrNull();
    return result != null ? DateTime.fromMicrosecondsSinceEpoch(result.timestampUsec) : null;
  }

  Future<void> setSyncCursor(DateTime time) {
    return into(
      cdrSyncCursorTable,
    ).insertOnConflictUpdate(CdrSyncCursorData(id: 0, timestampUsec: time.microsecondsSinceEpoch));
  }

  Future<void> wipeData() async {
    await transaction(() async {
      await delete(cdrTable).go();
      await delete(cdrSyncCursorTable).go();
    });
  }
}
