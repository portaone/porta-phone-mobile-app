/// Runs [init] once and shares its future with every caller.
///
/// A caller that arrives while the first run is still pending waits on that run instead of
/// starting one of its own - which is what `x ??= await init()` cannot promise: every caller
/// that reads the field before the first run resolves sees it empty and runs `init` again.
/// A run that fails is forgotten, so the next caller tries again; a run that succeeds is
/// kept for the lifetime of this object.
class AsyncOnce<T> {
  AsyncOnce(this._init);

  final Future<T> Function() _init;
  Future<T>? _pending;

  Future<T> call() => _pending ??= _run();

  Future<T> _run() async {
    try {
      return await _init();
    } catch (_) {
      _pending = null;
      rethrow;
    }
  }
}
