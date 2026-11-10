import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'call_bloc_harness.dart';

/// An update of the far end (a re-INVITE) is reported to callkeep with the
/// call's details. The proximity flag goes with it only as "on": on iOS "off"
/// is the VideoChat session mode, which routes to the loudspeaker, and sent on
/// every update it took a video call off the earpiece the user had chosen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CallBlocHarness h;

  setUp(() => h = CallBlocHarness());
  tearDown(() => h.close());

  UpdatingCallEvent update(String callId) => UpdatingCallEvent(
    line: 0,
    callId: callId,
    caller: '100',
    callee: '200',
    jsep: const {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'},
  );

  /// Feeds the update and lets the server take the answer, so the handler is done before
  /// the test looks.
  Future<void> answered(String callId) async {
    h.signaling.emit(update(callId));
    await h.settle(() => h.signaling.requests.whereType<UpdateRequest>().isNotEmpty);
    final answer = h.signaling.requests.whereType<UpdateRequest>().single;
    h.signaling.emit(UpdatedEvent(line: 0, callId: callId, transaction: answer.transaction));
    await pumpEventQueue();
  }

  test('an update of a video call reports no proximity change', () async {
    h.seedEstablishedCall('a', video: true);

    await answered('a');

    expect(h.callkeep.proximityUpdates, isEmpty);
  });

  test('an update of an audio call reports the sensor on', () async {
    h.seedEstablishedCall('a');

    await answered('a');

    expect(h.callkeep.proximityUpdates, [(callId: 'a', enabled: true)]);
  });
}
