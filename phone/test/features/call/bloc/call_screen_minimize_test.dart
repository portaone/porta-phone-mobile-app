import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:webtrit_phone/features/call/call.dart';

import 'call_bloc_harness.dart';

/// Leaving the call screen only changes how the call is shown. The proximity
/// sensor is not turned off for it: on iOS that is done by a session mode that
/// also moves the call to the loudspeaker, which put a private call on the
/// speaker the moment the user pressed back.
void main() {
  late CallBlocHarness h;

  setUp(() => h = CallBlocHarness());
  tearDown(() => h.close());

  test('leaving the call screen reports no proximity change', () async {
    h.seedEstablishedCall('a');

    h.bloc.add(const CallScreenEvent.didPop());
    await pumpEventQueue();

    expect(h.bloc.state.minimized, isTrue);
    expect(h.callkeep.proximityUpdates, isEmpty);
  });

  // The one report that stays: an incoming call gets its proximity flag from the screen
  // opening, so the value is repeated for a call that already has it.
  test('coming back to the call screen reports the sensor on, never off', () async {
    h.seedEstablishedCall('a');

    h.bloc.add(const CallScreenEvent.didPop());
    h.bloc.add(const CallScreenEvent.didPush());
    await pumpEventQueue();

    expect(h.bloc.state.minimized, isFalse);
    expect(h.callkeep.proximityUpdates, [(callId: 'a', enabled: true)]);
  });

  test('starting a blind transfer minimizes and reports no proximity change', () async {
    h.seedEstablishedCall('a');

    h.bloc.add(const CallControlEvent.blindTransferInitiated('a'));
    await pumpEventQueue();

    expect(h.bloc.state.minimized, isTrue);
    expect(h.callkeep.proximityUpdates, isEmpty);
  });

  test('starting an attended transfer minimizes and reports no proximity change', () async {
    h.seedEstablishedCall('a');

    h.bloc.add(const CallControlEvent.attendedTransferInitiated('a'));
    await pumpEventQueue();

    expect(h.bloc.state.minimized, isTrue);
    expect(h.callkeep.proximityUpdates, isEmpty);
  });

  test('submitting a blind transfer reports no proximity change', () async {
    h.seedEstablishedCall('a');

    h.bloc.add(const CallControlEvent.blindTransferInitiated('a'));
    await pumpEventQueue();
    h.bloc.add(const CallControlEvent.blindTransferSubmitted(number: '200'));
    await pumpEventQueue();

    expect(h.signaling.requests.whereType<TransferRequest>(), hasLength(1));
    expect(h.bloc.state.minimized, isFalse);
    expect(h.callkeep.proximityUpdates, isEmpty);
  });
}
