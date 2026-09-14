import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'helpers/callkeep_test_helpers.dart';

/// Probe for the A5 spike: can this device hold two self-managed calls at once?
///
/// The existing two-call scenario reports the second call immediately after the answer
/// callback for the first, and on a Pixel 9 running Android 17 Telecom rejects it with
/// MAX_RINGING_CALLS. Its own state machine had not finished moving the first call out of
/// RINGING - it did so 136 ms after the plugin's connection reported itself active - so the
/// second call is submitted while the first still counts as ringing.
///
/// This separates the two explanations. The same scenario, with a settle delay between the
/// answer and the second call, either produces two connections (the limit is on ringing calls
/// and the older test simply raced it) or fails the same way (the device really does allow one
/// call at a time).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Callkeep callkeep;
  late RecordingDelegate delegate;

  setUp(() async {
    callkeep = Callkeep();
    delegate = RecordingDelegate();
    await callkeep.setUp(kTestOptions);
    callkeep.setDelegate(delegate);
  });

  tearDown(() async {
    callkeep.setDelegate(null);
    try {
      await callkeep.tearDown().timeout(const Duration(seconds: 15));
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 300));
  });

  testWidgets('a second call is accepted once the first has settled into active', (WidgetTester _) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      markTestSkipped('Android only');
      return;
    }
    final id1 = nextTestId();
    final id2 = nextTestId();

    await callkeep.reportNewIncomingCall(id1, kTestHandle1, displayName: 'First');

    final answerLatch = Completer<void>();
    delegate.onPerformAnswerCall = (cid) {
      if (cid == id1 && !answerLatch.isCompleted) answerLatch.complete();
    };
    await callkeep.answerCall(id1);
    await waitFor(answerLatch.future, label: 'performAnswerCall id1');

    // The whole point of the probe. Telecom needs longer than the plugin does to leave
    // RINGING, and nothing the plugin exposes reports Telecom's own view of that.
    await Future.delayed(const Duration(seconds: 2));

    await callkeep.reportNewIncomingCall(id2, kTestHandle2, displayName: 'Second');
    final conn2 = await waitForConnection(id2);

    expect(conn2, isNotNull, reason: 'Telecom refused a second self-managed call even after the first had settled');
  });

  testWidgets('two answered calls can be grouped into a Telecom conference', (WidgetTester _) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      markTestSkipped('Android only');
      return;
    }
    final id1 = nextTestId();
    final id2 = nextTestId();

    Future<void> reportAndAnswer(String id, CallkeepHandle handle, String name) async {
      await callkeep.reportNewIncomingCall(id, handle, displayName: name);
      final latch = Completer<void>();
      delegate.onPerformAnswerCall = (cid) {
        if (cid == id && !latch.isCompleted) latch.complete();
      };
      await callkeep.answerCall(id);
      await waitFor(latch.future, label: 'performAnswerCall $id');
      // Telecom leaves RINGING later than the plugin's own connection does, and a call still
      // counted as ringing blocks the next one.
      await Future.delayed(const Duration(seconds: 2));
    }

    await reportAndAnswer(id1, kTestHandle1, 'First');
    await reportAndAnswer(id2, kTestHandle2, 'Second');

    final error = await callkeep.setCallGroup('room', [id1, id2]);
    expect(error, isNull, reason: 'the Telecom backend refused to group the calls');
    await Future.delayed(const Duration(seconds: 2));

    // Nothing is asked of the calls from here. Grouping itself puts every child active, the
    // way a telephony conference does, and the question is only whether Telecom leaves them
    // that way.

    // Held open so the states can be read from dumpsys while the group is up.
    await Future.delayed(const Duration(seconds: 25));
  });
}
