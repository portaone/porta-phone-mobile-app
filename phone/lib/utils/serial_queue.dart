import 'dart:async';

/// Runs actions one at a time, in the order they were handed over.
///
/// For state that several asynchronous operations share: each of them takes
/// more than one await, and an operation slipping in between another's awaits
/// sees that state half-changed. Chaining them removes the question of what
/// runs when.
class SerialQueue {
  Future<void> _tail = Future<void>.value();

  /// Runs [action] after everything already queued, and hands back what it
  /// returns - the error included, if it throws.
  Future<T> run<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    // What the queue waits on is a copy that swallows the failure, so one
    // failed action does not poison every action queued behind it - and does
    // not surface as an unhandled error here, since the caller is given the
    // real result to handle.
    _tail = result.then((_) {}, onError: (_, _) {});
    return result;
  }
}
