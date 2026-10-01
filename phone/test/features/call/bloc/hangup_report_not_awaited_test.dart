import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'call_bloc_harness.dart';

/// A hangup for a call the bloc never held is reported to callkeep and nothing else is done
/// with it. The report crosses to the platform through a queue a cold start keeps busy for
/// seconds, and the mutation handlers run one after another: the handler must not hold the
/// queue for the report, or the next hangup waits with it.
HangupEvent _hangup(String callId) => HangupEvent(line: 0, callId: callId, code: 487, reason: 'Request Terminated');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a second unknown call hung up while the first report is in flight is reported at once', () async {
    final h = CallBlocHarness();
    addTearDown(h.close);
    h.callkeep.endReportGate = Completer();

    h.signaling.emit(_hangup('first'));
    h.signaling.emit(_hangup('second'));
    await pumpEventQueue();

    expect(h.callkeep.ended, ['first', 'second'], reason: 'the second report does not wait for the first');

    h.callkeep.endReportGate!.complete();
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls, isEmpty);
  });

  test('a report the platform refuses is logged and the bloc goes on', () async {
    final h = CallBlocHarness();
    addTearDown(h.close);
    h.callkeep.endReportError = StateError('channel gone');

    h.signaling.emit(_hangup('first'));
    await pumpEventQueue();

    h.callkeep.endReportError = null;
    h.signaling.emit(_hangup('second'));
    await pumpEventQueue();

    expect(h.callkeep.ended, ['first', 'second']);
    expect(h.bloc.state.activeCalls, isEmpty);
  });
}
