/// The end-of-candidates marker on the signalling wire.
///
/// Janus and Core relay ICE candidates verbatim and mark the end of gathering
/// with `{"completed": true}` instead of a candidate object. Inbound, that
/// marker (or a missing candidate) becomes `null`; outbound, `null` becomes the
/// marker. Used by the line-level `ice_trickle` event and by both conference
/// trickle messages. The line-level `IceTrickleRequest` predates this helper
/// and still sends a bare `null`, which Core also accepts; it is left as is so
/// the line path's wire format does not change.
const Map<String, dynamic> iceCandidatesCompletedJson = {'completed': true};

Map<String, dynamic>? iceCandidateFromJson(Object? json) {
  if (json is! Map<String, dynamic>) return null;
  if (json['completed'] == true) return null;
  return json;
}

Map<String, dynamic> iceCandidateToJson(Map<String, dynamic>? candidate) => candidate ?? iceCandidatesCompletedJson;
