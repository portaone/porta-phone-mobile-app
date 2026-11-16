import '../abstract_requests.dart';

/// Stops publishing and receiving video; both video PeerConnections are then
/// closed. The participant stays in the audio conference, and an invited far
/// end keeps its invitation.
class ConferenceVideoLeaveRequest extends SessionRequest {
  const ConferenceVideoLeaveRequest({required super.transaction});

  static const typeValue = 'conference_video_leave';

  factory ConferenceVideoLeaveRequest.fromJson(Map<String, dynamic> json) {
    final requestTypeValue = json[Request.typeKey];
    if (requestTypeValue != typeValue) {
      throw ArgumentError.value(requestTypeValue, Request.typeKey, 'Not equal $typeValue');
    }

    return ConferenceVideoLeaveRequest(transaction: json['transaction'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {Request.typeKey: typeValue, 'transaction': transaction};
  }
}
