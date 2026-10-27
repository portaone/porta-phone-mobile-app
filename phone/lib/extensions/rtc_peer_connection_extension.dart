import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Extension on [RTCPeerConnection] to safely add a track.
/// This extension checks the signaling and connection state before adding a track.
/// If the connection is closed, it returns null instead of throwing an error,
/// otherwise, it returns the added [RTCRtpSender].
extension RTCPeerConnectionSafeAddTrack on RTCPeerConnection {
  Future<RTCRtpSender?> safeAddTrack(MediaStreamTrack track, MediaStream stream) async {
    if (signalingState != RTCSignalingState.RTCSignalingStateClosed &&
        connectionState != RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
      return addTrack(track, stream);
    }
    return null;
  }
}

/// Finds the sender that carries this connection's microphone.
///
/// The transceiver's own media decides, not the track currently on the
/// sender: a muted connection has no track there to recognise it by. Before
/// a remote description arrives the transceiver has no receiver track either,
/// and then the sender's own track is all there is to go by.
extension RTCPeerConnectionAudioSender on RTCPeerConnection {
  Future<RTCRtpSender?> audioSender() async {
    final transceivers = await getTransceivers();
    final audio = transceivers.firstWhereOrNull((transceiver) => transceiver.receiver.track?.kind == 'audio');
    if (audio != null) return audio.sender;
    final senders = await getSenders();
    return senders.firstWhereOrNull((sender) => sender.track?.kind == 'audio');
  }
}

/// Finds the track this connection plays for the remote audio.
///
/// It appears only once a remote description has been set - before that the
/// transceiver has no receiver track - and a connection that keeps no remote
/// stream of its own has nothing else to hold what is heard by.
extension RTCPeerConnectionAudioReceiver on RTCPeerConnection {
  Future<MediaStreamTrack?> audioReceiverTrack() async {
    final transceivers = await getTransceivers();
    final audio = transceivers.firstWhereOrNull((transceiver) => transceiver.receiver.track?.kind == 'audio');
    return audio?.receiver.track;
  }
}

/// Mutes one connection without touching the microphone behind it.
///
/// The app captures one track and lends the same one to every call, so the
/// track itself must keep running: only what a sender carries may change.
extension RTCRtpSenderMicrophone on RTCRtpSender {
  /// Stops this connection from sending. The stream stays up and carries
  /// silence, so the far end hears nothing rather than falling away.
  Future<void> detachMicrophone() => replaceTrack(null);

  /// Puts [microphone] back, unless this sender already carries a track.
  Future<void> attachMicrophone(MediaStreamTrack microphone) async {
    if (track == null) await replaceTrack(microphone);
  }
}

/// A call held by its own offer: the transceiver that carries the microphone
/// is inactive, so every offer of the connection says the call is on hold.
///
/// After a cold restart a call the server holds is restored this way. Its
/// restore offer goes on to the far end as a re-INVITE: offered `sendrecv` it
/// would take the call off hold on the server, while the gateway still counts
/// it held and answers a later hold without sending one. Offered held, the
/// call stays held everywhere, and a hold asked for meanwhile has nothing to
/// send. A resume gives the microphone back, which renegotiates the call.
extension RTCPeerConnectionOfferHold on RTCPeerConnection {
  /// Holds the call by its offer: the next offer has the microphone inactive.
  /// The other transceivers keep the directions the connection was built with.
  Future<void> holdByOffer() async => (await _microphoneTransceiver())?.setDirection(TransceiverDirection.Inactive);

  /// Whether the call is held by its offer and not resumed since.
  ///
  /// An offer of such a call must not ask to receive audio: libwebrtc would
  /// answer that with a second, `recvonly` audio transceiver, and the gateway
  /// takes its codec from that line once it is rejected.
  Future<bool> heldByOffer() async {
    final transceiver = await _microphoneTransceiver();
    return transceiver != null && await transceiver.getDirection() == TransceiverDirection.Inactive;
  }

  /// Gives the microphone back to a call held by its offer; nothing for any
  /// other call. Whether it did.
  Future<bool> resumeFromOfferHold() async {
    final transceiver = await _microphoneTransceiver();
    if (transceiver == null || await transceiver.getDirection() != TransceiverDirection.Inactive) return false;
    await transceiver.setDirection(TransceiverDirection.SendRecv);
    return true;
  }

  Future<RTCRtpTransceiver?> _microphoneTransceiver() async =>
      (await getTransceivers()).firstWhereOrNull((transceiver) => transceiver.sender.track?.kind == 'audio');
}
