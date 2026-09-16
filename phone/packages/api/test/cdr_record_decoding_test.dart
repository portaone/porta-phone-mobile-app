import 'package:test/test.dart';

import 'package:api/api.dart';

// The whole page is decoded in one go, so a value this build does not know must
// land on `unrecognized` rather than throw: a throw here would take every record
// of the response with it.
void main() {
  Map<String, Object?> record({required String direction, required String status}) => {
    'call_id': 'OEk6Vq1n7chCC0G0098Syj4L',
    'callee': '*199',
    'caller': '111000555',
    'connect_time': '2026-09-16T09:14:38Z',
    'direction': direction,
    'disconnect_reason': 'Normal call clearing',
    'disconnect_time': '2026-09-16T09:14:47Z',
    'duration': 9,
    'status': status,
  };

  group('direction', () {
    test('carries every value of the contract', () {
      const wire = {
        'incoming': CdrDirection.incoming,
        'outgoing': CdrDirection.outgoing,
        'forwarded': CdrDirection.forwarded,
        'unknown': CdrDirection.unknown,
      };

      for (final entry in wire.entries) {
        final decoded = CdrRecord.fromJson(record(direction: entry.key, status: 'accepted'));

        expect(decoded.direction, entry.value, reason: entry.key);
      }
    });

    test('a value this build does not know decodes instead of throwing', () {
      final decoded = CdrRecord.fromJson(record(direction: 'sideways', status: 'accepted'));

      expect(decoded.direction, CdrDirection.unrecognized);
    });
  });

  group('status', () {
    test('carries every value of the contract, snake case included', () {
      const wire = {
        'accepted': CdrStatus.accepted,
        'declined': CdrStatus.declined,
        'missed': CdrStatus.missed,
        'failed': CdrStatus.failed,
        'completed_elsewhere': CdrStatus.completedElsewhere,
        'error': CdrStatus.error,
      };

      for (final entry in wire.entries) {
        final decoded = CdrRecord.fromJson(record(direction: 'outgoing', status: entry.key));

        expect(decoded.status, entry.value, reason: entry.key);
      }
    });

    test('a value this build does not know decodes instead of throwing', () {
      final decoded = CdrRecord.fromJson(record(direction: 'outgoing', status: 'on_hold'));

      expect(decoded.status, CdrStatus.unrecognized);
    });
  });

  test('a page survives one record it cannot fully read', () {
    final response = CdrHistoryResponse.fromJson({
      'items': [
        record(direction: 'outgoing', status: 'accepted'),
        record(direction: 'unknown', status: 'accepted'),
        record(direction: 'forwarded', status: 'completed_elsewhere'),
      ],
    });

    expect(response.items.map((i) => i.direction), [
      CdrDirection.outgoing,
      CdrDirection.unknown,
      CdrDirection.forwarded,
    ]);
  });
}
