import '../abstract_requests.dart';

/// Merges the established calls on [lines] into a conference room.
///
/// Session-level: the room is addressed by the session, not by a line. Core
/// accepts a single line here; the client enforces "two or more" itself.
class MergeRequest extends SessionRequest {
  const MergeRequest({required super.transaction, required this.lines});

  final List<int> lines;

  @override
  List<Object?> get props => [...super.props, lines];

  static const typeValue = 'merge';

  factory MergeRequest.fromJson(Map<String, dynamic> json) {
    final requestTypeValue = json[Request.typeKey];
    if (requestTypeValue != typeValue) {
      throw ArgumentError.value(requestTypeValue, Request.typeKey, 'Not equal $typeValue');
    }

    return MergeRequest(
      transaction: json['transaction'] as String,
      lines: (json['lines'] as List<dynamic>).cast<int>(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {Request.typeKey: typeValue, 'transaction': transaction, 'lines': lines};
  }
}
