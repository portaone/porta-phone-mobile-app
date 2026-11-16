import '../abstract_requests.dart';

/// Stops publishing. Sent before the publisher PeerConnection is closed, so
/// that the room does not report the closed PeerConnection as a failure.
/// Refused with `not_publishing` when nothing is published.
class ConferenceVideoUnpublishRequest extends SessionRequest {
  const ConferenceVideoUnpublishRequest({required super.transaction});

  static const typeValue = 'conference_video_unpublish';

  factory ConferenceVideoUnpublishRequest.fromJson(Map<String, dynamic> json) {
    final requestTypeValue = json[Request.typeKey];
    if (requestTypeValue != typeValue) {
      throw ArgumentError.value(requestTypeValue, Request.typeKey, 'Not equal $typeValue');
    }

    return ConferenceVideoUnpublishRequest(transaction: json['transaction'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {Request.typeKey: typeValue, 'transaction': transaction};
  }
}
