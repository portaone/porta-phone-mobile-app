part of 'call_bloc.dart';

extension _RestoreCallActionMapping on RestoreCallAction {
  /// A call the server holds as answered and the bloc does not have.
  CallEvent toCallEvent() {
    return _RestoreAcceptedCall(
      line: line,
      callId: callId,
      acceptedEvent: acceptedEvent,
      acceptedTime: acceptedTime,
      incomingCallEvent: incomingCallEvent,
      remoteCameraEnabled: mediaState?.video,
    );
  }
}
