import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';

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

    final commands = coordinator.signalingConnected([(callId: 'a', lineId: 1), (callId: 'b', lineId: 2)]).toList();

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

  test('classifies only signaling transport and response-wait failures as transient', () {
    final coordinator = RenegotiationCoordinator(onCommand: (_) {});

    expect(coordinator.isTransientSignalingFailure(NotConnectedException('offline')), isTrue);
    expect(coordinator.isTransientSignalingFailure(const WebtritSignalingDisconnectedException(1)), isTrue);
    expect(coordinator.isTransientSignalingFailure(const WebtritSignalingTransactionTimeoutException(1, 'tx')), isTrue);
    expect(
      coordinator.isTransientSignalingFailure(
        const WebtritSignalingTransactionTerminateByDisconnectException(1, 'tx', 4502, 'timeout'),
      ),
      isTrue,
    );
    expect(coordinator.isTransientSignalingFailure(TimeoutException('response')), isTrue);
    expect(coordinator.isTransientSignalingFailure(StateError('bad SDP')), isFalse);
  });

  test('backs off the replays after the quick ones while signaling remains connected', () {
    fakeAsync((async) {
      final commands = <RenegotiationCommand>[];
      final delays = <Duration>[];
      final coordinator = RenegotiationCoordinator(
        onCommand: commands.add,
        createTimer: (duration, callback) {
          delays.add(duration);
          return Timer(duration, callback);
        },
      );
      final offer = RTCSessionDescription('v=0', 'offer');

      for (var attempt = 0; attempt < 7; attempt++) {
        coordinator.keepOffer('call', offer, signalingConnected: true);
        async.elapse(delays.last);
      }

      expect(delays, const [
        Duration(seconds: 2),
        Duration(seconds: 2),
        Duration(seconds: 4),
        Duration(seconds: 8),
        Duration(seconds: 16),
        Duration(seconds: 30),
        Duration(seconds: 30),
      ]);
      expect(commands, hasLength(7), reason: 'every failure is followed by another replay');
      expect(commands, everyElement(isA<Renegotiate>()));
      expect(coordinator.replayableOffer('call'), same(offer));
    });
  });

  test('a reconnect gives the kept offer its quick replays again', () {
    final delays = <Duration>[];
    final coordinator = RenegotiationCoordinator(
      onCommand: (_) {},
      createTimer: (duration, callback) {
        delays.add(duration);
        return Timer(duration, callback);
      },
    );
    final offer = RTCSessionDescription('v=0', 'offer');

    for (var attempt = 0; attempt < 4; attempt++) {
      coordinator.keepOffer('call', offer, signalingConnected: true);
    }
    coordinator.signalingConnected([(callId: 'call', lineId: 1)]);
    coordinator.keepOffer('call', offer, signalingConnected: true);
    coordinator.dispose();

    expect(delays.last, const Duration(seconds: 2));
  });

  test('takes the updating flag as stale after the bound of deferrals', () async {
    final coordinator = RenegotiationCoordinator(onCommand: (_) {}, delay: (_) async {});

    for (var deferral = 0; deferral < 9; deferral++) {
      await coordinator.retryAfterUpdating('call', 1);
    }
    expect(coordinator.isUpdatingStale('call'), isFalse);
    expect(coordinator.isUpdatingStale('other'), isFalse);

    await coordinator.retryAfterUpdating('call', 1);
    expect(coordinator.isUpdatingStale('call'), isTrue);
  });

  test('a settled update starts the count of deferrals again', () async {
    final coordinator = RenegotiationCoordinator(onCommand: (_) {}, delay: (_) async {}, maxUpdatingDeferrals: 2);

    await coordinator.retryAfterUpdating('call', 1);
    await coordinator.retryAfterUpdating('call', 1);
    expect(coordinator.isUpdatingStale('call'), isTrue);

    coordinator.updatingSettled('call');
    expect(coordinator.isUpdatingStale('call'), isFalse);

    await coordinator.retryAfterUpdating('call', 1);
    await coordinator.retryAfterUpdating('call', 1);
    coordinator.callRemoved('call');
    expect(coordinator.isUpdatingStale('call'), isFalse);
  });

  test('a disconnected failure waits for reconnect instead of arming a timer', () {
    fakeAsync((async) {
      final commands = <RenegotiationCommand>[];
      final coordinator = RenegotiationCoordinator(onCommand: commands.add);
      final offer = RTCSessionDescription('v=0', 'offer');

      coordinator.keepOffer('call', offer, signalingConnected: false);
      async.elapse(const Duration(minutes: 1));

      expect(coordinator.replayableOffer('call'), same(offer));
      expect(commands, isEmpty);
      expect(coordinator.signalingConnected([(callId: 'call', lineId: 1)]), contains(isA<Renegotiate>()));
    });
  });

  test('an offer waiting for its answer is replayable only after reconnect', () {
    fakeAsync((async) {
      final commands = <RenegotiationCommand>[];
      final coordinator = RenegotiationCoordinator(onCommand: commands.add);
      final offer = RTCSessionDescription('v=0', 'offer');

      coordinator.keepOffer('call', offer, signalingConnected: true);
      coordinator.awaitAnswer('call', offer);
      async.elapse(const Duration(minutes: 1));

      expect(coordinator.replayableOffer('call'), isNull);
      expect(coordinator.hasKeptOffer('call'), isTrue);
      expect(commands, isEmpty, reason: 'the replay timer of the earlier failure is cancelled');

      expect(coordinator.signalingConnected([(callId: 'call', lineId: 1)]), contains(isA<Renegotiate>()));
      expect(coordinator.replayableOffer('call'), same(offer));
    });
  });

  test('offer completion clears state and cancels its replay', () {
    fakeAsync((async) {
      final commands = <RenegotiationCommand>[];
      final coordinator = RenegotiationCoordinator(onCommand: commands.add);

      coordinator.keepOffer('call', RTCSessionDescription('v=0', 'offer'), signalingConnected: true);
      coordinator.offerCompleted('call');
      async.elapse(const Duration(minutes: 1));

      expect(coordinator.replayableOffer('call'), isNull);
      expect(coordinator.hasKeptOffer('call'), isFalse);
      expect(commands, isEmpty);
    });
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
