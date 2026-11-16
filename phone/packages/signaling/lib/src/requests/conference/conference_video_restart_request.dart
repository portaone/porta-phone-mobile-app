import '../abstract_requests.dart';

/// Asks the room for an ICE restart of the subscriber PeerConnection, which
/// only the room can restart since it offered it. A `conference_video_offer`
/// with the restart follows; it is answered on the same PeerConnection.
class ConferenceVideoRestartRequest extends SessionRequest {
  const ConferenceVideoRestartRequest({required super.transaction});

  static const typeValue = 'conference_video_restart';

  factory ConferenceVideoRestartRequest.fromJson(Map<String, dynamic> json) {
    final requestTypeValue = json[Request.typeKey];
    if (requestTypeValue != typeValue) {
      throw ArgumentError.value(requestTypeValue, Request.typeKey, 'Not equal $typeValue');
    }

    return ConferenceVideoRestartRequest(transaction: json['transaction'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {Request.typeKey: typeValue, 'transaction': transaction};
  }
}
