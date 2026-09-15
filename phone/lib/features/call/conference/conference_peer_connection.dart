import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/call/utils/utils.dart';

final _logger = Logger('ConferencePeerConnection');

/// Receives the candidates the room's peer connection gathers; `null` marks
/// the end of gathering.
typedef ConferenceCandidateSink = void Function(RTCIceCandidate? candidate);

/// Told when the connection to the mixer is gone for good.
typedef ConferenceConnectionLost = void Function();

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
  }) : _factory = factory,
       _userMediaBuilder = userMediaBuilder;

  final PeerConnectionFactory _factory;
  final UserMediaBuilder _userMediaBuilder;
  final ConferenceCandidateSink onLocalCandidate;

  /// The mixer connection failed. There is no way to ask for it again - the
  /// server offers a room once - so the room is over for this client.
  final ConferenceConnectionLost onConnectionLost;

  RTCPeerConnection? _peerConnection;
  MediaStream? _microphone;

  /// Everything that touches the connection runs here, one at a time.
  ///
  /// Opening one takes two awaits - the factory and the microphone - and a
  /// teardown arriving in between would find nothing to tear down and then
  /// let the half-built connection finish, leaving it open with nobody
  /// holding it and the microphone never given back.
  Future<void> _work = Future<void>.value();
  int? _room;
  bool _remoteDescribed = false;
  bool _selfMuted = false;

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

  /// Answers the mixer's [offer] for [room] and returns the local description
  /// to send back.
  ///
  /// The same room on a usable connection is renegotiated in place; a
  /// different room, or a connection that is closed or failed, gets a fresh
  /// one - a spent connection would look connected and carry silence.
  Future<RTCSessionDescription> answer({required int room, required Map<String, dynamic> offer}) {
    return _exclusively(() async {
      var peerConnection = _peerConnection;
      if (peerConnection == null || _room != room || !_isUsable(peerConnection)) {
        await _close();
        peerConnection = await _open();
        _room = room;
      }
      await peerConnection.setRemoteDescription(
        RTCSessionDescription(offer['sdp'] as String?, offer['type'] as String?),
      );
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
      return answer;
    });
  }

  /// Feeds a candidate from the mixer; `null` is the end of its gathering and
  /// needs nothing here. A candidate ahead of the offer waits for it.
  Future<void> addRemoteCandidate(Map<String, dynamic>? candidate) {
    if (candidate == null) return Future<void>.value();
    final iceCandidate = RTCIceCandidate(
      candidate['candidate'] as String?,
      candidate['sdpMid'] as String?,
      candidate['sdpMLineIndex'] as int?,
    );
    return _exclusively(() async {
      final peerConnection = _peerConnection;
      if (peerConnection == null || !_remoteDescribed) {
        _pendingCandidates.add(iceCandidate);
        return;
      }
      await peerConnection.addCandidate(iceCandidate);
    });
  }

  /// Mutes the host's microphone towards the room, without leaving it, by
  /// taking it off the room's own sender.
  ///
  /// The microphone itself is untouched: the app captures one pooled track
  /// and every call holds the same one, so disabling it would silence those
  /// calls too. Kept across a rebuilt connection; the room ending needs no
  /// undoing, because nothing outside it was changed.
  Future<void> setSelfMuted(bool muted) {
    _selfMuted = muted;
    return _exclusively(_applySelfMute);
  }

  /// Closes the room's peer connection, gives the microphone back and
  /// forgets the room: the self mute and any waiting candidates with it.
  Future<void> teardown() {
    _selfMuted = false;
    _pendingCandidates.clear();
    return _exclusively(_close);
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
      // Nobody re-offers a room, so a failed connection is not something to
      // recover from here; the owner is told so it can give the room up and
      // hand the calls back rather than leave the user in silence.
      peerConnection.onConnectionState = (state) {
        if (state != RTCPeerConnectionState.RTCPeerConnectionStateFailed) return;
        if (identical(_peerConnection, peerConnection)) onConnectionLost();
      };
      _peerConnection = peerConnection;
      await _applySelfMute();
      return peerConnection;
    } catch (e) {
      _peerConnection = peerConnection;
      await _close();
      rethrow;
    }
  }

  /// Runs [action] after whatever the connection is already doing.
  Future<T> _exclusively<T>(Future<T> Function() action) {
    final result = _work.then((_) => action());
    _work = result.then((_) {}, onError: (_, _) {});
    return result;
  }

  Future<void> _applySelfMute() async {
    final peerConnection = _peerConnection;
    final track = _microphone?.getAudioTracks().firstOrNull;
    if (peerConnection == null || track == null) return;
    final sender = await peerConnection.audioSender();
    if (sender == null) return;
    await sender.replaceTrack(_selfMuted ? null : track);
  }

  static bool _isUsable(RTCPeerConnection peerConnection) => switch (peerConnection.connectionState) {
    RTCPeerConnectionState.RTCPeerConnectionStateClosed || RTCPeerConnectionState.RTCPeerConnectionStateFailed => false,
    _ => true,
  };
}
