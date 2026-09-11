import '../abstract_events.dart';
import 'conference_participant.dart';

/// The mixer's SDP offer. Answered on a fresh PeerConnection with a
/// `conference_answer` request; this is what marks the conference established.
class ConferenceOfferEvent extends SessionEvent {
  const ConferenceOfferEvent({super.transaction, required this.room, required this.jsep, this.participants = const []});

  final int room;
  final Map<String, dynamic> jsep;
  final List<ConferenceParticipant> participants;

  @override
  List<Object?> get props => [...super.props, room, jsep, participants];

  static const typeValue = 'conference_offer';

  @override
  Map<String, dynamic> toJson() => {
    ...sessionBaseJson(typeValue),
    'room': room,
    'jsep': jsep,
    'participants': ConferenceParticipant.listToJson(participants),
  };

  factory ConferenceOfferEvent.fromJson(Map<String, dynamic> json) {
    final eventTypeValue = json[Event.typeKey];
    if (eventTypeValue != typeValue) {
      throw ArgumentError.value(eventTypeValue, Event.typeKey, 'Not equal $typeValue');
    }

    return ConferenceOfferEvent(
      transaction: json['transaction'],
      room: json['room'] as int,
      jsep: json['jsep'] as Map<String, dynamic>,
      participants: ConferenceParticipant.listFromJson(json['participants'] as List<dynamic>?),
    );
  }
}
