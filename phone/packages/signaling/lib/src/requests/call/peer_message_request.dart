import '../abstract_requests.dart';

/// In-call app-to-app message. The server is a dumb relay: it forwards the
/// envelope to the peer's sessions without inspecting it. The concrete subtype
/// is selected by the inner `type` field; each message's typed contract lives
/// here. Requests are client->server only, so an unknown `type` is a genuine
/// programming error (unlike inbound events, there is no forward-compat case).
sealed class PeerMessageRequest extends CallRequest {
  const PeerMessageRequest({required super.transaction, required super.line, required super.callId});

  static const typeValue = 'peer_message';

  factory PeerMessageRequest.fromJson(Map<String, dynamic> json) {
    final requestTypeValue = json[Request.typeKey];
    if (requestTypeValue != typeValue) {
      throw ArgumentError.value(requestTypeValue, Request.typeKey, 'Not equal $typeValue');
    }

    return switch (json['type']) {
      MediaStatePeerMessageRequest.messageType => MediaStatePeerMessageRequest.fromJson(json),
      ConferenceMutePeerMessageRequest.messageType => ConferenceMutePeerMessageRequest.fromJson(json),
      final other => throw ArgumentError.value(other, 'type', 'Unknown peer_message type'),
    };
  }
}

/// Local camera state to mirror on the peer (`data: {video: bool}`).
final class MediaStatePeerMessageRequest extends PeerMessageRequest {
  const MediaStatePeerMessageRequest({
    required super.transaction,
    required super.line,
    required super.callId,
    required this.video,
  });

  static const messageType = 'media_state';

  final bool video;

  @override
  List<Object?> get props => [...super.props, video];

  factory MediaStatePeerMessageRequest.fromJson(Map<String, dynamic> json) {
    return MediaStatePeerMessageRequest(
      transaction: json['transaction'],
      line: json['line'],
      callId: json['call_id'],
      video: json['data']['video'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      Request.typeKey: PeerMessageRequest.typeValue,
      'transaction': transaction,
      'line': line,
      'call_id': callId,
      'type': messageType,
      'data': {'video': video},
    };
  }
}

/// Tells the other party of this call that the host has muted them for the
/// whole room, or lifted it (`data: {muted: bool}`).
///
/// The server tells a muted participant nothing - every conference message is
/// addressed to the host's session - and their own client has no room state
/// to read. This is the host saying so over the one channel the two of them
/// share; see [ConferenceMutePeerMessageEvent] for why the receiving side
/// treats it as a claim about this call rather than as its own state.
final class ConferenceMutePeerMessageRequest extends PeerMessageRequest {
  const ConferenceMutePeerMessageRequest({
    required super.transaction,
    required super.line,
    required super.callId,
    required this.muted,
  });

  static const messageType = 'conference_mute_state';

  final bool muted;

  @override
  List<Object?> get props => [...super.props, muted];

  factory ConferenceMutePeerMessageRequest.fromJson(Map<String, dynamic> json) {
    return ConferenceMutePeerMessageRequest(
      transaction: json['transaction'],
      line: json['line'],
      callId: json['call_id'],
      muted: json['data']['muted'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      Request.typeKey: PeerMessageRequest.typeValue,
      'transaction': transaction,
      'line': line,
      'call_id': callId,
      'type': messageType,
      'data': {'muted': muted},
    };
  }
}
