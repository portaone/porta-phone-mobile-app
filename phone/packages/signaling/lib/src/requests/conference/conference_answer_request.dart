import '../abstract_requests.dart';

/// The client's SDP answer to a `conference_offer` event.
class ConferenceAnswerRequest extends SessionRequest {
  const ConferenceAnswerRequest({required super.transaction, required this.jsep});

  final Map<String, dynamic> jsep;

  @override
  List<Object?> get props => [...super.props, jsep];

  static const typeValue = 'conference_answer';

  factory ConferenceAnswerRequest.fromJson(Map<String, dynamic> json) {
    final requestTypeValue = json[Request.typeKey];
    if (requestTypeValue != typeValue) {
      throw ArgumentError.value(requestTypeValue, Request.typeKey, 'Not equal $typeValue');
    }

    return ConferenceAnswerRequest(
      transaction: json['transaction'] as String,
      jsep: json['jsep'] as Map<String, dynamic>,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {Request.typeKey: typeValue, 'transaction': transaction, 'jsep': jsep};
  }
}
