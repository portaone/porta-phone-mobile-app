import '../../ice_candidate_json.dart';
import '../abstract_events.dart';

/// An ICE candidate from the mixer for the conference PeerConnection.
/// `{"completed": true}` ends the gathering and arrives as a `null` [candidate],
/// the same convention as `IceTrickleEvent`; see `ice_candidate_json.dart`.
class ConferenceIceTrickleEvent extends SessionEvent {
  const ConferenceIceTrickleEvent({super.transaction, required this.candidate});

  final Map<String, dynamic>? candidate;

  @override
  List<Object?> get props => [...super.props, candidate];

  static const typeValue = 'conference_ice_trickle';

  @override
  Map<String, dynamic> toJson() => {...sessionBaseJson(typeValue), 'candidate': iceCandidateToJson(candidate)};

  factory ConferenceIceTrickleEvent.fromJson(Map<String, dynamic> json) {
    final eventTypeValue = json[Event.typeKey];
    if (eventTypeValue != typeValue) {
      throw ArgumentError.value(eventTypeValue, Event.typeKey, 'Not equal $typeValue');
    }

    return ConferenceIceTrickleEvent(
      transaction: json['transaction'],
      candidate: iceCandidateFromJson(json['candidate']),
    );
  }
}
