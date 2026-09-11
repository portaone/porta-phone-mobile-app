import 'package:signaling/src/requests/conference/conference_requests.dart';
import 'package:signaling/src/requests/session/session_requests.dart';

import 'abstract_requests.dart';

abstract class SessionRequest extends Request {
  const SessionRequest({required this.transaction}) : super();

  final String transaction;

  @override
  List<Object?> get props => [transaction];

  factory SessionRequest.fromJson(Map<String, dynamic> json) {
    final sessionRequest = tryFromJson(json);
    if (sessionRequest == null) {
      final requestTypeValue = json[Request.typeKey];
      throw ArgumentError.value(requestTypeValue, Request.typeKey, 'Unknown session request type');
    } else {
      return sessionRequest;
    }
  }

  static SessionRequest? tryFromJson(Map<String, dynamic> json) {
    final requestTypeValue = json[Request.typeKey];
    return _sessionRequestFromJsonDecoders[requestTypeValue]?.call(json) ?? LineRequest.tryFromJson(json);
  }

  static final Map<String, SessionRequest Function(Map<String, dynamic>)> _sessionRequestFromJsonDecoders = {
    PresenceSettingsUpdateRequest.typeValue: PresenceSettingsUpdateRequest.fromJson,
    // Conference requests are session-level even though some carry `line`:
    // there `line` names a participant, not an address.
    MergeRequest.typeValue: MergeRequest.fromJson,
    ConferenceAddRequest.typeValue: ConferenceAddRequest.fromJson,
    ConferenceAnswerRequest.typeValue: ConferenceAnswerRequest.fromJson,
    ConferenceIceTrickleRequest.typeValue: ConferenceIceTrickleRequest.fromJson,
    ConferenceMuteRequest.typeValue: ConferenceMuteRequest.fromJson,
    ConferenceRemoveRequest.typeValue: ConferenceRemoveRequest.fromJson,
    ConferenceHangupRequest.typeValue: ConferenceHangupRequest.fromJson,
  };
}
