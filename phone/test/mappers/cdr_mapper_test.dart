import 'package:flutter_test/flutter_test.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/mappers/mappers.dart';
import 'package:webtrit_phone/models/models.dart';

class _Mapper with CdrApiMapper, CdrDriftMapper {}

// Two translations and one trap. The api package decides what the wire meant,
// this mapper decides what the app calls it, and the database mirrors the app's
// enums by NAME - so a value added to one enum and not the other only fails when
// a record carrying it is written (WT-1983).
void main() {
  final mapper = _Mapper();

  api.CdrRecord apiRecord({
    api.CdrDirection direction = api.CdrDirection.outgoing,
    api.CdrStatus status = api.CdrStatus.accepted,
  }) => api.CdrRecord(
    callId: 'OEk6Vq1n7chCC0G0098Syj4L',
    callee: '*199',
    caller: '111000555',
    connectTime: DateTime.utc(2026, 9, 16, 9, 14, 38),
    direction: direction,
    disconnectReason: 'Normal call clearing',
    disconnectTime: DateTime.utc(2026, 9, 16, 9, 14, 47),
    duration: 9,
    status: status,
  );

  CdrRecord record({CallDirection direction = CallDirection.outgoing, CdrStatus status = CdrStatus.accepted}) =>
      CdrRecord(
        callId: 'OEk6Vq1n7chCC0G0098Syj4L',
        direction: direction,
        status: status,
        callee: '*199',
        calleeNumber: '*199',
        caller: '111000555',
        callerNumber: '111000555',
        connectTime: DateTime.utc(2026, 9, 16, 9, 14, 38),
        disconnectTime: DateTime.utc(2026, 9, 16, 9, 14, 47),
        disconnectReason: 'Normal call clearing',
        duration: const Duration(seconds: 9),
      );

  group('from the api', () {
    test('every direction of the contract has a domain value', () {
      const expected = {
        api.CdrDirection.incoming: CallDirection.incoming,
        api.CdrDirection.outgoing: CallDirection.outgoing,
        api.CdrDirection.forwarded: CallDirection.forwarded,
        api.CdrDirection.unknown: CallDirection.unknown,
        api.CdrDirection.unrecognized: CallDirection.unrecognized,
      };
      expect(expected.keys, containsAll(api.CdrDirection.values));

      for (final entry in expected.entries) {
        expect(mapper.cdrFromApi(apiRecord(direction: entry.key)).direction, entry.value, reason: '${entry.key}');
      }
    });

    test('every status of the contract has a domain value', () {
      const expected = {
        api.CdrStatus.accepted: CdrStatus.accepted,
        api.CdrStatus.declined: CdrStatus.declined,
        api.CdrStatus.missed: CdrStatus.missed,
        api.CdrStatus.failed: CdrStatus.failed,
        api.CdrStatus.completedElsewhere: CdrStatus.completedElsewhere,
        api.CdrStatus.error: CdrStatus.error,
        api.CdrStatus.unrecognized: CdrStatus.unrecognized,
      };
      expect(expected.keys, containsAll(api.CdrStatus.values));

      for (final entry in expected.entries) {
        expect(mapper.cdrFromApi(apiRecord(status: entry.key)).status, entry.value, reason: '${entry.key}');
      }
    });

    test('a leg the switch could not attribute stays distinct from a value we cannot read', () {
      expect(mapper.cdrFromApi(apiRecord(direction: api.CdrDirection.unknown)).direction, CallDirection.unknown);
      expect(
        mapper.cdrFromApi(apiRecord(direction: api.CdrDirection.unrecognized)).direction,
        CallDirection.unrecognized,
      );
    });
  });

  group('through the database', () {
    test('every direction survives the round trip', () {
      for (final direction in CallDirection.values) {
        final stored = mapper.cdrToDrift(record(direction: direction));

        expect(mapper.cdrFromDrift(stored).direction, direction, reason: '$direction');
      }
    });

    test('every status survives the round trip', () {
      for (final status in CdrStatus.values) {
        final stored = mapper.cdrToDrift(record(status: status));

        expect(mapper.cdrFromDrift(stored).status, status, reason: '$status');
      }
    });
  });
}
