import 'package:flutter_test/flutter_test.dart';

import 'package:signaling/signaling.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/models/models.dart';

import 'call_bloc_harness.dart';

const _offer = {'type': 'offer', 'sdp': 'v=0\r\no=- 1 1 IN IP4 127.0.0.1\r\nm=audio 9 RTP/AVP 0\r\n'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final sendable in [true, false]) {
    test('a rejected incoming registration cannot be answered later (sendable=$sendable)', () async {
      final h = CallBlocHarness();
      addTearDown(h.close);
      // Android returns this same final error for Telecom refusal and its
      // registration deadline. The Dart caller cannot distinguish them.
      h.callkeep.incomingRegistrationError = CallkeepIncomingCallError.callRejectedBySystem;
      h.signaling.sendable = sendable;

      h.signaling.emit(const IncomingCallEvent(line: 0, callId: 'call', caller: '100', callee: '200', jsep: _offer));
      await pumpEventQueue();

      expect(h.bloc.state.activeCalls, isEmpty);
      if (sendable) {
        final decline = h.signaling.requests.whereType<DeclineRequest>().single;
        expect(decline.callId, 'call');
        expect(decline.line, 0);
      } else {
        final decline = h.terminationQueue.requests['call'];
        expect(decline?.type, QueuedTerminationRequestType.decline);
        expect(decline?.line, 0);
      }

      // A successful delegate acknowledgement does not mean this call was
      // answered: there is no ActiveCall left for the answer handler to use.
      await h.bloc.performAnswerCall('call');
      await pumpEventQueue();

      expect(h.bloc.state.activeCalls, isEmpty);
      expect(h.signaling.requests.whereType<AcceptRequest>(), isEmpty);
      expect(h.signaling.requests.whereType<DeclineRequest>(), hasLength(sendable ? 1 : 0));
      if (!sendable) expect(h.terminationQueue.requests.keys, ['call']);
    });
  }
}
