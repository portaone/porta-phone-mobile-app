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

  test('a reconnect renegotiates every connected call from its handshake, once', () {
    final commands = <RenegotiationCommand>[];
    final coordinator = RenegotiationCoordinator(onCommand: commands.add);

    coordinator.signalingConnected(['a', 'b']);
    expect(commands, isEmpty, reason: 'nothing goes out before the handshake');

    final fromHandshake = coordinator.handshakeReceived([
      (callId: 'a', lineId: 1),
      (callId: 'b', lineId: 2),
    ], connection: coordinator.connection).toList();

    expect(fromHandshake, hasLength(2));
    expect(fromHandshake[0], isA<Renegotiate>().having((command) => command.callId, 'callId', 'a'));
    expect(fromHandshake[1], isA<Renegotiate>().having((command) => command.lineId, 'lineId', 2));
    expect(
      coordinator.handshakeReceived([(callId: 'a', lineId: 1)], connection: coordinator.connection),
      isEmpty,
      reason: 'a second handshake of the same connection owes nothing',
    );
  });

  test('a handshake without a reconnect, or for a call not owed, renegotiates nothing', () {
    final coordinator = RenegotiationCoordinator(onCommand: (_) {});

    expect(coordinator.handshakeReceived([(callId: 'a', lineId: 1)], connection: coordinator.connection), isEmpty);

    coordinator.signalingConnected(['a']);
    expect(coordinator.handshakeReceived([(callId: 'b', lineId: 2)], connection: coordinator.connection), isEmpty);
    expect(
      coordinator.handshakeReceived([(callId: 'a', lineId: 1)], connection: coordinator.connection),
      isEmpty,
      reason: 'what was owed went',
    );
  });

  test('a handshake of an earlier connection leaves what is owed to the current one', () {
    final coordinator = RenegotiationCoordinator(onCommand: (_) {});

    coordinator.signalingConnected(['a']);
    final first = coordinator.connection;
    coordinator.signalingConnected(['a']);

    expect(coordinator.handshakeReceived([(callId: 'a', lineId: 1)], connection: first), isEmpty);
    expect(coordinator.handshakeReceived([(callId: 'a', lineId: 1)], connection: coordinator.connection), hasLength(1));
  });

  group('server offers', () {
    test('a renegotiation goes at once while the call has no server offer', () {
      final coordinator = RenegotiationCoordinator(onCommand: (_) {});

      expect(coordinator.holdRenegotiation('a', 1), isFalse);
    });

    test('a renegotiation is put off behind a server offer and made once it is answered', () {
      final commands = <RenegotiationCommand>[];
      final coordinator = RenegotiationCoordinator(onCommand: commands.add);

      coordinator.serverOfferReceived('a');
      expect(coordinator.holdRenegotiation('a', 3), isTrue);
      expect(commands, isEmpty);

      coordinator.serverOfferAnswered('a');

      expect(
        commands.single,
        isA<Renegotiate>().having((c) => c.callId, 'callId', 'a').having((c) => c.lineId, 'lineId', 3),
      );
      expect(coordinator.hasServerOffer('a'), isFalse);
    });

    test('a server offer left unanswered lets the renegotiation go too', () {
      final commands = <RenegotiationCommand>[];
      final coordinator = RenegotiationCoordinator(onCommand: commands.add);

      coordinator.serverOfferReceived('a');
      coordinator.holdRenegotiation('a', 1);
      coordinator.serverOfferLeft('a');

      expect(commands.single, isA<Renegotiate>());
    });

    test('a server offer the server refused the answer to drops the renegotiation put off behind it', () {
      final commands = <RenegotiationCommand>[];
      final coordinator = RenegotiationCoordinator(onCommand: commands.add);

      coordinator.serverOfferReceived('a');
      coordinator.holdRenegotiation('a', 1);
      coordinator.serverOfferLeft('a', refused: true);

      expect(commands, isEmpty, reason: 'the refusal\'s own randomized retry renegotiates the call');
      expect(coordinator.hasServerOffer('a'), isFalse);
    });

    test('an offer needed only without an answer is dropped by the answer and made without one', () {
      final commands = <RenegotiationCommand>[];
      final coordinator = RenegotiationCoordinator(onCommand: commands.add);

      coordinator.serverOfferReceived('a');
      coordinator.offerUnlessServerOfferAnswered('a', 2);
      coordinator.serverOfferAnswered('a');
      expect(commands, isEmpty);

      coordinator.serverOfferReceived('a');
      coordinator.offerUnlessServerOfferAnswered('a', 2);
      coordinator.serverOfferLeft('a');
      expect(commands.single, isA<Renegotiate>().having((c) => c.lineId, 'lineId', 2));
    });

    test('a renegotiation asked for outright is not turned into one needed only without an answer', () {
      final commands = <RenegotiationCommand>[];
      final coordinator = RenegotiationCoordinator(onCommand: commands.add);

      coordinator.serverOfferReceived('a');
      coordinator.holdRenegotiation('a', 1);
      coordinator.offerUnlessServerOfferAnswered('a', 1);
      coordinator.serverOfferAnswered('a');

      expect(commands.single, isA<Renegotiate>());
    });

    test('the renegotiation waits for every open server offer of its call, and only of its call', () {
      final commands = <RenegotiationCommand>[];
      final coordinator = RenegotiationCoordinator(onCommand: commands.add);

      coordinator.serverOfferReceived('a');
      coordinator.serverOfferReceived('a');
      coordinator.serverOfferReceived('b');
      coordinator.holdRenegotiation('a', 1);

      coordinator.serverOfferAnswered('b');
      coordinator.serverOfferAnswered('a');
      expect(commands, isEmpty);

      coordinator.serverOfferAnswered('a');
      expect(commands.single.callId, 'a');
    });

    test('a renegotiation put off is dropped with its call', () {
      final commands = <RenegotiationCommand>[];
      final coordinator = RenegotiationCoordinator(onCommand: commands.add);

      coordinator.serverOfferReceived('a');
      coordinator.holdRenegotiation('a', 1);
      coordinator.callRemoved('a');
      coordinator.serverOfferAnswered('a');

      expect(commands, isEmpty);
      expect(coordinator.hasServerOffer('a'), isFalse);
    });
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
    coordinator.signalingConnected(['call']);
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
      coordinator.signalingConnected(['call']);
      expect(
        coordinator.handshakeReceived([(callId: 'call', lineId: 1)], connection: coordinator.connection),
        contains(isA<Renegotiate>()),
      );
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

      coordinator.signalingConnected(['call']);
      expect(
        coordinator.handshakeReceived([(callId: 'call', lineId: 1)], connection: coordinator.connection),
        contains(isA<Renegotiate>()),
      );
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
        coordinator.serverOfferAnswered('a');
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
        coordinator.serverOfferReceived('a');
        async.elapse(const Duration(seconds: 5));
        coordinator.pullResumeDeferred('a');
        async.elapse(const Duration(seconds: 5));
        expect(commands, isEmpty);

        coordinator.serverOfferAnswered('a');
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
        coordinator.serverOfferReceived('a');

        expect(coordinator.isPullResumeCurrent('a', command.attempt), isFalse);
      });
    });

    test('a server offer left unanswered lets the resume go on', () {
      fakeAsync((async) {
        final commands = <RenegotiationCommand>[];
        final coordinator = RenegotiationCoordinator(onCommand: commands.add);

        coordinator.pullAccepted('a');
        coordinator.serverOfferReceived('a');
        coordinator.serverOfferReceived('a');
        coordinator.serverOfferAnswered('a');
        async.elapse(const Duration(seconds: 5));
        expect(commands, isEmpty);

        coordinator.serverOfferLeft('a');
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
        coordinator.serverOfferAnswered('a');
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
          coordinator.serverOfferAnswered('a');
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
        coordinator.serverOfferAnswered('a');
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
        coordinator.serverOfferAnswered('a');
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
        coordinator.serverOfferAnswered('a', sendRecv: false);
        async.elapse(const Duration(seconds: 5));
        expect(commands, isEmpty);

        coordinator.serverOfferAnswered('a');
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
        coordinator.serverOfferAnswered('a');
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
