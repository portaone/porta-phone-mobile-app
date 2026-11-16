import '../abstract_events.dart';

/// The room's offer for the subscriber PeerConnection: the first one once
/// there is something to receive, then one for every change of what this
/// client receives (one offer may cover several changes), and one with an ICE
/// restart after `conference_video_restart`. Answered with
/// `conference_video_answer`. An offer after a new subscription, or after Janus
/// hung the old subscriber up, goes on a new PeerConnection.
class ConferenceVideoOfferEvent extends SessionEvent {
  const ConferenceVideoOfferEvent({super.transaction, required this.jsep});

  final Map<String, dynamic> jsep;

  @override
  List<Object?> get props => [...super.props, jsep];

  static const typeValue = 'conference_video_offer';

  @override
  Map<String, dynamic> toJson() => {...sessionBaseJson(typeValue), 'jsep': jsep};

  factory ConferenceVideoOfferEvent.fromJson(Map<String, dynamic> json) {
    final eventTypeValue = json[Event.typeKey];
    if (eventTypeValue != typeValue) {
      throw ArgumentError.value(eventTypeValue, Event.typeKey, 'Not equal $typeValue');
    }

    return ConferenceVideoOfferEvent(transaction: json['transaction'], jsep: json['jsep'] as Map<String, dynamic>);
  }
}
