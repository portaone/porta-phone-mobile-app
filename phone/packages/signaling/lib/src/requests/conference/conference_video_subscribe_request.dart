import '../abstract_requests.dart';

/// Starts receiving the conference's video: from now on Core keeps this client
/// subscribed to every stream of everyone else, sends `conference_video_updated`
/// at once and a `conference_video_offer` whenever there is something to
/// receive. Sent again, it remakes the subscription from scratch, and the new
/// offer is answered on a new PeerConnection.
class ConferenceVideoSubscribeRequest extends SessionRequest {
  const ConferenceVideoSubscribeRequest({required super.transaction});

  static const typeValue = 'conference_video_subscribe';

  factory ConferenceVideoSubscribeRequest.fromJson(Map<String, dynamic> json) {
    final requestTypeValue = json[Request.typeKey];
    if (requestTypeValue != typeValue) {
      throw ArgumentError.value(requestTypeValue, Request.typeKey, 'Not equal $typeValue');
    }

    return ConferenceVideoSubscribeRequest(transaction: json['transaction'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {Request.typeKey: typeValue, 'transaction': transaction};
  }
}
