import '../abstract_requests.dart';

/// Takes the leg on [line] out of the mix and leaves its call up.
///
/// Carried for protocol completeness. The app ends a participant's call with an
/// ordinary hangup instead, which removes the leg as a side effect.
class ConferenceRemoveRequest extends SessionRequest {
  const ConferenceRemoveRequest({required super.transaction, required this.line});

  final int line;

  @override
  List<Object?> get props => [...super.props, line];

  static const typeValue = 'conference_remove';

  factory ConferenceRemoveRequest.fromJson(Map<String, dynamic> json) {
    final requestTypeValue = json[Request.typeKey];
    if (requestTypeValue != typeValue) {
      throw ArgumentError.value(requestTypeValue, Request.typeKey, 'Not equal $typeValue');
    }

    return ConferenceRemoveRequest(transaction: json['transaction'] as String, line: json['line'] as int);
  }

  @override
  Map<String, dynamic> toJson() {
    return {Request.typeKey: typeValue, 'transaction': transaction, 'line': line};
  }
}
