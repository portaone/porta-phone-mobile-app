import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'package:app_database/app_database.dart';

// The backend reports one IVR call twice under the same callId: an outgoing leg
// and the leg the IVR created onward, which carries no direction. Only one row
// can survive the primary key, and which one must not depend on the order the
// pages happened to arrive in (WT-1983).
void main() {
  late AppDatabase database;

  CdrRecordData leg(CallDirectionData direction, {String callId = 'OEk6Vq1n7chCC0G0098Syj4L'}) => CdrRecordData(
    callId: callId,
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

  group('a call reported twice', () {
    test('keeps the attributed direction when the page puts it last', () async {
      await database.cdrsDao.upsertCdrs([leg(CallDirectionData.unknown), leg(CallDirectionData.outgoing)]);

      expect(await storedDirection(), CallDirectionData.outgoing);
    });

    test('keeps the attributed direction when the page puts it first', () async {
      await database.cdrsDao.upsertCdrs([leg(CallDirectionData.outgoing), leg(CallDirectionData.unknown)]);

      expect(await storedDirection(), CallDirectionData.outgoing);
    });

    test('keeps it when the legs arrive in separate pages, attributed one first', () async {
      await database.cdrsDao.upsertCdrs([leg(CallDirectionData.outgoing)]);
      await database.cdrsDao.upsertCdrs([leg(CallDirectionData.unknown)]);

      expect(await storedDirection(), CallDirectionData.outgoing);
    });

    test('and when the unattributed leg is stored first, the later one repaints it', () async {
      await database.cdrsDao.upsertCdrs([leg(CallDirectionData.unknown)]);
      expect(await storedDirection(), CallDirectionData.unknown, reason: 'shown rather than hidden');

      await database.cdrsDao.upsertCdrs([leg(CallDirectionData.outgoing)]);

      expect(await storedDirection(), CallDirectionData.outgoing);
    });

    test('an unrecognized direction is unattributed too', () async {
      await database.cdrsDao.upsertCdrs([leg(CallDirectionData.forwarded)]);
      await database.cdrsDao.upsertCdrs([leg(CallDirectionData.unrecognized)]);

      expect(await storedDirection(), CallDirectionData.forwarded);
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
