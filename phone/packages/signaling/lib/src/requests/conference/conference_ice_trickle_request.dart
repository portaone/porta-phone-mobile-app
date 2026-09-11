import '../../ice_candidate_json.dart';
import '../abstract_requests.dart';

/// An ICE candidate for the conference PeerConnection.
///
/// The conference PeerConnection is not one of the lines, so its candidates
/// cannot travel on the per-line `ice_trickle` path. A `null` [candidate] is
/// the end-of-candidates marker and is sent as `{"completed": true}`, the
/// convention `IceTrickleEvent` already decodes; see `ice_candidate_json.dart`.
class ConferenceIceTrickleRequest extends SessionRequest {
  const ConferenceIceTrickleRequest({required super.transaction, this.candidate});

  final Map<String, dynamic>? candidate;

  @override
  List<Object?> get props => [...super.props, candidate];

  static const typeValue = 'conference_ice_trickle';

  factory ConferenceIceTrickleRequest.fromJson(Map<String, dynamic> json) {
    final requestTypeValue = json[Request.typeKey];
    if (requestTypeValue != typeValue) {
      throw ArgumentError.value(requestTypeValue, Request.typeKey, 'Not equal $typeValue');
    }

    return ConferenceIceTrickleRequest(
      transaction: json['transaction'] as String,
      candidate: iceCandidateFromJson(json['candidate']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {Request.typeKey: typeValue, 'transaction': transaction, 'candidate': iceCandidateToJson(candidate)};
  }
}
