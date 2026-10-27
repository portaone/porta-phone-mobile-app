import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service/signaling_service.dart';

import 'renegotiation_coordinator.dart';

/// What the resume needs to know about a call, read afresh before each step:
/// any wait may let a hold, the end of the call or a signaling loss in.
typedef PulledCallView = ({
  bool signalingReady,
  bool pulled,
  bool connected,
  bool hungUp,
  bool held,
  bool conferenced,
  bool updating,
  int? line,
  bool video,
});

/// Sends the fresh offer that resumes a pulled call, on a [ResumePulledCall]
/// of the [RenegotiationCoordinator].
///
/// PortaSIP can keep playing music to the far end after a pull although both
/// sides negotiated sendrecv; only an offer of our own stops it. The
/// coordinator decides when that offer is due and how often it may be tried;
/// this sends one, steps back whenever the call stops being ready for it, and
/// reports the outcome to the coordinator.
///
/// The resume is optional: whatever goes wrong rolls the offer back and
/// leaves the call as it was, where an ordinary renegotiation would end it.
///
/// This is a workaround on the client side. The proper fix belongs in
/// PortaSIP (SIP-15507): it should stop the music once the pull completes.
/// When it does, this class and the coordinator's pull resume can go.
class PulledCallResumer {
  PulledCallResumer({
    required RenegotiationCoordinator coordinator,
    required SignalingModule signaling,
    required Future<RTCPeerConnection?> Function(String callId) peerConnection,
    required PulledCallView? Function(String callId) readCall,
    required void Function(String callId, RTCSessionDescription offer) prepareOffer,
    this.responseTimeout = const Duration(seconds: 10),
  }) : _coordinator = coordinator,
       _signaling = signaling,
       _peerConnection = peerConnection,
       _readCall = readCall,
       _prepareOffer = prepareOffer;

  static final _logger = Logger('PulledCallResumer');

  final RenegotiationCoordinator _coordinator;
  final SignalingModule _signaling;
  final Future<RTCPeerConnection?> Function(String callId) _peerConnection;
  final PulledCallView? Function(String callId) _readCall;

  /// Munges the offer and keeps the conference codecs, as for any offer.
  final void Function(String callId, RTCSessionDescription offer) _prepareOffer;

  /// How long the server gets to reply to the offer.
  final Duration responseTimeout;

