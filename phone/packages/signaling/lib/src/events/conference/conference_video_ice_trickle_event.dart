import '../../conference_video_types.dart';
import '../../ice_candidate_json.dart';
import '../abstract_events.dart';

/// An ICE candidate from the room for one of the two conference video
/// PeerConnections, named by [pc]. The completed marker arrives as a `null`
/// [candidate], as on the mixer's trickle. [pc] is `null` for a PeerConnection
/// this client does not know, from a newer Core: such a candidate has nowhere
/// to go, and failing the event would fail the connection.
class ConferenceVideoIceTrickleEvent extends SessionEvent {
  const ConferenceVideoIceTrickleEvent({super.transaction, required this.pc, this.candidate});

  final ConferenceVideoPc? pc;
  final Map<String, dynamic>? candidate;

  @override
  List<Object?> get props => [...super.props, pc, candidate];

  static const typeValue = 'conference_video_ice_trickle';

  @override
  Map<String, dynamic> toJson() => {
    ...sessionBaseJson(typeValue),
    if (pc != null) 'pc': pc!.value,
    'candidate': iceCandidateToJson(candidate),
  };

  factory ConferenceVideoIceTrickleEvent.fromJson(Map<String, dynamic> json) {
    final eventTypeValue = json[Event.typeKey];
    if (eventTypeValue != typeValue) {
      throw ArgumentError.value(eventTypeValue, Event.typeKey, 'Not equal $typeValue');
    }

    return ConferenceVideoIceTrickleEvent(
      transaction: json['transaction'],
      pc: ConferenceVideoPc.tryFromValue(json['pc']),
      candidate: iceCandidateFromJson(json['candidate']),
    );
  }
}
