import '../abstract_requests.dart';

/// Brings one more established call, the one on [line], into the running
/// conference. `line` names a participant, not an address.
class ConferenceAddRequest extends SessionRequest {
  const ConferenceAddRequest({required super.transaction, required this.line});

  final int line;

  @override
  List<Object?> get props => [...super.props, line];

  static const typeValue = 'conference_add';

  factory ConferenceAddRequest.fromJson(Map<String, dynamic> json) {
    final requestTypeValue = json[Request.typeKey];
    if (requestTypeValue != typeValue) {
      throw ArgumentError.value(requestTypeValue, Request.typeKey, 'Not equal $typeValue');
    }

    return ConferenceAddRequest(transaction: json['transaction'] as String, line: json['line'] as int);
  }

  @override
  Map<String, dynamic> toJson() {
    return {Request.typeKey: typeValue, 'transaction': transaction, 'line': line};
  }
}
