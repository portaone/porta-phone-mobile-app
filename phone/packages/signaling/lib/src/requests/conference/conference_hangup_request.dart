import '../abstract_requests.dart';

/// Tears the conference room down. The merged calls survive; a client
/// that wants them gone hangs each one up itself.
class ConferenceHangupRequest extends SessionRequest {
  const ConferenceHangupRequest({required super.transaction});

  static const typeValue = 'conference_hangup';

  factory ConferenceHangupRequest.fromJson(Map<String, dynamic> json) {
    final requestTypeValue = json[Request.typeKey];
    if (requestTypeValue != typeValue) {
      throw ArgumentError.value(requestTypeValue, Request.typeKey, 'Not equal $typeValue');
    }

    return ConferenceHangupRequest(transaction: json['transaction'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {Request.typeKey: typeValue, 'transaction': transaction};
  }
}
