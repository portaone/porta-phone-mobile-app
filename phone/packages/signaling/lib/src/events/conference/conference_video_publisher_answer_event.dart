import '../abstract_events.dart';

/// The room's answer to a `conference_video_publish` offer, for the publisher
/// PeerConnection.
class ConferenceVideoPublisherAnswerEvent extends SessionEvent {
  const ConferenceVideoPublisherAnswerEvent({super.transaction, required this.jsep});

  final Map<String, dynamic> jsep;

  @override
  List<Object?> get props => [...super.props, jsep];

  static const typeValue = 'conference_video_publisher_answer';

  @override
  Map<String, dynamic> toJson() => {...sessionBaseJson(typeValue), 'jsep': jsep};

  factory ConferenceVideoPublisherAnswerEvent.fromJson(Map<String, dynamic> json) {
    final eventTypeValue = json[Event.typeKey];
    if (eventTypeValue != typeValue) {
      throw ArgumentError.value(eventTypeValue, Event.typeKey, 'Not equal $typeValue');
    }

    return ConferenceVideoPublisherAnswerEvent(
      transaction: json['transaction'],
      jsep: json['jsep'] as Map<String, dynamic>,
    );
  }
}
