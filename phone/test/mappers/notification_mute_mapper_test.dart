import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/mappers/phoenix/messaging/notification_mute_mapper.dart';
import 'package:webtrit_phone/models/models.dart';

void main() {
  // The mute is a pair of fields, and the three states it can express are not
  // interchangeable: "not muted", "muted forever" and "muted until a moment".
  // Reading them apart is the whole job of this mapper.
  group('reading the mute pair off a payload', () {
    test('both fields absent is not muted', () {
      final mute = NotificationMutePhxMapper.fromMap({'id': 42, 'name': 'engineering'});

      expect(mute, NotificationMute.none);
    });

    test('muted with no expiration is muted forever', () {
      final mute = NotificationMutePhxMapper.fromMap({
        'chat_id': 42,
        'notifications_muted': true,
        'notifications_muted_until': null,
      });

      expect(mute.muted, isTrue);
      expect(mute.mutedUntil, isNull);
      expect(mute.isActiveAt(DateTime.utc(2999)), isTrue);
    });

    test('muted with an expiration keeps the moment, microseconds and all', () {
      final mute = NotificationMutePhxMapper.fromMap({
        'chat_id': 42,
        'notifications_muted': true,
        'notifications_muted_until': '2026-09-01T18:00:00.000000Z',
      });

      expect(mute.mutedUntil, DateTime.utc(2026, 9, 1, 18));
    });

    test('not muted reads as none, so a stored value compares equal to it', () {
      final mute = NotificationMutePhxMapper.fromMap({
        'chat_id': 42,
        'notifications_muted': false,
        'notifications_muted_until': null,
      });

      expect(mute, NotificationMute.none);
    });
  });

  // The core refuses a timestamp without an offset rather than guessing at the
  // zone, and Dart writes an offset only for a UTC value. A local DateTime
  // handed straight to `toIso8601String` is exactly the string that comes back
  // as `invalid_mute_expiration`.
  group('building a mute request', () {
    test('no expiration sends no field at all, which is the protocol forever', () {
      expect(NotificationMutePhxMapper.toMuteRequest(null), isEmpty);
    });

    test('a local time is sent with an offset, not as a bare local timestamp', () {
      final until = DateTime(2026, 9, 1, 18);

      final muteRequest = NotificationMutePhxMapper.toMuteRequest(until);
      final mutedUntil = muteRequest['muted_until'] as String;

      expect(mutedUntil, endsWith('Z'));
      expect(DateTime.parse(mutedUntil).isAtSameMomentAs(until), isTrue);
    });

    test('a time already in utc survives unchanged', () {
      final muteRequest = NotificationMutePhxMapper.toMuteRequest(DateTime.utc(2026, 9, 1, 18));

      expect(muteRequest['muted_until'], '2026-09-01T18:00:00.000Z');
    });
  });

  // The state is derived on every read because the expiry passes silently:
  // no job clears the flag, no event tells the client.
  group('a mute expires on its own', () {
    test('a timed mute is active before its moment and not after it', () {
      final mute = NotificationMute(muted: true, mutedUntil: DateTime.utc(2026, 9, 1, 18));

      expect(mute.isActiveAt(DateTime.utc(2026, 9, 1, 17, 59, 59)), isTrue);
      expect(mute.isActiveAt(DateTime.utc(2026, 9, 1, 18)), isFalse);
      expect(mute.isActiveAt(DateTime.utc(2026, 9, 1, 18, 0, 1)), isFalse);
    });

    test('an unmuted conversation is never active, whatever the expiration says', () {
      final mute = NotificationMute(muted: false, mutedUntil: DateTime.utc(2999));

      expect(mute.isActiveAt(DateTime.utc(2026)), isFalse);
    });
  });
}
