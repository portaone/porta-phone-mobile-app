import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/call/models/models.dart';
import 'package:webtrit_phone/features/call/utils/utils.dart';
import 'package:webtrit_phone/utils/utils.dart';

final _logger = Logger('ConferencePeerConnection');

/// Receives the candidates the room's peer connection gathers; `null` marks
/// the end of gathering.
typedef ConferenceCandidateSink = void Function(RTCIceCandidate? candidate);

/// Told when the room has to be given up: its audio could not be put where
/// it must be.
typedef ConferenceConnectionLost = void Function();

/// Told when the connection to the mixer failed. [hadConnected] says whether
/// it ever carried the room - a connection that did was working until its
/// network path went, which a new one can replace; one that never came up
/// says nothing of the kind.
typedef ConferenceConnectionFailed = void Function({required bool hadConnected});

/// The client's side of the conference room: one peer connection towards the
/// mixer, carrying the host's microphone up and the mixed room down.
///
/// The legs keep their own peer connections - the server takes their audio
/// from the SIP side - so this is one more connection next to them,
/// not a replacement. It knows nothing of signaling: the owner hands it the
/// mixer's offer and sends the answer it returns, and the candidates it
/// gathers go out through [onLocalCandidate].
///
/// The mixed audio plays natively as soon as the remote track arrives; no
/// renderer is involved, so the remote stream is not kept.
class ConferencePeerConnection {
  ConferencePeerConnection({
    required PeerConnectionFactory factory,
    required UserMediaBuilder userMediaBuilder,
    required this.onLocalCandidate,
    required this.onConnectionLost,
    required this.onConnectionFailed,
  }) : _factory = factory,
       _userMediaBuilder = userMediaBuilder;

  final PeerConnectionFactory _factory;
  final UserMediaBuilder _userMediaBuilder;
  final ConferenceCandidateSink onLocalCandidate;

  /// The room's audio could not be applied, so the room is over for this
  /// client; see [apply].
  final ConferenceConnectionLost onConnectionLost;

  /// The mixer connection failed. It cannot be restarted - the mixer made the
  /// offer and refuses one from the client - so the owner either asks the
  /// server for a new offer and calls [release], or gives the room up.
  final ConferenceConnectionFailed onConnectionFailed;

  RTCPeerConnection? _peerConnection;
  MediaStream? _microphone;

  /// Everything that touches the connection runs here, one at a time.
  ///
  /// Opening one takes two awaits - the factory and the microphone - and a
  /// teardown arriving in between would find nothing to tear down and then
  /// let the half-built connection finish, leaving it open with nobody
  /// holding it and the microphone never given back.
  final SerialQueue _operations = SerialQueue();
  int? _room;
  bool _remoteDescribed = false;

  /// Whether the current connection has ever reached the mixer.
  bool _hadConnected = false;

  /// What the room's audio is to be, from both of its reasons at once - the
  /// host's own mute and the room standing aside. Every apply reads it when it
  /// runs rather than a value captured when it was asked for, so a request
  /// that waited its turn cannot speak for a state nobody wants any more.
  CallAudio _wanted = const CallAudio(microphone: true, audible: true);

  /// Which apply is the current one, so a request overtaken by a later one -
  /// or by a teardown - stops instead of writing a state nobody wants.
  int _request = 0;

  /// How many times an apply is attempted before the room is given up.
  static const _attempts = 2;

  /// Candidates that arrived before the peer connection had a remote
  /// description to attach them to (the protocol allows that order).
  final List<RTCIceCandidate> _pendingCandidates = [];

  /// The room the current peer connection was built for; `null` without one.
  int? get room => _room;

  /// Whether there is a connection to the mixer that can still carry audio.
  /// A spent one looks connected and carries silence, so the state decides,
  /// not the presence of the object.
  bool get isUp {
    final peerConnection = _peerConnection;
    return peerConnection != null && _isUsable(peerConnection);
  }

  /// What the room's audio is to be, which is also what it will be: applying
  /// is this object's own business, retried here rather than planned again
  /// from outside.
  ///
  /// Deliberately not "what was last applied". The owner plans by comparing
  /// what it wants against this, and an apply is asked for without being waited
  /// on, so an answer of "not applied yet" would make a transition while one is
  /// in flight look like no transition at all - and the room would be left
  /// parked with nobody in the other call, or carrying while somebody is.
  CallAudio get audio => _wanted;

  /// Whether the room stands aside for a conversation outside it, which is the
  /// one of its two reasons the rest of the client acts on: a parked room is
  /// what a leg is told about and what the screen says the host is away from.
  bool get isParked => !_wanted.audible;