  /// Sends the resume [attempt] of the call, if it is still current and the
  /// call can take it. [setUpdating] mirrors the call's `updating` flag into
  /// the owner's state.
  Future<void> run(String callId, Object attempt, {required void Function(bool updating) setUpdating}) async {
    if (_ready(callId, attempt) == null) return;
    final pc = await _peerConnection(callId);
    if (pc == null) return;

    // The cache of the signaling state lags behind setLocalDescription, so
    // the native side is asked. A kept offer is the replay's to send.
    if (await pc.getSignalingState() != RTCSignalingState.RTCSignalingStateStable ||
        _coordinator.hasKeptOffer(callId)) {
      return _defer(callId);
    }
    // A soft-mute pull receives the far end's video on a recvonly transceiver
    // of an audio call; offering no video would turn it inactive.
    final receivesVideo = await _receivesVideo(pc);
    final offer = await pc.createOffer(<String, dynamic>{
      'mandatory': <String, dynamic>{
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': receivesVideo || (_readCall(callId)?.video ?? false),
      },
      'optional': <dynamic>[],
    });
    final call = _ready(callId, attempt);
    if (call == null) return;
    if (call.updating) return _defer(callId);
    final line = call.line;
    if (line == null) return;
    _coordinator.updatingSettled(callId);

    var installed = false;
    try {
      _prepareOffer(callId, offer);
      await pc.setLocalDescription(offer);
      installed = true;
      // A removal, a hold or a teardown may have won while the native side
      // installed the offer: the optional resume is not sent on their behalf.
      if (_ready(callId, attempt)?.updating != false) {
        await _rollBack(pc);
        return _defer(callId);
      }
      _coordinator.pullResumeSent(callId, attempt);
      _logger.info('resuming pulled call $callId with a fresh offer');

      final transaction = WebtritSignalingClient.generateTransactionId();
      await _signaling.execute(
        UpdateRequest(transaction: transaction, line: line, callId: callId, jsep: offer.toMap()),
      );
      final response = _signaling.events
          .firstWhere(
            (e) =>
                e is SignalingProtocolEvent &&
                e.event is SessionEvent &&
                (e.event as SessionEvent).transaction == transaction,
          )
          .then((e) => (e as SignalingProtocolEvent).event)
          .timeout(responseTimeout);

      // The answer is not worth holding the end of the call back: the end is
      // queued behind this wait. A hold still waits, as a new INVITE must not
      // start before this one completes (RFC 3261 14.1).
      final result = await Future.any<Object?>([response, _coordinator.pullCallEnding(callId).then((_) => null)]);
      switch (result) {
        case null:
          _logger.info('resume of $callId abandoned, the call is ending');
        case UpdatedEvent():
          _coordinator.offerCompleted(callId);
          setUpdating(false);
        case UpdatingEvent():
          // Only an interim acknowledgement: the answer comes later with the
          // accepted event, and the offer is kept until then.
          _coordinator.awaitAnswer(callId, offer);
          setUpdating(true);
        case CallErrorEvent(:final code, :final reason):
          _logger.warning('resume of $callId rejected: $code $reason');
          await _rollBack(pc);
          _coordinator.offerCompleted(callId);
          setUpdating(false);
          _coordinator.pullResumeRejected(callId, code);
        default:
          throw StateError('unexpected reply to the resume of $callId: $result');
      }
    } catch (e, s) {
      // The offer is not handed to the general replay: that one has no bound
      // and ends the call on a failure, where the resume must leave it as it
      // was. A transport loss or a missing reply is tried again within the
      // coordinator's bound; anything else ends the resume.
      final transient = _coordinator.isTransientSignalingFailure(e);
      _logger.warning('resume of $callId ${transient ? 'interrupted' : 'failed'}', e, s);
      if (installed || await pc.getSignalingState() == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        await _rollBack(pc);
      }
      if (transient) {
        _coordinator.pullResumeInterrupted(callId);
      } else {
        _coordinator.cancelPullResume(callId);
      }
    }
  }

  /// The call when the [attempt] is current and the call can take a resume,
  /// otherwise null.
  PulledCallView? _ready(String callId, Object attempt) {
    if (!_coordinator.isPullResumeCurrent(callId, attempt)) return null;
    final call = _readCall(callId);
    if (call == null ||
        !call.signalingReady ||
        !call.pulled ||
        !call.connected ||
        call.hungUp ||
        call.held ||
        call.conferenced) {
      return null;
    }
    return call;
  }

  Future<bool> _receivesVideo(RTCPeerConnection pc) async {
    final transceivers = await pc.getTransceivers();
    return transceivers.any((t) => t.receiver.track?.kind == 'video');
  }

  /// Whether a far end's offer sends and receives audio: one that holds the
  /// call (sendonly or inactive) does not ask for a resume.
  static bool offersSendRecv(String? sdp) {
    if (sdp == null) return true;
    String? session;
    String? audio;
    var section = 'session';
    var audioSeen = false;
    for (final raw in sdp.split('\n')) {
      final line = raw.trim();
      if (line.startsWith('m=')) {
        section = line.startsWith('m=audio') && !audioSeen ? 'audio' : 'other';
        audioSeen = audioSeen || section == 'audio';
      }
      const directions = {'a=sendrecv', 'a=sendonly', 'a=recvonly', 'a=inactive'};
      if (!directions.contains(line)) continue;
      if (section == 'session') session = line;
      if (section == 'audio') audio = line;
    }
    return (audio ?? session ?? 'a=sendrecv') == 'a=sendrecv';
  }

  /// Tries again after one settling time; a closed resume stays closed.
  void _defer(String callId) => _coordinator.pullResumeDeferred(callId);

  Future<void> _rollBack(RTCPeerConnection pc) async {
    try {
      await pc.setLocalDescription(RTCSessionDescription('', 'rollback'));
    } catch (e) {
      _logger.warning('rolling back the resume offer failed: $e');
    }
  }
}
