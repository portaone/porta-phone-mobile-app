import 'package:freezed_annotation/freezed_annotation.dart';

import 'call_queue.dart';

part 'call_queue_list_response.freezed.dart';

part 'call_queue_list_response.g.dart';

/// The call queues the user is an agent of.
///
/// An empty [items] is an answer rather than an error: it is how the backend
/// says this user is not a call center agent at all, and a client hides the
/// feature for them exactly as it does where the backend does not offer it.
@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CallQueueListResponse with _$CallQueueListResponse {
  const CallQueueListResponse({required this.items});

  @override
  final List<CallQueue> items;

  factory CallQueueListResponse.fromJson(Map<String, dynamic> json) => _$CallQueueListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CallQueueListResponseToJson(this);
}
