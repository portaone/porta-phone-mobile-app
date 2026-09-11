import '../abstract_events.dart';
import 'conference_participant.dart';

/// The participant list changed: someone joined, left, or was muted.
/// Authoritative; render from it. A leg the server dropped on its own (a codec
/// the mixer cannot speak) shows up here as a missing participant, not as a
/// `conference_failed`.
class ConferenceUpdatedEvent extends SessionEvent {
  const ConferenceUpdatedEvent({super.transaction, required this.room, this.participants = const []});

  final int room;
  final List<ConferenceParticipant> participants;

  @override
  List<Object?> get props => [...super.props, room, participants];

  static const typeValue = 'conference_updated';

  @override
  Map<String, dynamic> toJson() => {
    ...sessionBaseJson(typeValue),
    'room': room,
    'participants': ConferenceParticipant.listToJson(participants),
  };

  factory ConferenceUpdatedEvent.fromJson(Map<String, dynamic> json) {
    final eventTypeValue = json[Event.typeKey];
    if (eventTypeValue != typeValue) {
      throw ArgumentError.value(eventTypeValue, Event.typeKey, 'Not equal $typeValue');
    }

    return ConferenceUpdatedEvent(
      transaction: json['transaction'],
      room: json['room'] as int,
      participants: ConferenceParticipant.listFromJson(json['participants'] as List<dynamic>?),
    );
  }
}
