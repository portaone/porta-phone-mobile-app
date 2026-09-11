import '../abstract_events.dart';

/// The conference could not be built and no longer exists.
///
/// Core sends this for `video_not_supported` only; every other assembly failure
/// (a leg that never joins, a codec the mixer cannot speak) drops the leg and
/// ends up as `conference_updated` or `conference_terminated`.
class ConferenceFailedEvent extends SessionEvent {
  const ConferenceFailedEvent({super.transaction, required this.reason, this.room, this.detail});

  final int? room;
  final String reason;
  final String? detail;

  @override
  List<Object?> get props => [...super.props, room, reason, detail];

  static const typeValue = 'conference_failed';

  @override
  Map<String, dynamic> toJson() => {
    ...sessionBaseJson(typeValue),
    if (room != null) 'room': room,
    'reason': reason,
    if (detail != null) 'detail': detail,
  };

  factory ConferenceFailedEvent.fromJson(Map<String, dynamic> json) {
    final eventTypeValue = json[Event.typeKey];
    if (eventTypeValue != typeValue) {
      throw ArgumentError.value(eventTypeValue, Event.typeKey, 'Not equal $typeValue');
    }

    return ConferenceFailedEvent(
      transaction: json['transaction'],
      room: json['room'] as int?,
      reason: json['reason'] as String,
      detail: json['detail'] as String?,
    );
  }
}
