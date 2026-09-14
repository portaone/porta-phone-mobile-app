import 'package:collection/collection.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/models/models.dart';

import 'call_network_quality.dart';
import 'ice_connection_issue.dart';
import 'jsep_value.dart';
import 'processing_status.dart';
import 'transfer.dart';

part 'active_call.freezed.dart';

@freezed
class ActiveCall with _$ActiveCall implements CallEntry {
  ActiveCall({
    required this.direction,
    required this.line,
    required this.callId,
    required this.handle,
    required this.createdTime,
    required this.video,
    required this.processingStatus,
    this.videoPermissionDenied = false,
    this.frontCamera = true,
    this.held = false,
    this.muted = false,
    this.updating = false,
    this.incomingOffer,
    this.displayName,
    this.fromReferId,
    this.fromReplaces,
    this.fromNumber,
    this.acceptedTime,
    this.hungUpTime,
    this.transfer,
    this.failure,
    this.localStream,
    this.remoteStream,
    this.remoteCameraEnabled,
    this.speakerOnBeforeMinimize,
    this.iceCandidates = const [],
    this.iceConnectionIssue,
    this.networkQuality,
    this.earlyMedia = false,
  });

  @override
  final CallDirection direction;

  @override
  final int? line;

  @override
  final String callId;

  @override
  final CallkeepHandle handle;

  @override
  final DateTime createdTime;

  /// Whether the user has explicitly enabled the local camera for this call.
  ///
  /// This is local camera intent, not remote SDP capability. It is set only by
  /// user actions (the camera control event) and initial media setup.
  /// Never derive it from a remote SDP offer — that is what [remoteVideo] is for.
  @override
  final bool video;

  /// Set when an incoming video call was answered audio-only because camera
  /// permission was denied. Drives the camera-button hint that routes the user
  /// to app settings. It is a best-effort hint: the button re-checks the live
  /// permission on tap, so a stale value cannot send a user with granted
  /// permission to settings.
  @override
  final bool videoPermissionDenied;

  @override
  final CallProcessingStatus processingStatus;

  @override
  final bool? frontCamera;

  @override
  final bool held;

  @override
  final bool muted;

  @override
  final bool updating;

  @override
  final JsepValue? incomingOffer;

  @override
  final String? displayName;

  @override
  final String? fromReferId;

  @override
  final String? fromReplaces;

  @override
  final String? fromNumber;

  @override
  final DateTime? acceptedTime;

  @override
  final DateTime? hungUpTime;

  @override
  final Transfer? transfer;

  @override
  final Object? failure;

  @override
  final MediaStream? localStream;

  @override
  final MediaStream? remoteStream;

  /// Last known remote camera state, delivered via the media_state signaling
  /// event. `null` until the remote side reports anything. Soft mute keeps
  /// the negotiated video track alive (black frames), so the track presence
  /// alone cannot tell whether the remote camera is actually on - this flag
  /// can.
  @override
  final bool? remoteCameraEnabled;

  @override
  final bool? speakerOnBeforeMinimize;

  @override
  final List<RTCIceCandidate> iceCandidates;

  @override
  final IceConnectionIssue? iceConnectionIssue;

  /// Transient media-degradation indicator from Janus `slowlink` events.
  /// Null when the media is healthy; auto-cleared once slowlink events stop.
  @override
  final CallNetworkQuality? networkQuality;

  /// Whether the remote side already streams audio to this outgoing call before
  /// it is answered (early media: a network ringback, an announcement, an IVR).
  ///
  /// Set only once the remote description carrying that media has actually been
  /// applied - an event alone is not enough, since a missing peer connection or
  /// a failed description leaves the call silent and the local ringback needed.
  /// Once set, the local ringback must not be started again: a provisional
  /// ringing answer can still arrive afterwards and would otherwise play the
  /// bundled tone on top of the network one.
  @override
  final bool earlyMedia;

  @override
  bool get isIncoming => direction == CallDirection.incoming;

  @override
  bool get isOutgoing => direction == CallDirection.outgoing;

  @override
  bool get wasAccepted => acceptedTime != null;

  /// An incoming call that is still ringing - offered but not yet accepted.
  bool get isIncomingRinging => isIncoming && !wasAccepted;

  @override
  bool get wasHungUp => hungUpTime != null;

