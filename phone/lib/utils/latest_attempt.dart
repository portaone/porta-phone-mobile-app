/// Numbers the attempts of one action, so that something offered for an
/// attempt - a "try again" that outlives it - can tell whether a newer one has
/// started since and it no longer stands for what the user wants.
class LatestAttempt {
  int _latest = 0;

  /// The number of the attempt begun last; 0 before the first.
  int get latest => _latest;

  /// Starts a new attempt and returns its number; every earlier attempt stops
  /// being the latest.
  int begin() => ++_latest;

  /// Whether no attempt has begun since [attempt].
  bool isLatest(int attempt) => attempt == _latest;
}
