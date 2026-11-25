import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/mappers/json/presence_settings_mapper.dart';
import 'package:webtrit_phone/mappers/signaling/presence_settings_mapper.dart';
import 'package:webtrit_phone/models/models.dart';

PresenceSettings _settings({required DateTime timestamp, required int timeOffsetMin}) {
  return PresenceSettings(
    available: false,
    note: 'In a meeting',
    statusIcon: null,
    device: 'phone',
    timeOffsetMin: timeOffsetMin,
    timestamp: timestamp,
    activity: PresenceActivity.meeting,
    dndMode: false,
  );
}

/// The settings as an older build of the app left them in the preferences: the
/// wall clock of the phone with no zone, and the offset of that zone beside it.
String _storedByAnOlderBuild({required String timestamp, required int timeOffsetMin}) {
  return jsonEncode({
    'available': false,
    'note': 'In a meeting',
    'statusIcon': null,
    'device': 'phone',
    'timeOffsetMin': timeOffsetMin,
    'timestamp': timestamp,
    'activity': 'meeting',
    'dndMode': false,
  });
}

String _published(PresenceSettings settings) => SignalingPresenceSettingsMapper.toSignaling(settings).timestamp;

void main() {
  group('own status in the preferences', () {
    test('is stored as an instant and read back as the same instant', () {
      // A wall clock with no zone is read back in whatever zone the phone is
      // in by then, so after the phone moved to another zone the status would
      // be published as having been set hours earlier or later than it was.
      final setAt = DateTime(2026, 7, 31, 12, 30, 15, 250);
      final settings = _settings(timestamp: setAt, timeOffsetMin: setAt.timeZoneOffset.inMinutes);

      final stored = PresenceSettingsJsonMapper.toJson(settings);
      final readBack = PresenceSettingsJsonMapper.fromJson(stored);

      expect(jsonDecode(stored)['timestamp'], setAt.toUtc().toIso8601String());
      expect(readBack.timestamp.isAtSameMomentAs(setAt), isTrue);
      expect(readBack.timeOffsetMin, settings.timeOffsetMin);
      expect(DateTime.parse(_published(readBack)), setAt.toUtc());
    });

    test('a value an older build stored is read as the wall clock of the offset stored with it', () {
      // Two hours east of UTC the phone wrote its own 12:00, which is 10:00 UTC
      // in any zone the test runs in. The second case, five hours west, makes
      // the test tell the two readings apart even on a machine two hours east.
      final east = PresenceSettingsJsonMapper.fromJson(
        _storedByAnOlderBuild(timestamp: '2026-07-31T12:00:00.000', timeOffsetMin: 120),
      );
      final west = PresenceSettingsJsonMapper.fromJson(
        _storedByAnOlderBuild(timestamp: '2026-07-31T05:00:00.000', timeOffsetMin: -300),
      );

      expect(_published(east), '2026-07-31T10:00:00.000Z');
      expect(east.timeOffsetMin, 120);
      expect(_published(west), '2026-07-31T10:00:00.000Z');
    });
  });

  group('own status as it is published', () {
    test('a time held as UTC goes out as it is, whatever the offset beside it', () {
      final settings = _settings(timestamp: DateTime.utc(2026, 7, 31, 10), timeOffsetMin: 120);

      expect(_published(settings), '2026-07-31T10:00:00.000Z');
    });

    test('a local time is the wall clock of the offset held with it', () {
      // Read in the zone of the machine it would be another instant wherever
      // that zone is not two hours east of UTC.
      final settings = _settings(timestamp: DateTime(2026, 7, 31, 12), timeOffsetMin: 120);

      expect(_published(settings), '2026-07-31T10:00:00.000Z');
    });

    test('a status set now goes out as the moment it was set', () {
      final before = DateTime.now();
      final settings = PresenceSettings.blank(device: 'phone').copyWithNote('Back at five');
      final after = DateTime.now();

      final sent = DateTime.parse(_published(settings));

      expect(sent.isBefore(before), isFalse);
      expect(sent.isAfter(after), isFalse);
      expect(settings.timeOffsetMin, DateTime.now().timeZoneOffset.inMinutes);
    });
  });
}
