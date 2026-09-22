part of 'call_queues_cubit.dart';

/// How the control for every queue at once has to look.
///
/// There is no third state on the wire, so this is derived from the list. From
/// [mixed] the control logs into every queue: that is the start-of-shift
/// action, and the safer of the two to reach by accident.
enum MasterSwitchState { on, off, mixed }

@freezed
class CallQueuesState with _$CallQueuesState {
  const CallQueuesState({
    this.queues = const [],
    this.known = false,
    this.pendingIds = const {},
    this.allPending = false,
    this.readFailed = false,
  });

  /// The state the repository's snapshot describes.
  ///
  /// The cubit adds nothing of its own: what a screen shows is what the last
  /// answer said, whoever asked for it - this screen, the other placement of
  /// it, or the polling task behind both.
  CallQueuesState.of(CallQueuesSnapshot snapshot)
    : this(
        queues: snapshot.queues,
        known: snapshot.known,
        pendingIds: snapshot.pendingIds,
        allPending: snapshot.allPending,
        readFailed: snapshot.readFailed,
      );

  @override
  final List<CallQueue> queues;

  /// Whether a read has completed at least once.
  ///
  /// Until it has, an empty list says nothing: the screen waits instead of
  /// announcing that the user has no queues.
  @override
  final bool known;

  @override
  final Set<String> pendingIds;

  @override
  final bool allPending;

  /// Whether the last read failed.
  ///
  /// The queues already on screen stay: a failed read says nothing about them
  /// being wrong, and blanking the list would cost an agent the only view they
  /// have of their shift.
  @override
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
}
