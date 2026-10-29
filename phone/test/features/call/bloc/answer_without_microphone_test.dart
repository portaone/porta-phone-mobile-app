import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';
import 'package:webtrit_phone/features/call/call.dart';

import 'call_bloc_harness.dart';

/// An incoming call answered while the system refuses the microphone cannot be
/// put through. It used to end without a word - the call screen closed and the
/// caller heard a decline - while an outgoing call in the same state says why.
class _RefusedMediaBuilder extends Fake implements UserMediaBuilder {
  @override
  Future<MediaStream> build({required bool video, bool? frontCamera, bool allowAudioFallback = false}) async =>
      throw UserMediaError('Unable to getUserMedia: NotAllowedError');
}

StateHandshake _incomingCall() {
  final buffer = SignalingEventBuffer();
  buffer.onEvent(
    SignalingHandshakeReceived(
      handshake: const StateHandshake(
        keepaliveInterval: Duration(seconds: 30),
        timestamp: 1,
        registration: Registration(status: RegistrationStatus.registered),
        lines: [null],
        presenceInfos: [],
        dialogInfos: [],
        guestLine: null,
      ),
    ),
  );
  buffer.onEvent(
    SignalingProtocolEvent(
      event: const IncomingCallEvent(
        line: 0,
        callId: 'incoming',
        caller: '100',
        callee: '200',
        jsep: {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 RTP/AVP 0\r\n'},
      ),
    ),
  );
  return buffer.snapshot.whereType<SignalingHandshakeReceived>().single.handshake;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an answer without the microphone tells the user why the call ended', () async {
    final h = CallBlocHarness(userMediaBuilder: _RefusedMediaBuilder());
    addTearDown(h.close);

    h.signaling.emitHandshake(_incomingCall());
    await pumpEventQueue();
    await h.bloc.performAnswerCall('incoming');
    await pumpEventQueue();

    expect(h.errors.errors, [isA<UserMediaError>()]);
    // The line is still cleaned up on the server, as before.
    expect(h.signaling.requests.whereType<DeclineRequest>().map((r) => r.callId), ['incoming']);
  });
}
