import '../abstract_requests.dart';

/// Silences the participant on [line] for the whole room, or unsilences them.
/// Their call is untouched; only the mixer stops taking their audio.
class ConferenceMuteRequest extends SessionRequest {
  const ConferenceMuteRequest({required super.transaction, required this.line, required this.muted});

  final int line;
  final bool muted;

  @override
  List<Object?> get props => [...super.props, line, muted];

  static const typeValue = 'conference_mute';

  factory ConferenceMuteRequest.fromJson(Map<String, dynamic> json) {
    final requestTypeValue = json[Request.typeKey];
    if (requestTypeValue != typeValue) {
      throw ArgumentError.value(requestTypeValue, Request.typeKey, 'Not equal $typeValue');
    }

    return ConferenceMuteRequest(
      transaction: json['transaction'] as String,
      line: json['line'] as int,
      muted: json['muted'] as bool,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {Request.typeKey: typeValue, 'transaction': transaction, 'line': line, 'muted': muted};
  }
}
