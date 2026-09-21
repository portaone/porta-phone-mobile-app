import 'package:webtrit_phone/models/messaging/notification_mute.dart';

class NotificationMutePhxMapper {
  /// Reads the mute pair off a conversation payload, a mute reply or a
  /// `*_mute_update` event - all three carry the same two fields.
  ///
  /// Both are absent on a core without the functionality, and on every
  /// `chat_info_update`, which is broadcast to the whole chat and deliberately
  /// carries no per-member state. Absent reads as [NotificationMute.none] here,
  /// so a caller that maps such a payload must not store the result over what
  /// it already knows - see the merge rule in the sync worker.
  static NotificationMute fromMap(Map<String, dynamic> map) {
    final mutedUntil = map['notifications_muted_until'];

    return NotificationMute(
      muted: map['notifications_muted'] as bool? ?? false,
      mutedUntil: mutedUntil is String ? DateTime.parse(mutedUntil) : null,
    );
  }

  /// The payload of a `chat:mute` / `sms:conversation:mute` request.
  ///
  /// No field at all is the protocol's "forever" - not a far-future timestamp,
  /// which the core would take as an ordinary expiry.
  ///
  /// The conversion to UTC is not cosmetic. The core refuses a timestamp with
  /// no offset rather than guess at the zone (`invalid_mute_expiration`), and
  /// `toIso8601String` writes an offset only for a UTC value: handed a local
  /// [DateTime] it produces exactly the string that gets refused.
  static Map<String, dynamic> toMuteRequest(DateTime? mutedUntil) {
    if (mutedUntil == null) return {};

    return {'muted_until': mutedUntil.toUtc().toIso8601String()};
  }
}

mixin NotificationMutePhxMapperMixin {
  NotificationMute fromMap(Map<String, dynamic> map) => NotificationMutePhxMapper.fromMap(map);
}
