import 'package:drift/drift.dart';

// Both mirror the domain enums in `webtrit_phone/models`, value for value: the
// mappers translate by name, so a value missing here fails at write time.
// The columns are textEnum, so adding a value stores a new name and needs no
// migration.
enum CdrStatusData { accepted, declined, missed, failed, completedElsewhere, error, unrecognized }

enum CallDirectionData { incoming, outgoing, forwarded, unknown, unrecognized }

@DataClassName('CdrRecordData')
class CdrTable extends Table {
  @override
  String get tableName => 'cdrs';

  // One row per record of the history, not per call id: the backend reuses a SIP Call-ID (a
  // transfer back, a retried transfer, the legs of an IVR call), and every leg and attempt is a
  // record of its own. A record has no id of its own; its call id, its connect time and its
  // direction tell it apart (two legs of one moment differ by direction).
  @override
  Set<Column> get primaryKey => {callId, connectTimeUsec, direction};

  TextColumn get callId => text()();

  TextColumn get direction => textEnum<CallDirectionData>()();

  TextColumn get status => textEnum<CdrStatusData>()();

  TextColumn get callee => text()();

  TextColumn get calleeNumber => text().nullable()();

  TextColumn get caller => text()();

  TextColumn get callerNumber => text().nullable()();

  IntColumn get connectTimeUsec => integer()();

  IntColumn get disconnectTimeUsec => integer()();

  TextColumn get disconnectReason => text()();

  IntColumn get durationSeconds => integer()();

  TextColumn get recordingId => text().nullable()();
}
