import '../../conference_video_types.dart';
import '../../ice_candidate_json.dart';
import '../abstract_requests.dart';

/// An ICE candidate for one of the two conference video PeerConnections, named
/// by [pc]. A `null` [candidate] ends the gathering and is sent as
/// `{"completed": true}`, as on the mixer's trickle; Core hands it to Janus
/// as is. A trickle for a PeerConnection Core has not made yet is refused with
/// `no_peer_connection`: candidates wait for the publish or subscribe ack.
class ConferenceVideoIceTrickleRequest extends SessionRequest {
  const ConferenceVideoIceTrickleRequest({required super.transaction, required this.pc, this.candidate});

  final ConferenceVideoPc pc;
  final Map<String, dynamic>? candidate;

  @override
  List<Object?> get props => [...super.props, pc, candidate];

  static const typeValue = 'conference_video_ice_trickle';

  factory ConferenceVideoIceTrickleRequest.fromJson(Map<String, dynamic> json) {
    final requestTypeValue = json[Request.typeKey];
    if (requestTypeValue != typeValue) {
      throw ArgumentError.value(requestTypeValue, Request.typeKey, 'Not equal $typeValue');
    }

    return ConferenceVideoIceTrickleRequest(
      transaction: json['transaction'] as String,
      pc: ConferenceVideoPc.fromValue(json['pc']),
      candidate: iceCandidateFromJson(json['candidate']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      Request.typeKey: typeValue,
      'transaction': transaction,
      'pc': pc.value,
      'candidate': iceCandidateToJson(candidate),
    };
  }
}
