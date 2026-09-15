import 'package:drift/drift.dart';

@DataClassName('VoicemailData')
class VoicemailTable extends Table {
  @override
  String get tableName => 'voicemails';

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();

  TextColumn get date => text()();

  RealColumn get duration => real()();

  TextColumn get sender => text()();

  TextColumn get receiver => text()();

  BoolColumn get seen => boolean().withDefault(const Constant(false))();

  IntColumn get size => integer()();

  TextColumn get type => text()();

  TextColumn get attachmentPath => text().nullable()();

  /// Whether the user is keeping this message.
  ///
  /// Nullable because the backend omits the field when the mailbox behind it
  /// cannot persist the flag, and that is not the same as `false`: it means the
  /// control does not apply to this message at all.
  BoolColumn get saved => boolean().nullable()();

  /// The id of the user who forwarded this message on; null unless it arrived
  /// that way. The sender stays the original caller, so this is the only thing
  /// naming the colleague who passed it along.
  TextColumn get forwardedBy => text().nullable()();
}
