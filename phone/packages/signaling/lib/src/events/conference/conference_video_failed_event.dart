import '../../conference_video_types.dart';
import '../abstract_events.dart';

/// A conference video request or PeerConnection failed after it was
/// acknowledged.
///
/// Two shapes share the event. With [pc], the room refused a publication or a
/// subscription: [reason] is Janus's error text and [code] its number (432 is
/// the room's publisher limit). Core has dropped that handle; the client closes
/// that PeerConnection and publishes or subscribes again. With [request], the
/// host's controller refused a request an invited far end sent, which its own
/// controller had already acknowledged: [reason] is one of the
/// video refusal reasons (`not_subscribed`, `not_in_conference`, ...).
class ConferenceVideoFailedEvent extends SessionEvent {
  const ConferenceVideoFailedEvent({super.transaction, this.pc, this.request, required this.reason, this.code});

  final ConferenceVideoPc? pc;

  /// The refused request's type, such as `conference_video_answer`.
  final String? request;

  final String reason;
  final int? code;

  @override
  List<Object?> get props => [...super.props, pc, request, reason, code];

  static const typeValue = 'conference_video_failed';

  @override
  Map<String, dynamic> toJson() => {
    ...sessionBaseJson(typeValue),
    if (pc != null) 'pc': pc!.value,
    if (request != null) 'request': request,
    'reason': reason,
    if (code != null) 'code': code,
  };

  factory ConferenceVideoFailedEvent.fromJson(Map<String, dynamic> json) {
    final eventTypeValue = json[Event.typeKey];
    if (eventTypeValue != typeValue) {
      throw ArgumentError.value(eventTypeValue, Event.typeKey, 'Not equal $typeValue');
    }

    return ConferenceVideoFailedEvent(
      transaction: json['transaction'],
      pc: ConferenceVideoPc.tryFromValue(json['pc']),
      request: json['request'] as String?,
      // Janus's text goes into it as Janus sent it; whatever it is, the client
      // still has to start that PeerConnection over, so it does not fail the event.
      reason: json['reason'] is String ? json['reason'] as String : '',
      code: json['code'] as int?,
    );
  }
}
