import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:webtrit_phone/extensions/extensions.dart';

import '../features/call/bloc/call_bloc_harness.dart';

/// The connection's own video sender: the one carrying video, else the first empty sender of a
/// video transceiver that sends.
void main() {
  FakePeerConnection connection({bool remoteDescribed = true}) => FakePeerConnection(
    audioTrack: FakeMediaStreamTrack(kind: 'audio', id: 'mic'),
    remoteDescribed: remoteDescribed,
  );

  /// A video line whose track was taken off again.
  Future<RTCRtpSender> emptyVideoLine(FakePeerConnection peer) async {
    final sender = await peer.addTrack(FakeMediaStreamTrack(kind: 'video', id: 'gone'));
    await sender.replaceTrack(null);
    return sender;
  }

  test('a sender carrying video is the one', () async {
    final peer = connection();
    final camera = FakeMediaStreamTrack(kind: 'video', id: 'camera');
    final sender = await peer.addTrack(camera);

    expect(await peer.videoSender(), same(sender));
  });

  test('an empty sender of a video line that sends is found again', () async {
    final peer = connection();
    final sender = await emptyVideoLine(peer);

    expect(await peer.videoSender(), same(sender));
  });

  test('an empty video sender made before the first answer is told by its line in the offer', () async {
    final peer = connection(remoteDescribed: false);
    final sender = await emptyVideoLine(peer);
    peer.fakeTransceivers.first.mid = '0';
    peer.fakeTransceivers.last.mid = '1';
    await peer.setLocalDescription(
      RTCSessionDescription(
        'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\na=mid:0\r\nm=video 9 UDP/TLS/RTP/SAVPF 96\r\na=mid:1\r\n',
        'offer',
      ),
    );

    expect(await peer.videoSender(), same(sender));
  });

  test('an empty sender in no description and with no receiver track is not taken', () async {
    final peer = connection(remoteDescribed: false);
    await emptyVideoLine(peer);
    peer.fakeTransceivers.last.mid = '';

    expect(await peer.videoSender(), isNull);
  });

  test('an empty sender of an audio line is not a video one', () async {
    final peer = connection();
    await peer.fakeSenders.first.replaceTrack(null);

    expect(await peer.videoSender(), isNull);
  });

  for (final direction in [TransceiverDirection.RecvOnly, TransceiverDirection.Inactive]) {
    test('an empty video line that does not send ($direction) is left alone', () async {
      final peer = connection();
      await emptyVideoLine(peer);
      peer.fakeTransceivers.last.direction = direction;

      expect(await peer.videoSender(), isNull);
    });
  }

  test('a stopped video line is left alone', () async {
    final peer = connection();
    await emptyVideoLine(peer);
    peer.fakeTransceivers.last.stoped = true;

    expect(await peer.videoSender(), isNull);
  });

  test('the direction is read only of the lines that could be the one', () async {
    final peer = connection();
    final sender = await emptyVideoLine(peer);

    expect(await peer.videoSender(), same(sender));
    expect(peer.fakeTransceivers.first.directionReads, 0, reason: 'the audio line is not a candidate');
    expect(peer.fakeTransceivers.last.directionReads, 1);
  });
}