  /// Answers the mixer's [offer] for [room] and returns the local description
  /// to send back.
  ///
  /// Every offer gets a connection of its own, the same room's included: the
  /// mixer sends a second offer for a room only from a new handle of its own
  /// - after a rejoin - and an offer from another handle cannot be
  /// renegotiated onto the connection made with the one before. Such a
  /// connection would look connected and carry silence.
  Future<RTCSessionDescription> answer({required int room, required RTCSessionDescription offer}) {
    return _operations.run(() async {
      await _close();
      final peerConnection = await _open();
      _room = room;
      await peerConnection.setRemoteDescription(offer);
      _remoteDescribed = true;
      // Taken and cleared before the first await: the list is added to from
      // outside while these are being fed in.
      final pending = List.of(_pendingCandidates);
      _pendingCandidates.clear();
      for (final candidate in pending) {
        await peerConnection.addCandidate(candidate);
      }
      final answer = await peerConnection.createAnswer({});
      await peerConnection.setLocalDescription(answer);
      // Again here, and not only when the connection is opened: what the host
      // hears hangs on the receiver's track, and that exists only once a
      // remote description has been set. A room parked while it was still
      // assembling would otherwise come up audible.
      await _applyAudioState();
      return answer;
    });
  }

  /// Feeds a candidate from the mixer; `null` is the end of its gathering and
  /// needs nothing here. A candidate ahead of the offer waits for it.
  Future<void> addRemoteCandidate(RTCIceCandidate? candidate) {
    if (candidate == null) return Future<void>.value();
    return _operations.run(() async {
      final peerConnection = _peerConnection;
      if (peerConnection == null || !_remoteDescribed) {
        _pendingCandidates.add(candidate);
        return;
      }
      await peerConnection.addCandidate(candidate);
    });
  }

  /// Puts the room's audio where [wanted] says it belongs, and keeps it there.
  ///
  /// One intent, two reasons. A mute is what the host asked for and what the
  /// panel shows; parking is the room standing aside for another conversation,
  /// and it silences both directions rather than one. They stay independent
  /// causes - a mute set before an outside call outlives it with nothing to
  /// restore, and the host is never left talking into a room he believes he
  /// has left - but they meet in one value here, so what the host hears can
  /// never disagree with what he is heard in. The microphone itself is
  /// untouched either way: the app captures one pooled track and every call
  /// holds the same one, so disabling it would silence those calls too.
  ///
  /// Nothing is undone when an apply fails, and getting it applied is this
  /// object's own business: the owner plans against [audio] without waiting
  /// for the apply, so nothing outside would ever come back to finish one that
  /// threw. The apply takes the microphone off the sender before it touches
  /// what is heard, so one that got halfway has already closed the direction
  /// that matters - putting the audio back would hand the room the host's
  /// private call, which is the whole point of parking it.
  ///
  /// [_attempts] attempts, and then the room is **given up** rather than left
  /// in a state nobody can describe: that state may still have the host's
  /// microphone in the mix, or be a conference the user can see and cannot
  /// hear, or a room he believes he is muted in and is not. Giving up hands
  /// the legs back as ordinary calls, which the user can act on.
  Future<void> apply(CallAudio wanted) {
    _wanted = wanted;
    final request = ++_request;
    return _operations.run(() async {
      for (var attempt = 1; attempt <= _attempts; attempt++) {
        // Before every attempt, the retry included: a request overtaken by a
        // later one - or by a teardown - speaks for a state nobody wants any
        // more, and a retry that did not look would put the microphone back on
        // a room that is closing.
        if (request != _request) return;
        try {
          await _applyAudioState();
          return;
        } catch (e) {
          // The await can outlive this request, including on its last attempt.
          // Only a failure of the current intent can give the room up.
          if (request != _request) return;
          _logger.warning('apply: putting the room audio in place failed (attempt $attempt of $_attempts)', e);
          if (attempt == _attempts) {
            _giveUpUnappliedRoom();
            rethrow;
          }
        }
      }
    });
  }

  /// The room could not be made to do what it must, so it is given up. Silent
  /// if there is nothing left to give up - a teardown may already have run -
  /// and for a connection that has failed: nothing can be applied to that
  /// one, its failure is reported by itself, and what is wanted is kept for
  /// the connection that replaces it.
  void _giveUpUnappliedRoom() {
    final peerConnection = _peerConnection;
    if (peerConnection == null || !_isUsable(peerConnection)) return;
    _logger.warning('apply: the room audio cannot be applied, giving the room up');
    onConnectionLost();
  }

