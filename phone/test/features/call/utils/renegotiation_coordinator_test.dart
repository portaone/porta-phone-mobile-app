import 'dart:async';
import 'dart:math';

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

  group('pull resume', () {
    test('sends one command after the settling time, debounced by server offers', () {
      fakeAsync((async) {
        final commands = <RenegotiationCommand>[];
        final coordinator = RenegotiationCoordinator(onCommand: commands.add);

        coordinator.pullAccepted('a');
        async.elapse(const Duration(milliseconds: 1000));
        coordinator.pullServerOfferAnswered('a');
        async.elapse(const Duration(milliseconds: 1000));
        expect(commands, isEmpty);

        async.elapse(const Duration(milliseconds: 500));
        expect(commands.single, isA<ResumePulledCall>().having((command) => command.callId, 'callId', 'a'));
      });
    });

    test('a server offer that has arrived holds the resume back until it is answered', () {
      fakeAsync((async) {
        final commands = <RenegotiationCommand>[];
        final coordinator = RenegotiationCoordinator(onCommand: commands.add);

        coordinator.pullAccepted('a');
        async.elapse(const Duration(seconds: 1));
        coordinator.pullServerOfferReceived('a');
        async.elapse(const Duration(seconds: 5));
        coordinator.pullResumeDeferred('a');
        async.elapse(const Duration(seconds: 5));
        expect(commands, isEmpty);

        coordinator.pullServerOfferAnswered('a');
        async.elapse(const Duration(milliseconds: 2500));
        expect(commands.single, isA<ResumePulledCall>());
      });
    });

    test('a resume command already handed out is stale once a server offer arrives', () {
      fakeAsync((async) {
        final commands = <RenegotiationCommand>[];
        final coordinator = RenegotiationCoordinator(onCommand: commands.add);

        coordinator.pullAccepted('a');
        async.elapse(const Duration(seconds: 3));
        final command = commands.single as ResumePulledCall;
        coordinator.pullServerOfferReceived('a');

        expect(coordinator.isPullResumeCurrent('a', command.attempt), isFalse);
      });
    });

    test('a server offer left unanswered lets the resume go on', () {
      fakeAsync((async) {
        final commands = <RenegotiationCommand>[];
        final coordinator = RenegotiationCoordinator(onCommand: commands.add);

        coordinator.pullAccepted('a');
        coordinator.pullServerOfferReceived('a');
        coordinator.pullServerOfferReceived('a');
        coordinator.pullServerOfferAnswered('a');
        async.elapse(const Duration(seconds: 5));
        expect(commands, isEmpty);

        coordinator.pullServerOfferLeft('a');
        async.elapse(const Duration(milliseconds: 2500));
        expect(commands.single, isA<ResumePulledCall>());
      });
    });

    test('a later accept of the same call does not arm it again', () {
      fakeAsync((async) {
        final commands = <RenegotiationCommand>[];
        final coordinator = RenegotiationCoordinator(onCommand: commands.add);

        coordinator.pullAccepted('a');
        async.elapse(const Duration(seconds: 2));
        final command = commands.single as ResumePulledCall;
        coordinator.pullResumeSent('a', command.attempt);
        coordinator.pullAccepted('a');
        async.elapse(const Duration(seconds: 5));

        expect(commands, hasLength(1));
      });
    });

    test('a newer arming makes the earlier command stale', () {
      fakeAsync((async) {
        final commands = <RenegotiationCommand>[];
        final coordinator = RenegotiationCoordinator(onCommand: commands.add);

        coordinator.pullAccepted('a');
        async.elapse(const Duration(seconds: 2));
        final first = commands.single as ResumePulledCall;
        coordinator.pullResumeDeferred('a');

        expect(coordinator.isPullResumeCurrent('a', first.attempt), isFalse);
        async.elapse(const Duration(seconds: 2));
        expect(coordinator.isPullResumeCurrent('a', (commands.last as ResumePulledCall).attempt), isTrue);
      });
    });

    test('a 491 is retried after 2.1-4 s, other refusals end the resume', () {
      fakeAsync((async) {
        final commands = <RenegotiationCommand>[];
        final coordinator = RenegotiationCoordinator(onCommand: commands.add, random: Random(7));

        coordinator.pullAccepted('a');
        async.elapse(const Duration(seconds: 2));
        coordinator.pullResumeSent('a', (commands.last as ResumePulledCall).attempt);
        coordinator.pullResumeRejected('a', 491);
        async.elapse(const Duration(milliseconds: 2099));
        expect(commands, hasLength(1));
        async.elapse(const Duration(milliseconds: 1901));
        expect(commands, hasLength(2));

        coordinator.pullResumeSent('a', (commands.last as ResumePulledCall).attempt);
        coordinator.pullResumeRejected('a', 488);
        coordinator.pullServerOfferAnswered('a');
        async.elapse(const Duration(seconds: 10));
        expect(commands, hasLength(2));
      });
    });

    test('stops arming after the bound of resumes', () {
      fakeAsync((async) {
        final commands = <RenegotiationCommand>[];
        final coordinator = RenegotiationCoordinator(onCommand: commands.add, maxPullResumes: 2);

        coordinator.pullAccepted('a');
        for (var i = 0; i < 4; i++) {
          async.elapse(const Duration(seconds: 5));
          final last = commands.lastOrNull;
          if (last is ResumePulledCall && coordinator.isPullResumeCurrent('a', last.attempt)) {
            coordinator.pullResumeSent('a', last.attempt);
          }
          coordinator.pullServerOfferAnswered('a');
        }

        expect(commands, hasLength(2));
      });
    });

    test('server offers no longer arm it once the window after the pull has passed', () {
      fakeAsync((async) {
        final commands = <RenegotiationCommand>[];
        final coordinator = RenegotiationCoordinator(onCommand: commands.add);

        coordinator.pullAccepted('a');
        async.elapse(const Duration(seconds: 2));
        coordinator.pullResumeSent('a', (commands.last as ResumePulledCall).attempt);
        async.elapse(const Duration(seconds: 30));
        coordinator.pullServerOfferAnswered('a');
        async.elapse(const Duration(seconds: 5));

        expect(commands, hasLength(1));
      });
    });

    test('a resume armed near the end of the window still goes out', () {
      fakeAsync((async) {
        final commands = <RenegotiationCommand>[];
        final coordinator = RenegotiationCoordinator(onCommand: commands.add);

        coordinator.pullAccepted('a');
        async.elapse(const Duration(seconds: 2));
        coordinator.pullResumeSent('a', (commands.last as ResumePulledCall).attempt);
        async.elapse(const Duration(seconds: 27));
        coordinator.pullServerOfferAnswered('a');
        async.elapse(const Duration(seconds: 2));

        expect(commands, hasLength(2));
        expect(coordinator.isPullResumeCurrent('a', (commands.last as ResumePulledCall).attempt), isTrue);
      });
    });

    test('a server offer that holds the call puts the resume off until a sendrecv one', () {
      fakeAsync((async) {
        final commands = <RenegotiationCommand>[];
        final coordinator = RenegotiationCoordinator(onCommand: commands.add);

        coordinator.pullAccepted('a');
        coordinator.pullServerOfferAnswered('a', sendRecv: false);
        async.elapse(const Duration(seconds: 5));
        expect(commands, isEmpty);

        coordinator.pullServerOfferAnswered('a');
        async.elapse(const Duration(seconds: 2));
        expect(commands.single, isA<ResumePulledCall>());
      });
    });

    test('the resume ends after the bound of deferrals', () {
      fakeAsync((async) {
        final commands = <RenegotiationCommand>[];
        final coordinator = RenegotiationCoordinator(onCommand: commands.add, maxPullResumeDeferrals: 2);

        coordinator.pullAccepted('a');
        for (var i = 0; i < 3; i++) {
          async.elapse(const Duration(seconds: 2));
          coordinator.pullResumeDeferred('a');
        }
        async.elapse(const Duration(seconds: 5));

        expect(commands, hasLength(3));
        expect(coordinator.isPullResumeCurrent('a', (commands.last as ResumePulledCall).attempt), isFalse);
      });
    });

    test('an offer left without a reply is tried again within the bound of resumes', () {
      fakeAsync((async) {
        final commands = <RenegotiationCommand>[];
        final coordinator = RenegotiationCoordinator(onCommand: commands.add, maxPullResumes: 2);

        coordinator.pullAccepted('a');
        for (var i = 0; i < 3; i++) {
          async.elapse(const Duration(seconds: 2));
          final last = commands.last as ResumePulledCall;
          if (coordinator.isPullResumeCurrent('a', last.attempt)) coordinator.pullResumeSent('a', last.attempt);
          coordinator.pullResumeInterrupted('a');
        }

        expect(commands, hasLength(2));
      });
    });

    test('a hold cancels the armed resume', () {
      fakeAsync((async) {
        final commands = <RenegotiationCommand>[];
        final coordinator = RenegotiationCoordinator(onCommand: commands.add);

        coordinator.pullAccepted('a');
        coordinator.cancelPullResume('a');
        coordinator.pullServerOfferAnswered('a');
        async.elapse(const Duration(seconds: 5));

        expect(commands, isEmpty);
      });
    });

    test('ending the call completes the wait for its resume answer and cancels it', () {
      fakeAsync((async) {
        final commands = <RenegotiationCommand>[];
        final coordinator = RenegotiationCoordinator(onCommand: commands.add);
        var ending = false;

        coordinator.pullAccepted('a');
        coordinator.pullCallEnding('a').then((_) => ending = true);
        coordinator.callEnding('a');
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 5));

        expect(ending, isTrue);
        expect(commands, isEmpty);
      });
    });

    test('removal and dispose cancel the resume and release its waits', () {
      fakeAsync((async) {
        final commands = <RenegotiationCommand>[];
        final coordinator = RenegotiationCoordinator(onCommand: commands.add);
        final released = <String>[];

        coordinator.pullAccepted('a');
        coordinator.pullAccepted('b');
        coordinator.pullCallEnding('a').then((_) => released.add('a'));
        coordinator.pullCallEnding('b').then((_) => released.add('b'));
        coordinator.callRemoved('a');
        coordinator.dispose();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 5));

        expect(released, ['a', 'b']);
        expect(commands, isEmpty);
      });
    });
  });
}
