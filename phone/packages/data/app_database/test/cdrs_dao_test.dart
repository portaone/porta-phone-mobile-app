import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'package:app_database/app_database.dart';

// The backend reports one IVR call twice under the same callId: an outgoing leg
// and the leg the IVR created onward, which carries no direction. Only one row
// survives the primary key, and nothing chooses between them - the last write
// wins.
//
// These tests do not ask for that to be right. They pin what happens today, so
// the behaviour is stated somewhere other than a bug report, and so a change to
// the upsert or to the order the sync worker writes in shows up here rather
// than in someone's call history.
void main() {
  late AppDatabase database;

  CdrRecordData leg(CallDirectionData direction) => CdrRecordData(
    callId: 'OEk6Vq1n7chCC0G0098Syj4L',
    direction: direction,
    status: CdrStatusData.accepted,
    callee: '*199',
    caller: '111000555',
    connectTimeUsec: 1789550078000000,
    disconnectTimeUsec: 1789550087000000,
    disconnectReason: 'Normal call clearing',
    durationSeconds: 9,
  );

  Future<CallDirectionData> storedDirection() async {
    final stored = await database.cdrsDao.getHistory();
    expect(stored.length, 1, reason: 'one row per callId');
    return stored.single.direction;
  }

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  group('one call reported twice, in a single page', () {
    // The API returns a page newest-first and the sync worker upserts it
    // reversed, so this is the order production writes in: the attributed leg
    // lands last and wins.
    test('the attributed leg written last is the one kept', () async {
      await database.cdrsDao.upsertCdrs([leg(CallDirectionData.unknown), leg(CallDirectionData.outgoing)]);

      expect(await storedDirection(), CallDirectionData.outgoing);
    });

    // Same page, opposite order - which is what a page that is not reversed,
    // or a backend that orders the two legs the other way round, would produce.
    test('but the order alone decides it', () async {
      await database.cdrsDao.upsertCdrs([leg(CallDirectionData.outgoing), leg(CallDirectionData.unknown)]);

      expect(await storedDirection(), CallDirectionData.unknown);
    });
  });

  group('one call reported twice, across pages', () {
    // History pages 50 records at a time, so the two legs can reach the store in
    // separate calls. Nothing spans them.
    test('the later page overwrites the earlier one, whichever leg it carries', () async {
      await database.cdrsDao.upsertCdrs([leg(CallDirectionData.outgoing)]);
      await database.cdrsDao.upsertCdrs([leg(CallDirectionData.unknown)]);

      expect(
        await storedDirection(),
        CallDirectionData.unknown,
        reason: 'the call ends up stored, and shown, with no direction',
      );
    });

    test('and the other way round it recovers', () async {
      await database.cdrsDao.upsertCdrs([leg(CallDirectionData.unknown)]);
      await database.cdrsDao.upsertCdrs([leg(CallDirectionData.outgoing)]);

      expect(await storedDirection(), CallDirectionData.outgoing);
    });
  });

  test('an ordinary record still updates in place', () async {
    await database.cdrsDao.upsertCdrs([leg(CallDirectionData.outgoing)]);
    await database.cdrsDao.upsertCdrs([
      CdrRecordData(
        callId: 'OEk6Vq1n7chCC0G0098Syj4L',
        direction: CallDirectionData.outgoing,
        status: CdrStatusData.accepted,
        callee: '*199',
        caller: '111000555',
        connectTimeUsec: 1789550078000000,
        disconnectTimeUsec: 1789550087000000,
        disconnectReason: 'Normal call clearing',
        durationSeconds: 9,
        recordingId: '36495',
      ),
    ]);

    final stored = await database.cdrsDao.getHistory();

    expect(stored.single.recordingId, '36495', reason: 'a recording that shows up later must land');
  });
}
