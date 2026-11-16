import 'dart:async';

/// Tells that nothing has been received on a connection for as long as a
/// live one may stay quiet.
///
/// What is sent on a connection says nothing about it - a request leaves a
/// dead one as well as a live one. What is received does. So the watch is
/// restarted by [heard] alone, and runs out however busy the sending side
/// is. It tells once and then waits for something to be heard.
class ReceiveWatchdog {
  ReceiveWatchdog({required this.quiet, required this.onQuiet});

  /// How long the connection may stay quiet. Asked at each restart, since
  /// the server names the interval after connecting.
  final Duration Function() quiet;

  final void Function() onQuiet;

  Timer? _timer;
  bool _watching = false;

  void start() {
    _watching = true;
    _schedule();
  }

  /// Something was received: the quiet time starts over. Ignored when the
  /// watch is not running.
  void heard() {
    if (_watching) _schedule();
  }

  void stop() {
    _watching = false;
    _timer?.cancel();
    _timer = null;
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(quiet(), onQuiet);
  }
}
