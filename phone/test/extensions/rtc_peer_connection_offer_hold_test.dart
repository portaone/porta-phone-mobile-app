import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webtrit_phone/extensions/extensions.dart';

import '../features/call/bloc/call_bloc_harness.dart';

void main() {
  late FakePeerConnection peer;

  FakeRtpTransceiver microphone() => peer.fakeTransceivers.single;

  setUp(
    () => peer = FakePeerConnection(
      audioTrack: FakeMediaStreamTrack(kind: 'audio', id: 'mic'),
    ),
  );

  test('a call held by its offer has its microphone inactive', () async {
    expect(await peer.heldByOffer(), isFalse);

    await peer.holdByOffer();

    expect(microphone().direction, TransceiverDirection.Inactive);
    expect(await peer.heldByOffer(), isTrue);
  });

  test('a resume gives the microphone back once', () async {
    await peer.holdByOffer();

    expect(await peer.resumeFromOfferHold(), isTrue);
    expect(microphone().direction, TransceiverDirection.SendRecv);
    expect(await peer.resumeFromOfferHold(), isFalse, reason: 'nothing to give back any more');
  });

  test('a call not held by its offer is left as it is', () async {
    expect(await peer.resumeFromOfferHold(), isFalse);
    expect(microphone().directions, isEmpty);
  });

  test('a connection without a microphone has nothing to hold', () async {
    peer = FakePeerConnection();

    await peer.holdByOffer();

    expect(await peer.heldByOffer(), isFalse);
  });
}
