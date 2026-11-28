import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/models/models.dart';

import 'call_bloc_harness.dart';

/// The message shown when the server ends a call with an error response. A 403 from the switch
/// refuses one call (a destination outside the tariff, no funds, a blocked number) without saying
/// which; the account itself may still call other numbers, so the message must not send the user
/// to check the account.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a 403 hangup shows the neutral unable-to-complete message', () async {
    final h = CallBlocHarness();
    addTearDown(h.close);

    h.signaling.emit(const HangupEvent(line: 0, callId: 'call', code: 403, reason: 'Auth Failed'));
    await pumpEventQueue();

    expect(h.notifications, [isA<CallUnableToCompleteNotification>()]);
  });

  test('a busy hangup keeps its own message', () async {
    final h = CallBlocHarness();
    addTearDown(h.close);

    h.signaling.emit(const HangupEvent(line: 0, callId: 'call', code: 486, reason: 'Busy Here'));
    await pumpEventQueue();

    expect(h.notifications, [isA<CallBusyNotification>()]);
  });
}
