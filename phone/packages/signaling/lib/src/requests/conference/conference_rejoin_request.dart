import '../abstract_requests.dart';

/// Puts the host back into the running room over a new peer connection,
/// after the one to the mixer was lost. The room and its participants stay
/// as they are; a new `conference_offer` for the same room follows.
class ConferenceRejoinRequest extends SessionRequest {
  const ConferenceRejoinRequest({required super.transaction});

  static const typeValue = 'conference_rejoin';

  factory ConferenceRejoinRequest.fromJson(Map<String, dynamic> json) {
    final requestTypeValue = json[Request.typeKey];
    if (requestTypeValue != typeValue) {
      throw ArgumentError.value(requestTypeValue, Request.typeKey, 'Not equal $typeValue');
    }

    return ConferenceRejoinRequest(transaction: json['transaction'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {Request.typeKey: typeValue, 'transaction': transaction};
  }
}
