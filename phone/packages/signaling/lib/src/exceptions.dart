abstract class WebtritSignalingException implements Exception {
  const WebtritSignalingException(this.id);

  final int id;

  @override
  String toString() => '$runtimeType id: $id';
}

class WebtritSignalingErrorException extends WebtritSignalingException {
  const WebtritSignalingErrorException(super.id, this.code, this.reason);

  final int code;
  final String reason;

  @override
  String toString() => '${super.toString()}, code: $code, reason: $reason';
}

class WebtritSignalingDisconnectedException extends WebtritSignalingException {
  const WebtritSignalingDisconnectedException(super.id);
}

class WebtritSignalingUnknownMessageException extends WebtritSignalingException {
  const WebtritSignalingUnknownMessageException(super.id, this.message);

  final Map<String, dynamic> message;

  @override
  String toString() => '${super.toString()}, message: $message';
}

class WebtritSignalingUnknownResponseException extends WebtritSignalingException {
  const WebtritSignalingUnknownResponseException(super.id, this.response);

  final Map<String, dynamic> response;

  @override
  String toString() => '${super.toString()}, response: $response';
}

abstract class WebtritSignalingTransactionException extends WebtritSignalingException {
  const WebtritSignalingTransactionException(super.id, this.transactionId);

  final String transactionId;

  @override
  String toString() => '${super.toString()}, transactionId: $transactionId';
}

class WebtritSignalingTransactionTimeoutException extends WebtritSignalingTransactionException {
  const WebtritSignalingTransactionTimeoutException(super.id, super.transactionId);
}

class WebtritSignalingBadStateException extends WebtritSignalingException {
  const WebtritSignalingBadStateException(super.id, this.error);

  final StateError error;

  @override
  String toString() => '${super.toString()}, stateError: $error';
}

class WebtritSignalingKeepaliveTransactionTimeoutException extends WebtritSignalingTransactionTimeoutException {
  const WebtritSignalingKeepaliveTransactionTimeoutException(super.id, super.transactionId);
}

/// The keepalive was answered on a connection whose state handshake never
/// came. The server sends the state first, so such a connection lost frames
/// on the way and is given up as one whose keepalive got no answer.
class WebtritSignalingKeepaliveWithoutStateException extends WebtritSignalingKeepaliveTransactionTimeoutException {
  const WebtritSignalingKeepaliveWithoutStateException(super.id, super.transactionId);
}

abstract class WebtritSignalingTransactionTerminateException extends WebtritSignalingTransactionException {
  const WebtritSignalingTransactionTerminateException(super.id, super.transactionId);
}

class WebtritSignalingTransactionTerminateByDisconnectException extends WebtritSignalingTransactionTerminateException {
  const WebtritSignalingTransactionTerminateByDisconnectException(
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
