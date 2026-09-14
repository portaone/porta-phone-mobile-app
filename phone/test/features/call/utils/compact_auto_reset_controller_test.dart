import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/call/call.dart';

import '../../../mocks/mocks.dart';

void main() {
  group('CompactAutoResetController', () {
    late CompactAutoResetController controller;
    const int autoResetSeconds = 5;

    setUp(() {
      controller = CompactAutoResetController(autoResetSeconds: autoResetSeconds);
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial state is inactive and expanded (not compact)', () {
      expect(controller.active, isFalse);
      expect(controller.compact, isFalse);
      expect(controller.isRunning, isFalse);
    });

    test('Constructor throws assertion error if autoResetSeconds <= 0', () {
      expect(() => CompactAutoResetController(autoResetSeconds: 0), throwsA(isA<AssertionError>()));
    });

    test('activate() starts the timer and switches to compact after timeout', () {
      fakeAsync((async) {
        controller.activate();

        // Immediately active but still expanded
        expect(controller.active, isTrue);
        expect(controller.compact, isFalse);
        expect(controller.isRunning, isTrue);

        // Advance time partially (2s)
        async.elapse(const Duration(seconds: 2));
        expect(controller.compact, isFalse);

        // Advance time past limit (Total 5s)
        async.elapse(const Duration(seconds: 3));
        expect(controller.compact, isTrue);

        // Timer should stop after compacting
        expect(controller.isRunning, isFalse);
      });
    });

    test('deactivate() stops the timer and resets state', () {
      fakeAsync((async) {
        controller.activate();
        async.elapse(const Duration(seconds: 2));

        controller.deactivate();

        expect(controller.active, isFalse);
        expect(controller.compact, isFalse);
        expect(controller.isRunning, isFalse);

        // Advance time past original timeout - nothing should happen
        async.elapse(const Duration(seconds: 10));
        expect(controller.compact, isFalse);
      });
    });

    group('setActive() edge cases', () {
      test('setActive(true) when already active is a no-op (does not restart timer)', () {
        fakeAsync((async) {
          controller.activate(); // Active = true, Timer started (5s)

          // Elapse 3 seconds
          async.elapse(const Duration(seconds: 3));
          expect(controller.compact, isFalse);

          // Call setActive(true) again
          controller.setActive(true);

          // If it restarted, we would need 5 more seconds.
          // If it didn't restart, we only need 2 more seconds.
          async.elapse(const Duration(seconds: 2));

          // Should be compact now (total 5s from start)
          expect(controller.compact, isTrue);
        });
      });

      test('setActive(false) when already inactive is a no-op', () {
        expect(controller.active, isFalse);

        controller.setActive(false);

        expect(controller.active, isFalse);
        expect(controller.isRunning, isFalse);
        expect(controller.compact, isFalse);
      });

      test('setActive(true) while timer is running continues the timer', () {
        fakeAsync((async) {
          controller.setActive(true);
          expect(controller.isRunning, isTrue);

          async.elapse(const Duration(seconds: 1));
          controller.setActive(true); // Should not disturb running timer

          async.elapse(const Duration(seconds: 4));
          expect(controller.compact, isTrue);
        });
      });
    });

    group('toggle()', () {
      test('toggle() manually switches state and manages timer when active', () {
        fakeAsync((async) {
          controller.activate();

          // Manually compact
          controller.toggle();
          expect(controller.compact, isTrue);
          expect(controller.isRunning, isFalse); // Timer shouldn't run when compact

          // Manually expand
          controller.toggle();
          expect(controller.compact, isFalse);
          expect(controller.isRunning, isTrue); // Timer should restart

          // Should compact again after timeout
          async.elapse(const Duration(seconds: 5));
          expect(controller.compact, isTrue);
        });
      });

      test('toggle() while inactive leaves the state expanded', () {
        // A compact state reached with no timer to undo it is one nothing
        // reverts, so an inactive controller refuses to compact at all.
        expect(controller.active, isFalse);
        var notified = 0;
        controller.addListener(() => notified++);

        controller.toggle();
        expect(controller.compact, isFalse);
        expect(controller.isRunning, isFalse);
        expect(notified, 0, reason: 'nothing changed, so nobody is told');
      });

      test('setCompact(true) while inactive is refused, deactivating expands', () {
        fakeAsync((async) {
          controller.setCompact(true, reason: 'test');
          expect(controller.compact, isFalse);

          controller.activate();
          async.elapse(const Duration(seconds: 5));
          expect(controller.compact, isTrue);

          // Inactive means expanded, whichever way it got there.
          controller.deactivate();
          expect(controller.compact, isFalse);
          controller.setCompact(true, reason: 'test');
          expect(controller.compact, isFalse);
        });
      });
    });
  });

  group('ActiveCallListAutoCompact Extension', () {
    test('A demand to keep the controls refuses the auto-hide whatever the call is', () {
      final List<ActiveCall> videoCall = [MockActiveCall(isCameraActive: true, remoteVideo: true)];

      expect(videoCall.shouldAutoHideControls(keepControlsVisible: false), isTrue);
      // Hidden controls drop out of the accessibility tree, so once they are
      // required to stay there is no hiding them.
      expect(videoCall.shouldAutoHideControls(keepControlsVisible: true), isFalse);

      final List<ActiveCall> audioCall = [MockActiveCall()];
      expect(audioCall.shouldAutoHideControls(keepControlsVisible: false), isFalse);
    });

    test('Returns false for empty list', () {
      final List<ActiveCall> calls = [];
      expect(calls.shouldAutoCompact, isFalse);
    });

    test('Returns TRUE only for CallProcessingStatus.connected on current call', () {
      // Loop through ALL statuses defined in the enum
      for (final status in CallProcessingStatus.values) {
        // Explicit type definition fixes "subtype of orElse" error
        final List<ActiveCall> calls = [
          MockActiveCall(processingStatus: status, isCameraActive: true, remoteVideo: true),
        ];

        if (status == CallProcessingStatus.connected) {
          expect(calls.shouldAutoCompact, isTrue, reason: 'Status $status should allow compact mode');
        } else {
          expect(calls.shouldAutoCompact, isFalse, reason: 'Status $status should NOT allow compact mode');
        }
      }
    });

    test('Returns false if current call was hung up', () {
      final List<ActiveCall> calls = [
        MockActiveCall(
          processingStatus: CallProcessingStatus.connected,
          wasHungUp: true,
          isCameraActive: true,
          remoteVideo: true,
        ),
      ];
      expect(calls.shouldAutoCompact, isFalse);
    });

    test('Returns true with remote video on a two-way video call', () {
      final List<ActiveCall> calls = [
        MockActiveCall(processingStatus: CallProcessingStatus.connected, isCameraActive: true, remoteVideo: true),
      ];
      expect(calls.shouldAutoCompact, isTrue);
    });

    test('The own camera does not matter: a one-way video call compacts too', () {
      // The controls get out of the way of the other person's picture, and
      // that picture is there whether or not the own camera is on. A far side
      // that announces video but sends black frames is not caught here - the
      // screen probes the frames and adds that condition on top.
      final List<ActiveCall> calls = [
        MockActiveCall(
          processingStatus: CallProcessingStatus.connected,
          isCameraActive: false, // Local OFF
          remoteVideo: true, // Remote ON
        ),
      ];
      expect(calls.shouldAutoCompact, isTrue);
    });

    test('Returns false if remote video is OFF', () {
      final List<ActiveCall> calls = [
        MockActiveCall(processingStatus: CallProcessingStatus.connected, isCameraActive: true, remoteVideo: false),
      ];
      expect(calls.shouldAutoCompact, isFalse);
    });

    test('Multi-call: Returns false if current call is Audio, even if background call is Video', () {
      final List<ActiveCall> calls = [
        // Background Call: Video (Held)
        MockActiveCall(
          processingStatus: CallProcessingStatus.connected,
          isCameraActive: true,
          remoteVideo: true,
          held: true,
        ),
        // Current Call: Audio (Active, Not Held)
        MockActiveCall(
          processingStatus: CallProcessingStatus.connected,
          isCameraActive: false,
          remoteVideo: false,
          held: false,
        ),
      ];
      // Logic: 'current' resolves to the Audio call. Audio call => No Compact.
      expect(calls.shouldAutoCompact, isFalse);
    });

    test('Multi-call: Returns true if current call is Video, regardless of background call', () {
      final List<ActiveCall> calls = [
        // Background Call: Audio (Held)
        MockActiveCall(
          processingStatus: CallProcessingStatus.connected,
          isCameraActive: false,
          remoteVideo: false,
          held: true,
        ),
        // Current Call: Video (Active, Not Held)
        MockActiveCall(
          processingStatus: CallProcessingStatus.connected,
          isCameraActive: true,
          remoteVideo: true,
          held: false,
        ),
      ];
      // Logic: 'current' resolves to the Video call. Video call => Compact.
      expect(calls.shouldAutoCompact, isTrue);
    });
  });
}
