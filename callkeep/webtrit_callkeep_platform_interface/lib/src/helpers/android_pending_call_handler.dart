/// Represents a pending call on Android.
class PendingCall {
  /// Creates a new instance of [PendingCall].
  PendingCall({
    required this.id,
    required this.handle,
    required this.displayName,
    this.hasVideo = false,
    this.hasMute = false,
    this.hasHold = false,
    this.offeredAt,
  });

  /// Creates a new instance of [PendingCall] from a map.
  factory PendingCall.fromMap(Map<String, dynamic> map) {
    return PendingCall(
      id: map['callId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      handle: map['number'] as String? ?? '',
      hasVideo: map['hasVideo'] == 'true',
      hasMute: map['hasMute'] == 'true',
      hasHold: map['hasHold'] == 'true',
      offeredAt: int.tryParse(map['offeredAt'] as String? ?? ''),
    );
  }

  /// Unique identifier for the call
  final String id;

  /// Display name of the caller
  final String displayName;

  /// Phone number of the caller
  final String handle;

  /// Whether the call has video
  final bool hasVideo;

  /// Whether the call is muted
  final bool hasMute;

  /// Whether the call is on hold
  final bool hasHold;

  /// Core's `offered_at` of the offer, the push's `offeredAt` (epoch milliseconds by Core's clock):
  /// the moment Core learned of this offer, when Janus reported its incomingcall. The same value
  /// as the offer's incoming_call event and its handshake call log; a new offer of the same Call-ID
  /// gets another. It identifies the offer: compared for equality only, never with a clock. Null
  /// from a Core that does not send it.
  final int? offeredAt;

  @override
  String toString() {
    return 'PendingCall{id: $id, displayName: $displayName, handle: $handle, hasVideo: $hasVideo, hasMute: $hasMute, hasHold: $hasHold, offeredAt: $offeredAt}';
  }
}
