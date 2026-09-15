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
