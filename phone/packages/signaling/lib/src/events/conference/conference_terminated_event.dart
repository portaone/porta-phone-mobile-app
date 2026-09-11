import '../abstract_events.dart';

/// The conference is over: the subscriber ended it, fewer than two
/// legs were left to mix, the 10 s setup deadline passed, the controller
/// stopped, or Core lost its Janus session and discarded the room. In the
/// first four cases the merged calls that are still up carry on by themselves;
/// in the last one they have no media any more and their hangup events follow,
/// so a client must check that a call is still established before restoring it.
class ConferenceTerminatedEvent extends SessionEvent {
  const ConferenceTerminatedEvent({super.transaction, this.room});

  final int? room;

  @override
  List<Object?> get props => [...super.props, room];

  static const typeValue = 'conference_terminated';

  @override
  Map<String, dynamic> toJson() => {...sessionBaseJson(typeValue), if (room != null) 'room': room};

  factory ConferenceTerminatedEvent.fromJson(Map<String, dynamic> json) {
    final eventTypeValue = json[Event.typeKey];
    if (eventTypeValue != typeValue) {
      throw ArgumentError.value(eventTypeValue, Event.typeKey, 'Not equal $typeValue');
    }

    return ConferenceTerminatedEvent(transaction: json['transaction'], room: json['room'] as int?);
  }
}