  /// Closes the room's peer connection, gives the microphone back and
  /// forgets the room: the self mute, the parking and any waiting candidates
  /// with it.
  Future<void> teardown() {
    _wanted = const CallAudio(microphone: true, audible: true);
    // Anything still queued belongs to a room that is over.
    _request++;
    _pendingCandidates.clear();
    return _operations.run(_close);
  }

  /// Closes a connection that is of no use any more and keeps the room: the
  /// host's mute and the room's parking stay as they are, for the connection
  /// the next offer is answered on. Candidates still waiting were the dead
  /// connection's and go with it, and so does an apply still queued for it:
  /// what it was to put in place is read again when the next one opens.
  Future<void> release() {
    _request++;
    _pendingCandidates.clear();
    return _operations.run(_close);
  }

  /// Closes the connection and the microphone, keeping what belongs to the
  /// next connection: the self mute, and candidates that came ahead of the
  /// offer.
  Future<void> _close() async {
    final peerConnection = _peerConnection;
    final microphone = _microphone;
    _peerConnection = null;
    _microphone = null;
    _room = null;
    _remoteDescribed = false;
    _hadConnected = false;
    if (peerConnection != null) {
      peerConnection.onIceCandidate = null;
      peerConnection.onIceGatheringState = null;
      try {
        await peerConnection.close();
        await peerConnection.dispose();
      } catch (e) {
        _logger.warning('teardown: closing the peer connection failed', e);
      }
    }
    if (microphone != null) {
      try {
        await _userMediaBuilder.release(microphone);
      } catch (e) {
        _logger.warning('teardown: releasing the microphone failed', e);
      }
    }
  }

  Future<RTCPeerConnection> _open() async {
    final peerConnection = await _factory.create();
    try {
      final microphone = await _userMediaBuilder.build(video: false);
      _microphone = microphone;
      for (final track in microphone.getAudioTracks()) {
        await peerConnection.addTrack(track, microphone);
      }
      // Guarded by identity, not by the handler being cleared: a callback
      // already on its way when the connection was closed would otherwise
      // trickle a dead room's candidate into the next one.
      peerConnection.onIceCandidate = (candidate) {
        if (identical(_peerConnection, peerConnection)) onLocalCandidate(candidate);
      };
      peerConnection.onIceGatheringState = (state) {
        if (state != RTCIceGatheringState.RTCIceGatheringStateComplete) return;
        if (identical(_peerConnection, peerConnection)) onLocalCandidate(null);
      };
      // A failed connection is not something to recover from here: the owner
      // is told, so it can ask the server for a new offer or hand the calls
      // back rather than leave the user in silence.
      peerConnection.onConnectionState = (state) => _onConnectionState(peerConnection, state);
      _peerConnection = peerConnection;
      await _applyAudioState();
      return peerConnection;
    } catch (e) {
      _peerConnection = peerConnection;
      await _close();
      rethrow;
    }
  }

  void _onConnectionState(RTCPeerConnection peerConnection, RTCPeerConnectionState state) {
    if (!identical(_peerConnection, peerConnection)) return;
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) _hadConnected = true;
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) onConnectionFailed(hadConnected: _hadConnected);
  }

  /// Puts the room's audio where the current state says it belongs: the
  /// microphone on the room's sender unless the host is muted or the room is
  /// parked, and the mix audible unless the room is parked.
  ///
  /// Both directions in one place, because they answer to overlapping reasons:
  /// two appliers would have to agree on which reason wins, and the state the
  /// host hears would be able to disagree with the state he is heard in. The
  /// sender comes first on purpose: it is the direction that would carry the
  /// host's other conversation into the room, so a half-done park has closed
  /// that one.
  Future<void> _applyAudioState() async {
    final peerConnection = _peerConnection;
    if (peerConnection == null) return;
    final track = _microphone?.getAudioTracks().firstOrNull;
    final sender = await peerConnection.audioSender();
    if (sender != null && track != null) {
      await sender.replaceTrack(_wanted.microphone ? track : null);
    }
    // The mixed audio plays natively and no stream of it is kept, so the
    // receiver's own track is the only handle on what the host hears. It is
    // absent until a remote description has been set, and then this runs
    // again - see [answer].
    final inbound = await peerConnection.audioReceiverTrack();
    if (inbound != null) inbound.enabled = _wanted.audible;
  }

  static bool _isUsable(RTCPeerConnection peerConnection) => switch (peerConnection.connectionState) {
    RTCPeerConnectionState.RTCPeerConnectionStateClosed || RTCPeerConnectionState.RTCPeerConnectionStateFailed => false,
    _ => true,
  };
}