  /// The answer default for an incoming [offer]: a video offer is answered
  /// with video unless the caller has since reported the camera off.
  /// [remoteVideo] is the caller's last reported camera state, `null` while
  /// nothing was reported.
  static bool incomingVideo(JsepValue? offer, bool? remoteVideo) => (offer?.hasVideo ?? false) && (remoteVideo ?? true);

  /// This call as the caller's [offer] describes it: the offer, its [line],
  /// the answer default and the caller's camera state. Every place that learns
  /// of an incoming offer applies it this way - the fast path that wakes an
  /// answer already waiting for the offer and the queued incoming mutation -
  /// so the answer opens the same media whichever of them runs first. An
  /// event re-delivered without a jsep keeps the offer already stored.
  ActiveCall withIncomingOffer(JsepValue? offer, {required int? line, bool? remoteVideo}) {
    final resolvedOffer = offer ?? incomingOffer;
    return copyWith(
      incomingOffer: resolvedOffer,
      line: line,
      video: incomingVideo(resolvedOffer, remoteVideo),
      remoteCameraEnabled: remoteVideo ?? remoteCameraEnabled,
    );
  }

  /// Whether the remote peer is expected to send (or is already sending) video.
  ///
  /// Returns `true` when the remote stream contains at least one video track
  /// (confirmed by WebRTC). Falls back to the logical [video] flag when the
  /// stream is absent or audio-only. Note [video] is the LOCAL camera intent
  /// (see its doc), used here only as a provisional proxy until the remote
  /// tracks confirm; the authoritative remote signal is [remoteCameraEnabled].
  /// The fallback covers the window between the SDP
  /// negotiation completing and the first video frame arriving, which is
  /// especially common after a glare-resolution rollback where [onAddStream]
  /// does not re-fire for the updated stream and only [onAddTrack] signals the
  /// new video track.
  /// An explicit remote camera-off report ([remoteCameraEnabled] == false)
  /// overrides both: a soft-muted remote track keeps delivering black frames,
  /// which must not present the call as a video call.
  bool get remoteVideo {
    if (remoteCameraEnabled == false) return false;
    return (remoteStream?.getVideoTracks().isNotEmpty ?? false) || video;
  }

  /// Indicates whether the [localStream] contains at least one video track.
  ///
  /// This checks for the physical existence of a track in the stream, ignoring its
  /// current [MediaStreamTrack.enabled] state. This distinction is crucial for
  /// correct state comparison, as tracks are mutable objects.
  bool get hasLocalVideoTrack => localStream?.getVideoTracks().isNotEmpty ?? false;

  /// Determines whether the local camera is effectively active and should be displayed.
  ///
  /// This is the primary flag for UI visibility. It evaluates to `true` only if:
  /// 1. The user has explicitly enabled video (logical state [video] is `true`).
  /// 2. A valid video track exists in the [localStream] (technical state [hasLocalVideoTrack] is `true`).
  bool get isCameraActive =>
      video && hasLocalVideoTrack && localStream?.getVideoTracks().any((track) => track.enabled) == true;
}

extension ActiveCallIterableExtension<T extends ActiveCall> on Iterable<T> {
  T get current => lastWhere((activeCall) => !activeCall.held, orElse: () => last);

  List<T> get nonCurrent => where((activeCall) => activeCall != current).toList();

  T? get blindTransferInitiated => firstWhereOrNull((activeCall) => activeCall.transfer is BlindTransferInitiated);

  /// The calls answering acts upon - everything except the still-ringing
  /// incoming ones (they keep ringing; the rest is held or ended).
  List<T> get nonIncomingRinging => where((activeCall) => !activeCall.isIncomingRinging).toList();

  /// The most concerning media-degradation indicator across all calls, for the
  /// global toolbar status line: an active (non-recovered) warning beats a
  /// recovered confirmation, then the higher severity wins. `null` when every
  /// stream is healthy.
  CallNetworkQuality? get worstNetworkQuality {
    CallNetworkQuality? worst;
    for (final call in this) {
      final quality = call.networkQuality;
      if (quality == null) continue;
      int score(CallNetworkQuality q) => q.recovered ? -1 : q.severity.index;
      if (worst == null || score(quality) > score(worst)) worst = quality;
    }
    return worst;
  }

  /// The first real media failure across all calls; failures take precedence
  /// over degradation warnings on the toolbar status line.
  IceConnectionIssue? get firstIceConnectionIssue =>
      firstWhereOrNull((activeCall) => activeCall.iceConnectionIssue != null)?.iceConnectionIssue;
}
