abstract class SignalingException implements Exception {
  const SignalingException(this.id);

  final int id;

  @override
  String toString() => '$runtimeType id: $id';
}

class SignalingErrorException extends SignalingException {
  const SignalingErrorException(super.id, this.code, this.reason);

  final int code;
  final String reason;

  @override
  String toString() => '${super.toString()}, code: $code, reason: $reason';
}

class SignalingDisconnectedException extends SignalingException {
  const SignalingDisconnectedException(super.id);
}

class SignalingUnknownMessageException extends SignalingException {
  const SignalingUnknownMessageException(super.id, this.message);

  final Map<String, dynamic> message;

  @override
  String toString() => '${super.toString()}, message: $message';
}

class SignalingUnknownResponseException extends SignalingException {
  const SignalingUnknownResponseException(super.id, this.response);

  final Map<String, dynamic> response;

  @override
  String toString() => '${super.toString()}, response: $response';
}

abstract class SignalingTransactionException extends SignalingException {
  const SignalingTransactionException(super.id, this.transactionId);

  final String transactionId;

  @override
  String toString() => '${super.toString()}, transactionId: $transactionId';
}

class SignalingTransactionTimeoutException extends SignalingTransactionException {
  const SignalingTransactionTimeoutException(super.id, super.transactionId);
}

class SignalingBadStateException extends SignalingException {
  const SignalingBadStateException(super.id, this.error);

  final StateError error;

  @override
  String toString() => '${super.toString()}, stateError: $error';
}

class SignalingKeepaliveTimeoutException extends SignalingTransactionTimeoutException {
  const SignalingKeepaliveTimeoutException(super.id, super.transactionId);
}

/// The keepalive was answered on a connection whose state handshake never
/// came. The server sends the state first, so such a connection lost frames
/// on the way and is given up as one whose keepalive got no answer.
class SignalingStateHandshakeMissingException extends SignalingKeepaliveTimeoutException {
  const SignalingStateHandshakeMissingException(super.id, super.transactionId);
}

abstract class SignalingTransactionTerminateException extends SignalingTransactionException {
  const SignalingTransactionTerminateException(super.id, super.transactionId);
}

class SignalingTransactionTerminateByDisconnectException extends SignalingTransactionTerminateException {
  const SignalingTransactionTerminateByDisconnectException(
    super.id,
    super.transactionId,
    this.closeCode,
    this.closeReason,
  );

  final int? closeCode;
  final String? closeReason;

  @override
  String toString() => '${super.toString()}, code: $closeCode, reason: $closeReason';
}
