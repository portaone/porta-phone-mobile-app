import 'package:flutter_test/flutter_test.dart';

import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/mappers/signaling/presence_info_mapper.dart';
import 'package:webtrit_phone/mappers/signaling/presence_settings_mapper.dart';
import 'package:webtrit_phone/models/models.dart';

SignalingPresenceInfo _incoming({String? timestamp, int? timeOffsetMin, required DateTime arrivalTime}) {
  return SignalingPresenceInfo(
    id: 'presence_1',
    number: '1001',
    available: true,
    note: '',
    statusIcon: null,
    device: null,
    timeOffsetMin: timeOffsetMin,
    timestamp: timestamp,
    activities: const [],
    arrivalTime: arrivalTime,
    source: SignalingPresenceInfoSource.direct,
  );
}

void main() {
  final heardByCore = DateTime.utc(2026, 7, 31, 14, 0, 1);

  group('a presence record as the app receives it', () {
    test('keeps the time Core heard of it', () {
      // The records of a number are put in order by it, so it has to be Core's
      // one clock and not the moment this phone happened to read the event.
      final info = SignalingPresenceInfoMapper.fromSignaling(
        _incoming(timestamp: '2026-07-31T14:00:00Z', arrivalTime: heardByCore),
      );

      expect(info.arrivalTime, heardByCore);
    });

    test('takes a time that names its zone as it is', () {
      final info = SignalingPresenceInfoMapper.fromSignaling(
        _incoming(timestamp: '2026-07-31T14:00:00Z', timeOffsetMin: -300, arrivalTime: heardByCore),
      );

      expect(info.timestamp, DateTime.utc(2026, 7, 31, 14));
    });

    test('does not apply the offset to a time that names its zone by an offset', () {
      // The offset beside the time is the same zone the time already names;
      // applied once more it would move the time two hours back.
      for (final timestamp in ['2026-07-31T16:00:00+02:00', '2026-07-31T16:00:00+0200']) {
        final info = SignalingPresenceInfoMapper.fromSignaling(
          _incoming(timestamp: timestamp, timeOffsetMin: 120, arrivalTime: heardByCore),
        );

        expect(info.timestamp, DateTime.utc(2026, 7, 31, 14), reason: timestamp);
      }
    });

    test('reads a time without a zone or an offset in the zone of this phone, as before', () {
      final info = SignalingPresenceInfoMapper.fromSignaling(
        _incoming(timestamp: '2026-07-31T09:00:00', arrivalTime: heardByCore),
      );

      expect(info.timestamp, DateTime(2026, 7, 31, 9));
      expect(info.timestamp!.isUtc, isFalse);
    });

    test('reads a wall clock that does not exist in the zone of this phone', () {
      // 03:30 on 2026-03-29 was skipped wherever clocks went from 03:00 to
      // 04:00 that night. Read in such a zone first - TZ=Europe/Kyiv - it came
      // out as 04:30 local, and the publisher's offset of three hours then
      // gave 01:30 UTC, an hour late. Its fields are what the publisher meant
      // in any zone the reader is in.
      final info = SignalingPresenceInfoMapper.fromSignaling(
        _incoming(timestamp: '2026-03-29T03:30:00.000', timeOffsetMin: 180, arrivalTime: heardByCore),
      );

      expect(info.timestamp, DateTime.utc(2026, 3, 29, 0, 30));
    });

    test('reads a time without a zone as the wall clock of its publisher', () {
      // A phone five hours behind UTC wrote its own 09:00 and its offset.
      // Whatever zone the reader is in, that is 14:00 UTC.
      final info = SignalingPresenceInfoMapper.fromSignaling(
        _incoming(timestamp: '2026-07-31T09:00:00', timeOffsetMin: -300, arrivalTime: heardByCore),
      );

      expect(info.timestamp, DateTime.utc(2026, 7, 31, 14));
    });

    test('has no time when none was sent or it cannot be read', () {
      expect(SignalingPresenceInfoMapper.fromSignaling(_incoming(arrivalTime: heardByCore)).timestamp, isNull);
      expect(
        SignalingPresenceInfoMapper.fromSignaling(_incoming(timestamp: 'yesterday', arrivalTime: heardByCore))
            .timestamp,
        isNull,
      );
    });
  });

  group('the status the app publishes', () {
    test('carries its time as an instant, zone and all', () {
      final localNoon = DateTime(2026, 7, 31, 12);
      final settings = PresenceSettings(
        available: true,
        note: '',
        statusIcon: null,
        device: 'phone',
        timeOffsetMin: localNoon.timeZoneOffset.inMinutes,
        timestamp: localNoon,
        activity: null,
        dndMode: false,
      );

      final sent = SignalingPresenceSettingsMapper.toSignaling(settings).timestamp;

      expect(sent, endsWith('Z'));
      expect(DateTime.parse(sent), localNoon.toUtc());
    });
  });
}
