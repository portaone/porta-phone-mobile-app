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

  @override
  Set<Column> get primaryKey => {callId};

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
