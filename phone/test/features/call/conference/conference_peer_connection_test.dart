import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:webtrit_phone/features/call/call.dart';

import '../bloc/call_bloc_harness.dart';

/// The room's connection on its own: one peer connection per room, the microphone on
/// it, candidates in both directions, and nothing left behind on teardown.
final _offer = RTCSessionDescription('v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n', 'offer');
final _candidate = RTCIceCandidate('candidate:1 1 udp 1 10.0.0.1 5000 typ host', '0', 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePeerConnectionFactory factory;
  late FakeUserMediaBuilder media;
  late List<RTCIceCandidate?> gathered;
  late int lost;
  late ConferencePeerConnection connection;

  setUp(() {
    CallBlocHarness.installPlatformStubs();
    factory = FakePeerConnectionFactory();
    media = FakeUserMediaBuilder();
    gathered = [];
    lost = 0;
    connection = ConferencePeerConnection(
      factory: factory,
      userMediaBuilder: media,
      onLocalCandidate: gathered.add,
      onConnectionLost: () => lost++,
    );
  });

  test('an answer opens one connection with the microphone on it', () async {
    final answer = await connection.answer(room: 1, offer: _offer);

    final peer = factory.created.single;
    expect(answer.type, 'answer');
    expect(peer.remoteDescriptions.single.type, 'offer');
    expect(peer.localDescriptions.single.type, 'answer');
    expect(peer.addedTracks.single.kind, 'audio');
    expect(media.built.single.getAudioTracks().single, peer.addedTracks.single);
    expect(connection.room, 1);
    expect(connection.isUp, isTrue);
  });

  test('a second offer for the same room renegotiates on the same connection', () async {
    await connection.answer(room: 1, offer: _offer);
    await connection.answer(room: 1, offer: _offer);

    expect(factory.created, hasLength(1));
    expect(factory.created.single.remoteDescriptions, hasLength(2));
  });

  test('an offer for another room replaces the connection', () async {
    await connection.answer(room: 1, offer: _offer);
    await connection.answer(room: 2, offer: _offer);

    expect(factory.created, hasLength(2));
    expect(factory.created.first.closes, 1);
    expect(media.released, [media.built.first]);
    expect(connection.room, 2);
  });

  test('a connection that failed is not reused for its room', () async {
    await connection.answer(room: 1, offer: _offer);
    factory.created.single.connectionState = RTCPeerConnectionState.RTCPeerConnectionStateFailed;
    await connection.answer(room: 1, offer: _offer);

    expect(factory.created, hasLength(2));
  });

  test('a candidate ahead of the offer waits for it', () async {
    await connection.addRemoteCandidate(_candidate);
    expect(factory.created, isEmpty);

    await connection.answer(room: 1, offer: _offer);
    await connection.addRemoteCandidate(_candidate);
    await connection.addRemoteCandidate(null);

    expect(factory.created.single.candidates, hasLength(2));
    expect(factory.created.single.candidates.first.candidate, _candidate.candidate);
  });

  test('gathered candidates and the end of gathering reach the owner', () async {
    await connection.answer(room: 1, offer: _offer);
    final peer = factory.created.single;

    peer.onIceCandidate!(RTCIceCandidate('candidate:2', '0', 0));
    peer.onIceGatheringState!(RTCIceGatheringState.RTCIceGatheringStateGathering);
    peer.onIceGatheringState!(RTCIceGatheringState.RTCIceGatheringStateComplete);

    expect(gathered.map((candidate) => candidate?.candidate), ['candidate:2', null]);
  });

  test('self mute takes the microphone off the room and is kept across a rebuilt connection', () async {
    await connection.setSelfMuted(true);
    await connection.answer(room: 1, offer: _offer);
    expect(factory.created.single.fakeSenders.single.track, isNull);
    // The microphone itself is every call's; the room mutes by letting go of
    // it, never by switching it off.
    expect(media.microphone.enabled, isTrue);

    await connection.answer(room: 2, offer: _offer);
    expect(factory.created.last.fakeSenders.single.track, isNull, reason: 'the new room starts muted too');

    await connection.setSelfMuted(false);
    expect(factory.created.last.fakeSenders.single.track, media.microphone);

    await connection.teardown();
    expect(media.microphone.enabled, isTrue);
    expect(connection.isUp, isFalse);
    expect(connection.room, isNull);
  });

  test('teardown closes the connection, returns the microphone and forgets the candidates', () async {
    await connection.answer(room: 1, offer: _offer);
    await connection.teardown();
    await connection.addRemoteCandidate(_candidate);
    await connection.answer(room: 1, offer: _offer);

    expect(factory.created.first.closes, 1);
    expect(media.released, [media.built.first]);
    expect(factory.created.last.candidates, hasLength(1), reason: 'only the candidate after the teardown');
  });

  test('a teardown while a room is being opened still leaves nothing up', () async {
    // Opening takes two awaits; a teardown arriving in between used to find
    // nothing to tear down and let the half-built connection finish, leaving
    // it open with the microphone never given back.
    final gate = Completer<void>();
    final gated = _GatedMediaBuilder(media, gate);
    final connection = ConferencePeerConnection(
      factory: factory,
      userMediaBuilder: gated,
      onLocalCandidate: gathered.add,
      onConnectionLost: () {},
    );

    final answering = connection.answer(room: 1, offer: _offer);
    await pumpEventQueue();
    final tearing = connection.teardown();
    gate.complete();
    await answering;
    await tearing;

    expect(connection.isUp, isFalse);
    expect(factory.created.single.closes, 1);
    expect(media.released, media.built, reason: 'the microphone went back');
    expect(media.microphoneLive, isFalse);
  });

  test('a failed connection to the mixer is reported once, and only while it is ours', () async {
    await connection.answer(room: 1, offer: _offer);
    final first = factory.created.single;
    final failed = first.onConnectionState!;

    failed(RTCPeerConnectionState.RTCPeerConnectionStateConnected);
    expect(lost, 0);
    first.connectionState = RTCPeerConnectionState.RTCPeerConnectionStateFailed;
    failed(RTCPeerConnectionState.RTCPeerConnectionStateFailed);
    expect(lost, 1);
    // A spent connection must not pass for a live one.
    expect(connection.isUp, isFalse);

    await connection.teardown();
    failed(RTCPeerConnectionState.RTCPeerConnectionStateFailed);
    expect(lost, 1, reason: 'the room it belonged to is gone');
  });

  test('a candidate from a connection that is gone is never passed on', () async {
    await connection.answer(room: 1, offer: _offer);
    // Held from before the teardown, the way a callback already on its way
    // holds it; the handler is cleared but that one call cannot be recalled.
    final gathering = factory.created.single.onIceCandidate!;
    final complete = factory.created.single.onIceGatheringState!;
    await connection.teardown();
    gathered.clear();

    gathering(RTCIceCandidate('candidate:stale', '0', 0));
    complete(RTCIceGatheringState.RTCIceGatheringStateComplete);

    expect(gathered, isEmpty, reason: 'a dead room must not trickle into the next one');
  });

  test('a microphone that cannot be opened leaves no connection behind', () async {
    final failing = _FailingMediaBuilder();
    final connection = ConferencePeerConnection(
      factory: factory,
      userMediaBuilder: failing,
      onLocalCandidate: gathered.add,
      onConnectionLost: () {},
    );

    await expectLater(connection.answer(room: 1, offer: _offer), throwsA(isA<UserMediaError>()));

    expect(factory.created.single.closes, 1);
    expect(connection.isUp, isFalse);
  });
}

/// Parks the microphone request until the test lets it go, so a teardown can
/// be made to land inside an opening room.
class _GatedMediaBuilder extends Fake implements UserMediaBuilder {
  _GatedMediaBuilder(this._inner, this._gate);

  final FakeUserMediaBuilder _inner;
  final Completer<void> _gate;

  @override
  Future<MediaStream> build({required bool video, bool? frontCamera, bool allowAudioFallback = false}) async {
    await _gate.future;
    return _inner.build(video: video, frontCamera: frontCamera, allowAudioFallback: allowAudioFallback);
  }

  @override
  Future<void> release(MediaStream stream) => _inner.release(stream);
}

class _FailingMediaBuilder extends Fake implements UserMediaBuilder {
  @override
  Future<MediaStream> build({required bool video, bool? frontCamera, bool allowAudioFallback = false}) async {
    throw UserMediaError('no microphone');
  }
}
