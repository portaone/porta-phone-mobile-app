import 'package:equatable/equatable.dart';

import 'call_queue.dart';

/// What is known about the user's call queues right now.
///
/// [known] is what separates "not an agent" from "not asked yet": both show an
/// empty list, and only one of them is an answer. Until the first read
/// completes the feature hides rather than announcing that the user has no
/// queues.
class CallQueuesSnapshot extends Equatable {
  const CallQueuesSnapshot({
    this.queues = const [],
    this.known = false,
    this.pendingIds = const {},
    this.allPending = false,
    this.readFailed = false,
  });

  final List<CallQueue> queues;

  /// Whether a read has completed at least once in this session.
  final bool known;

  /// Queues whose own log in / log out request is in flight.
  final Set<String> pendingIds;

  /// Whether a log in / log out of every queue at once is in flight.
  final bool allPending;

  /// Whether the last read failed.
  ///
  /// Published here rather than kept by whoever asked, because the reads are a
  /// polling task nobody awaits: a screen whose first read failed has no other
  /// way of learning that it is waiting for something that is not coming.
  /// Whatever was read before is kept - a failure says nothing about it.
  final bool readFailed;

  /// Whether this user is a call center agent at all.
  ///
  /// An empty list from the backend is the per-user gate: the deployment offers
  /// the feature, this person is not an agent of anything, and the entry to the
  /// screen is hidden for them.
  bool get isAgent => queues.isNotEmpty;

  /// Whether a request that would change [queueId] is already in flight.
  bool isPending(String queueId) => allPending || pendingIds.contains(queueId);

  /// Whether anything at all is in flight.
  bool get isBusy => allPending || pendingIds.isNotEmpty;

  CallQueuesSnapshot copyWith({
    List<CallQueue>? queues,
    bool? known,
    Set<String>? pendingIds,
    bool? allPending,
    bool? readFailed,
  }) => CallQueuesSnapshot(
    queues: queues ?? this.queues,
    known: known ?? this.known,
    pendingIds: pendingIds ?? this.pendingIds,
    allPending: allPending ?? this.allPending,
    readFailed: readFailed ?? this.readFailed,
  );

  @override
  List<Object?> get props => [queues, known, pendingIds, allPending, readFailed];
}
