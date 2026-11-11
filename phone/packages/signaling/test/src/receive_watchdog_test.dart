import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import 'package:signaling/src/receive_watchdog.dart';

void main() {
  const quiet = Duration(seconds: 30);

  late int told;
  late ReceiveWatchdog watchdog;

  setUp(() {
    told = 0;
    watchdog = ReceiveWatchdog(quiet: () => quiet, onQuiet: () => told++);
  });

  test('a connection that hears nothing is told quiet after the interval', () {
    fakeAsync((async) {
      watchdog.start();

      async.elapse(quiet - const Duration(milliseconds: 1));
      expect(told, 0);

      async.elapse(const Duration(milliseconds: 1));
      expect(told, 1);
    });
  });

  test('what is heard starts the quiet time over', () {
    fakeAsync((async) {
      watchdog.start();
      async.elapse(const Duration(seconds: 29));
      watchdog.heard();
      async.elapse(const Duration(seconds: 29));
      watchdog.heard();
      async.elapse(const Duration(seconds: 29));
      expect(told, 0);

      async.elapse(const Duration(seconds: 1));
      expect(told, 1);
    });
  });

  test('the interval is asked each time something is heard', () {
    fakeAsync((async) {
      var interval = const Duration(seconds: 30);
      watchdog = ReceiveWatchdog(quiet: () => interval, onQuiet: () => told++);
      watchdog.start();
      interval = const Duration(seconds: 60);
      watchdog.heard();

      async.elapse(const Duration(seconds: 59));
      expect(told, 0);
      async.elapse(const Duration(seconds: 1));
      expect(told, 1);
    });
  });

  test('quiet is told once, and again only after something is heard', () {
    fakeAsync((async) {
      watchdog.start();
      async.elapse(const Duration(minutes: 5));
      expect(told, 1);

      watchdog.heard();
      async.elapse(quiet);
      expect(told, 2);
    });
  });

  test('a stopped watch tells nothing and is not restarted by what is heard', () {
    fakeAsync((async) {
      watchdog.start();
      watchdog.stop();
      watchdog.heard();
      async.elapse(const Duration(minutes: 5));

      expect(told, 0);
    });
  });

  test('what is heard before the watch starts does not start it', () {
    fakeAsync((async) {
      watchdog.heard();
      async.elapse(const Duration(minutes: 5));

      expect(told, 0);
    });
  });
}
