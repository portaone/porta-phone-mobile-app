import '../abstract_events.dart';

/// The invitation of `conference_video_invite` is over: the conference ended,
/// this participant was removed, or its call ended. Both video
/// PeerConnections are closed; the call carries on unless it was the call that
/// ended.
class ConferenceVideoTerminatedEvent extends SessionEvent {
  const ConferenceVideoTerminatedEvent({super.transaction, this.room});

  final int? room;

  @override
  List<Object?> get props => [...super.props, room];

  static const typeValue = 'conference_video_terminated';

  @override
  Map<String, dynamic> toJson() => {...sessionBaseJson(typeValue), if (room != null) 'room': room};

  factory ConferenceVideoTerminatedEvent.fromJson(Map<String, dynamic> json) {
    final eventTypeValue = json[Event.typeKey];
    if (eventTypeValue != typeValue) {
      throw ArgumentError.value(eventTypeValue, Event.typeKey, 'Not equal $typeValue');
    }

    return ConferenceVideoTerminatedEvent(transaction: json['transaction'], room: json['room'] as int?);
  }
}
