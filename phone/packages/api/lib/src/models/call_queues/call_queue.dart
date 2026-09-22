import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_queue.freezed.dart';

part 'call_queue.g.dart';

/// One call queue the user serves as an agent, with its current load.
///
/// A call queue is a hunt group on the PBX that callers wait in until an agent
/// takes them. Being logged in is per queue, not per user: an agent can be
/// taking calls from one queue while logged out of another.
@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CallQueue with _$CallQueue {
  const CallQueue({
    required this.id,
    required this.name,
    required this.loggedIn,
    required this.agentsTotal,
    required this.agentsLoggedIn,
    this.callersWaiting,
  });

  /// The queue's number on the PBX, which is also what logging in and out is
  /// addressed by - there is no separate identifier to pass.
  @override
  final String id;

  @override
  final String name;

  /// Whether THIS user is currently taking calls from the queue.
  ///
  /// The same flag is written by the PBX dial codes and by the self-care
  /// portal, so it is read from every answer rather than assumed after a write.
  @override
  final bool loggedIn;

  @override
  final int agentsTotal;

  /// How many agents are logged in right now.
  ///
  /// Never null, and legitimately zero - a queue nobody is covering.
  @override
  final int agentsLoggedIn;

  /// How many callers are queued, or null when that figure is unknown.
  ///
  /// Null is not zero, and it is not transient: where the PBX call control
  /// interface is unreachable or not permitted it is null on every queue,
  /// permanently. Rendering it as zero tells an agent that nobody is waiting
  /// while callers are on hold, which is why it stays nullable all the way up
  /// to the screen instead of being coalesced here.
  @override
  final int? callersWaiting;

  factory CallQueue.fromJson(Map<String, dynamic> json) => _$CallQueueFromJson(json);

  Map<String, dynamic> toJson() => _$CallQueueToJson(this);
}
