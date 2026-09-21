import 'package:webtrit_phone/models/messaging/notification_mute.dart';

class NotificationMutePhxMapper {
  /// Reads the mute pair off a mute reply or a `*_mute_update` event, which
  /// always carry both fields.
  ///
  /// The mute is mapped from those two and from the `chat:get` /
  /// `sms:conversation:get` replies only - never from `chat_info_update`,
  /// which is broadcast to the whole chat and deliberately carries no
  /// per-member state. That is what keeps a broadcast from writing "not
  /// muted" over a real mute: there is no code path that maps one to a mute.
  static NotificationMute fromMap(Map<String, dynamic> map) {
    final mutedUntil = map['notifications_muted_until'];

    // Read as "is it true", not cast: a null or a missing flag reads as not
    // muted, where a failed cast inside the personal-topic stream would tear
    // down every conversation subscription and restart the sync.
    return NotificationMute(
      muted: map['notifications_muted'] == true,
      mutedUntil: mutedUntil is String ? DateTime.parse(mutedUntil) : null,
    );
  }

  /// Reads the mute pair off a conversation payload, where it may be missing
  /// altogether: a core without the functionality sends the conversation
  /// without these fields.
  ///
  /// Missing is null, not [NotificationMute.none]. The two read the same to a
  /// user, but not to storage: "the core says nothing" is not knowledge, and a
  /// caller that stored it as "not muted" would be inventing a row per
  /// conversation on every sync of a deployment that has no mute at all.
  static NotificationMute? fromMapOrNull(Map<String, dynamic> map) {
    if (map['notifications_muted'] == null) return null;

    return fromMap(map);
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
