import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:webtrit_phone/features/call/call.dart';

import '../bloc/call_bloc_harness.dart';

/// The room's connection on its own: one peer connection per room, the microphone on
/// it, candidates in both directions, and nothing left behind on teardown.
final _offer = RTCSessionDescription('v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n', 'offer');
final _candidate = RTCIceCandidate('candidate:1 1 udp 1 10.0.0.1 5000 typ host', '0', 0);

/// The three intents a room is ever asked for. Which reason produced one -
/// the host's own mute, or the room standing aside - is [CallState.roomAudio]'s
/// business; the connection is told the outcome and nothing else.
const _carrying = CallAudio(microphone: true, audible: true);
const _muted = CallAudio(microphone: false, audible: true);
const _parked = CallAudio.silent();

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
    await connection.apply(_muted);
    await connection.answer(room: 1, offer: _offer);
    expect(factory.created.single.fakeSenders.single.track, isNull);
    // The microphone itself is every call's; the room mutes by letting go of
    // it, never by switching it off.
    expect(media.microphone.enabled, isTrue);

    await connection.answer(room: 2, offer: _offer);
    expect(factory.created.last.fakeSenders.single.track, isNull, reason: 'the new room starts muted too');

    await connection.apply(_carrying);
    expect(factory.created.last.fakeSenders.single.track, media.microphone);

    await connection.teardown();
    expect(media.microphone.enabled, isTrue);
    expect(connection.isUp, isFalse);
    expect(connection.room, isNull);
  });

  test('parking silences the room both ways and gives it back', () async {
    await connection.answer(room: 1, offer: _offer);
    final peer = factory.created.single;

    expect(peer.fakeSenders.single.track, media.microphone);
    expect(peer.fakeTransceivers.single.receiver.track!.enabled, isTrue);

    await connection.apply(_parked);
    expect(connection.isParked, isTrue);
    expect(peer.fakeSenders.single.track, isNull, reason: 'the room hears nothing of the host');
    expect(peer.fakeTransceivers.single.receiver.track!.enabled, isFalse, reason: 'and the host nothing of it');
    // What is parked is the channel, never the microphone: it is the call
    // outside the room that the host is talking into.
    expect(media.microphone.enabled, isTrue);

    await connection.apply(_carrying);
    expect(peer.fakeSenders.single.track, media.microphone);
    expect(peer.fakeTransceivers.single.receiver.track!.enabled, isTrue);
  });

  test('a room parked before its offer comes up silent', () async {
    // The receiver has no track until a remote description is set, so the
    // inbound half of the parking can only be applied once the offer has been
    // answered - the room is parked while it is still assembling whenever the
    // outside call started first.
    await connection.apply(_parked);
    await connection.answer(room: 1, offer: _offer);

    final peer = factory.created.single;
    expect(peer.fakeSenders.single.track, isNull);
    expect(peer.fakeTransceivers.single.receiver.track!.enabled, isFalse);
  });

  test('a muted room is still heard, a parked one is not', () async {
    // Two reasons, one intent: which of them silenced the sender is
    // [CallState.roomAudio]'s business, and the difference the connection
    // knows is that a mute closes one direction and parking closes both.
    await connection.answer(room: 1, offer: _offer);
    final peer = factory.created.single;

    await connection.apply(_muted);
    expect(peer.fakeSenders.single.track, isNull, reason: 'the room hears nothing of the host');
    expect(peer.fakeTransceivers.single.receiver.track!.enabled, isTrue, reason: 'a muted host still hears the room');

    await connection.apply(_parked);
    expect(peer.fakeTransceivers.single.receiver.track!.enabled, isFalse);

    await connection.apply(_carrying);
    expect(peer.fakeSenders.single.track, media.microphone);
    expect(peer.fakeTransceivers.single.receiver.track!.enabled, isTrue);
  });

  test('parking is kept across a rebuilt connection and forgotten with the room', () async {
    await connection.answer(room: 1, offer: _offer);
    await connection.apply(_parked);

    await connection.answer(room: 2, offer: _offer);
    expect(factory.created.last.fakeSenders.single.track, isNull, reason: 'the new room is parked too');
    expect(factory.created.last.fakeTransceivers.single.receiver.track!.enabled, isFalse);

    await connection.teardown();
    expect(connection.isParked, isFalse, reason: 'the next room is planned from the state, not from this one');
  });

  test('a park that cannot be applied at all gives the room up', () async {
    // Nothing here can be reached - not even the sender - so there is nothing
    // to half-do. What matters is that the intent stands: the next apply, from
    // a renegotiation or the next request, carries it out. (An earlier round
    // had this answer `false` so the owner would plan it again; that turned out
    // to drop transitions, because the owner plans while an apply is still in
    // flight. Reconciling is this object's own job now.)
    var lost = 0;
    final failing = _FailingTransceiverFactory();
    final connection = ConferencePeerConnection(
      factory: failing,
      userMediaBuilder: media,
      onLocalCandidate: gathered.add,
      onConnectionLost: () => lost++,
    );
    await connection.answer(room: 1, offer: _offer);
    failing.created.single.failTransceivers = true;

    await expectLater(connection.apply(_parked), throwsA(isA<StateError>()));

    expect(connection.isParked, isTrue);
    expect(lost, 1, reason: 'and the room is given up rather than left undescribable');
  });

  test('a park whose first attempt fails is finished by the retry', () async {
    // The host is on a call outside the room, which is why the park was asked
    // for. Nothing outside will come back to finish an apply that threw - the
    // owner plans against what this object says it is doing - so the second
    // attempt belongs here.
    final failing = _FailingTransceiverFactory();
    final connection = ConferencePeerConnection(
      factory: failing,
      userMediaBuilder: media,
      onLocalCandidate: gathered.add,
      onConnectionLost: () {},
    );
    await connection.answer(room: 1, offer: _offer);
    final peer = failing.created.single;
    // The sender is found, its track comes off, and the receiver lookup then
    // fails - once, the way a blip does.
    peer.failTransceiversAfter = 1;

    await connection.apply(_parked);

    expect(peer.fakeSenders.single.track, isNull);
    expect(peer.fakeTransceivers.single.receiver.track!.enabled, isFalse, reason: 'the retry finished the job');
    expect(connection.isParked, isTrue);
  });

  test('a park that keeps failing gives the room up', () async {
    // Both attempts gone. Nothing outside will come back to finish this - the
    // owner plans against what the room is to be, which is already this - so a
    // room left in a state nobody can describe would stay that way: possibly
    // with the host's microphone still in the mix. It is given up instead.
    var lost = 0;
    final failing = _FailingTransceiverFactory();
    final connection = ConferencePeerConnection(
      factory: failing,
      userMediaBuilder: media,
      onLocalCandidate: gathered.add,
      onConnectionLost: () => lost++,
    );
    await connection.answer(room: 1, offer: _offer);
    final peer = failing.created.single;
    peer.failTransceiversAfter = 1;
    peer.failAfterRetry = true;

    await expectLater(connection.apply(_parked), throwsA(isA<StateError>()));

    expect(lost, 1, reason: 'the owner is told to give the room up');
    expect(peer.fakeSenders.single.track, isNull, reason: 'and the room was never given the host back');
  });

  test('a retry does not put the microphone back on a room being torn down', () async {
    // The first attempt has taken the microphone off and is waiting on the
    // receiver when the user ends the conference. The teardown is queued behind
    // it, so the connection is still there - and the retry, if it did not look,
    // would apply what is wanted now (nothing parked) and hand the closing room
    // the microphone back.
    final failing = _FailingTransceiverFactory();
    final connection = ConferencePeerConnection(
      factory: failing,
      userMediaBuilder: media,
      onLocalCandidate: gathered.add,
      onConnectionLost: () {},
    );
    await connection.answer(room: 1, offer: _offer);
    final peer = failing.created.single;
    peer.failTransceiversAfter = 1;
    final held = Completer<void>();
    peer.holdFailure = held;

    final parking = connection.apply(_parked);
    await pumpEventQueue();
    expect(peer.fakeSenders.single.track, isNull, reason: 'the microphone is off before the lookup');

    final tearing = connection.teardown();
    held.complete();
    await parking.catchError((Object _) {});
    await tearing;

    expect(peer.fakeSenders.single.track, isNull, reason: 'the closing room never got it back');
    expect(connection.isUp, isFalse);
  });

  test('the last intent is what the room ends up with', () async {
    // Park, the outside call held (back to the room), then resumed (aside
    // again) - all recorded before the first one has run. What the connection
    // ends up doing is the last of them, because every apply reads what is
    // wanted at the time it runs rather than a value captured when it was asked
    // for. That capture is what used to let a late failure turn the park off.
    await connection.answer(room: 1, offer: _offer);
    final peer = factory.created.single;

    final first = connection.apply(_parked);
    final second = connection.apply(_carrying);
    final third = connection.apply(_parked);
    await Future.wait([first, second, third]);

    expect(peer.fakeSenders.single.track, isNull);
    expect(peer.fakeTransceivers.single.receiver.track!.enabled, isFalse);
    expect(connection.isParked, isTrue);
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

/// A connection whose transceivers can be made to fail, so a park can be
/// asked for on one that cannot take it.
class _FailingPeerConnection extends FakePeerConnection {
  _FailingPeerConnection() : super(remoteDescribed: false);

  bool failTransceivers = false;

  /// Lets this many lookups through, then fails the next one and only it.
  int? failTransceiversAfter;

  /// Keeps failing once [failTransceiversAfter] has fired, so a retry fails too.
  bool failAfterRetry = false;

  /// Held open before the failing lookup throws, so something else can happen
  /// while an apply is halfway through.
  Completer<void>? holdFailure;

  @override
  Future<List<RTCRtpTransceiver>> getTransceivers() async {
    if (failTransceivers) throw StateError('connection is gone');
    final after = failTransceiversAfter;
    if (after != null) {
      if (after > 0) {
        failTransceiversAfter = after - 1;
      } else {
        if (!failAfterRetry) failTransceiversAfter = null;
        await holdFailure?.future;
        throw StateError('transceivers went away');
      }
    }
    return super.getTransceivers();
  }
}

class _FailingTransceiverFactory implements PeerConnectionFactory {
  final List<_FailingPeerConnection> created = [];

  @override
  Future<RTCPeerConnection> create([
    Map<String, dynamic> configuration = const {},
    Map<String, dynamic> constraints = const {},
  ]) async {
    final peerConnection = _FailingPeerConnection();
    created.add(peerConnection);
    return peerConnection;
  }
}
