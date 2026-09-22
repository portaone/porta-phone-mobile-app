part of 'call_queues_cubit.dart';

/// How the control for every queue at once has to look.
///
/// There is no third state on the wire, so this is derived from the list. From
/// [mixed] the control logs into every queue: that is the start-of-shift
/// action, and the safer of the two to reach by accident.
enum MasterSwitchState { on, off, mixed }

class CallQueuesState extends Equatable {
  const CallQueuesState({
    this.queues = const [],
    this.known = false,
    this.pendingIds = const {},
    this.allPending = false,
    this.readFailed = false,
  });

  CallQueuesState.of(CallQueuesSnapshot snapshot)
    : queues = snapshot.queues,
      known = snapshot.known,
      pendingIds = snapshot.pendingIds,
      allPending = snapshot.allPending,
      readFailed = snapshot.readFailed;

  final List<CallQueue> queues;

  /// Whether a read has completed at least once.
  ///
  /// Until it has, an empty list says nothing: the screen waits instead of
  /// announcing that the user has no queues.
  final bool known;

  final Set<String> pendingIds;

  final bool allPending;

  /// Whether the last read failed.
  ///
  /// The queues already on screen stay: a failed read says nothing about them
  /// being wrong, and blanking the list would cost an agent the only view they
  /// have of their shift.
  final bool readFailed;

  bool get isAgent => queues.isNotEmpty;

  bool isPending(String queueId) => allPending || pendingIds.contains(queueId);

  bool get isBusy => allPending || pendingIds.isNotEmpty;

  int get loggedInCount => queues.where((queue) => queue.loggedIn).length;

  MasterSwitchState get masterState {
    if (queues.isEmpty || loggedInCount == 0) return MasterSwitchState.off;
    if (loggedInCount == queues.length) return MasterSwitchState.on;
    return MasterSwitchState.mixed;
  }

  CallQueuesState copyWith({
    List<CallQueue>? queues,
    bool? known,
    Set<String>? pendingIds,
    bool? allPending,
    bool? readFailed,
  }) => CallQueuesState(
    queues: queues ?? this.queues,
    known: known ?? this.known,
    pendingIds: pendingIds ?? this.pendingIds,
    allPending: allPending ?? this.allPending,
    readFailed: readFailed ?? this.readFailed,
  );

  @override
  List<Object?> get props => [queues, known, pendingIds, allPending, readFailed];
}
