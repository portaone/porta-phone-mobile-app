import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:webtrit_phone/features/call/utils/utils.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/peer_connection_settings/peer_connection_settings_repository.dart';

import '../bloc/call_bloc_harness.dart';

/// The far end asks for video in a call that has none of its own: the policy backs the offer's
/// video line with a camera track, turned off - on the call's video sender when the call has one,
/// even an empty one, and on a new line only when it has none.
void main() {
  late FakeUserMediaBuilder media;
  late ModifyWithSettingsPeerConnectionPolicyApplier applier;

  setUp(() {
    media = FakeUserMediaBuilder();
    applier = ModifyWithSettingsPeerConnectionPolicyApplier(_Settings(), PeerConnectionSettings.blank(), media);
  });

  FakePeerConnection connection() => FakePeerConnection(
    audioTrack: FakeMediaStreamTrack(kind: 'audio', id: 'mic'),
    remoteDescribed: true,
  );

  test('an audio call gets a video line backed by a camera turned off', () async {
    final peer = connection();
    final localStream = media.buildSync();

    await applier.apply(peer, hasRemoteVideo: true, localStream: localStream);

    expect(peer.addedTracks, hasLength(1));
    expect(peer.addedTracks.single.kind, 'video');
    expect(peer.addedTracks.single.enabled, isFalse);
  });

  test('the empty video sender a stopped screen share left takes the camera, no second line', () async {
    final peer = connection();
    // A screen share added this line to an audio call and, stopped, left it without a track.
    final screen = FakeMediaStreamTrack(kind: 'video', id: 'screen');
    final sender = await peer.addTrack(screen);
    await sender.replaceTrack(null);
    final localStream = media.buildSync();

    await applier.apply(peer, hasRemoteVideo: true, localStream: localStream);

    expect(peer.addedTracks, [screen], reason: 'no line is added beside the empty one');
    expect(sender.track?.kind, 'video');
    expect(sender.track?.enabled, isFalse);
    expect((sender as FakeRtpSender).streams, [localStream], reason: 'tied to the stream as addTrack ties it');
  });

  for (final (name, turn) in <(String, void Function(FakeRtpTransceiver))>[
    ('receive-only', (line) => line.direction = TransceiverDirection.RecvOnly),
    ('inactive', (line) => line.direction = TransceiverDirection.Inactive),
    ('stopped', (line) => line.stoped = true),
  ]) {
    test('an empty video line that is $name is not used: the camera gets a line of its own', () async {
      final peer = connection();
      final sender = await peer.addTrack(FakeMediaStreamTrack(kind: 'video', id: 'gone'));
      await sender.replaceTrack(null);
      turn(peer.fakeTransceivers.last);

      await applier.apply(peer, hasRemoteVideo: true, localStream: media.buildSync());

      expect(peer.addedTracks, hasLength(2));
      expect(sender.track, isNull);
    });
  }

  test('a call whose video sender carries a track is left as it is', () async {
    final peer = connection();
    final camera = FakeMediaStreamTrack(kind: 'video', id: 'camera');
    unawaited(peer.addTrack(camera));

    await applier.apply(peer, hasRemoteVideo: true, localStream: media.buildSync());

    expect(peer.addedTracks, [camera]);
    expect(media.camerasOpened, isEmpty);
  });
}

class _Settings implements PeerConnectionSettingsRepository {
  @override
  PeerConnectionSettings getPeerConnectionSettings({PeerConnectionSettings? defaultValue}) =>
      defaultValue ?? PeerConnectionSettings.blank();

  @override
  Future<void> setPearConnectionSettings(PeerConnectionSettings settings) async {}

  @override
  Future<void> clear() async {}
}
