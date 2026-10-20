import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/call/utils/utils.dart';

void main() {
  test('debounces ICE restart separately for each call', () {
    fakeAsync((async) {
      final commands = <RenegotiationCommand>[];
      final coordinator = RenegotiationCoordinator(onCommand: commands.add);

      coordinator.networkAvailable('a');
      async.elapse(const Duration(seconds: 1));
      coordinator.networkAvailable('a');
      coordinator.networkAvailable('b');
      async.elapse(const Duration(seconds: 1));
      expect(commands, isEmpty);

      async.elapse(const Duration(seconds: 1));
      expect(commands.map((command) => command.callId), ['a', 'b']);
    });
  });

  test('call removal cancels its pending ICE restart', () {
    fakeAsync((async) {
      final commands = <RenegotiationCommand>[];
      final coordinator = RenegotiationCoordinator(onCommand: commands.add);

      coordinator.networkAvailable('call');
      coordinator.callRemoved('call');
      async.elapse(const Duration(minutes: 1));

      expect(commands, isEmpty);
    });
  });

  test('signaling reconnect returns renegotiation for every connected call', () {
    final coordinator = RenegotiationCoordinator(onCommand: (_) {});

    final commands = coordinator.signalingConnected([(callId: 'a', lineId: 1), (callId: 'b', lineId: 2)]);

    expect(commands, hasLength(2));
    expect(commands[0], isA<Renegotiate>().having((command) => command.callId, 'callId', 'a'));
    expect(commands[1], isA<Renegotiate>().having((command) => command.callId, 'callId', 'b'));
  });

  test('updating retry waits and returns the same call', () async {
    final waits = <Duration>[];
    final coordinator = RenegotiationCoordinator(onCommand: (_) {}, delay: (duration) async => waits.add(duration));

    final command = await coordinator.retryAfterUpdating('call', 3);

    expect(waits, [const Duration(seconds: 1)]);
    expect(command, isA<Renegotiate>().having((command) => command.callId, 'callId', 'call'));
    expect((command as Renegotiate).lineId, 3);
  });

  test('dispose cancels pending ICE restarts', () {
    fakeAsync((async) {
      final commands = <RenegotiationCommand>[];
      final coordinator = RenegotiationCoordinator(onCommand: commands.add);

      coordinator.networkAvailable('call');
      coordinator.dispose();
      async.elapse(const Duration(minutes: 1));

      expect(commands, isEmpty);
    });
  });
}
