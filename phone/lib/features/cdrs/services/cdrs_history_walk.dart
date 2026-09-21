import 'dart:async';

/// Runs one walk through the call history at a time.
///
/// The watermark in the store tells a walk where a PREVIOUS one stopped, which
/// is enough when walks follow one another - a screen opened again, the next
/// launch. It says nothing about a walk still in flight: two lists that mount
/// together read the same watermark in the same frame, and each then works
/// through its own sequence of slices, asking for every one of them twice.
///
/// So the walks queue instead. Each starts by reading the watermark, and by the
/// time the second one starts the first has moved it - which is the difference
/// between "walked before" and "walking now" that the watermark alone cannot
/// express.
class CdrsHistoryWalkQueue {
  Future<void> _tail = Future<void>.value();

  /// Runs [walk] after whatever is already queued, and keeps the queue alive
  /// when one of them fails: a walk that throws is the caller's to report, not
  /// a reason for the next list to wait forever.
  Future<void> add(Future<void> Function() walk) {
    final run = _tail.then((_) => walk());
    _tail = run.then((_) {}, onError: (_) {});
    return run;
  }
}
