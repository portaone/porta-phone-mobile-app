import 'models/error.dart';
import 'models/user_session.dart';

class RequestFailure implements Exception {
  RequestFailure({required this.url, this.statusCode, required this.requestId, this.token, this.error, this.rawBody});

  // package:http exposes no status-code constants; dart:io is not web-safe.
  static const _requestTimeout = 408;
  static const _tooEarly = 425;
  static const _tooManyRequests = 429;

  static const _transientStatusCodes = {_requestTimeout, _tooEarly, _tooManyRequests};

  final Uri url;
  final int? statusCode;
  final String requestId;
  final String? token;
  final ErrorResponse? error;

  /// Truncated raw response body, carried when the error payload was not JSON
  /// (e.g. a plain-text page from a proxy in front of a dead backend), so
  /// diagnostics keep the actual server response even though [error] is null.
  final String? rawBody;

  /// Whether the response is a client error (4xx).
  bool get isClientError {
    final statusCode = this.statusCode;
    return statusCode != null && statusCode >= 400 && statusCode < 500;
  }

  /// Whether the response is a server error (5xx).
  bool get isServerError {
    final statusCode = this.statusCode;
    return statusCode != null && statusCode >= 500 && statusCode < 600;
  }

  /// Whether the status is transient by HTTP semantics: the server asks to
  /// retry the request.
  bool get isTransient => _transientStatusCodes.contains(statusCode);

  /// The backend-produced error code from the response body, if any.
  String? get errorCode => error?.code;

  @override
  String toString() {
    final buffer = StringBuffer()
      ..write('RequestFailure(statusCode: $statusCode')
      ..write(', requestId: $requestId');

    if (error != null) {
      buffer.write(', code: ${error?.code}');
      final details = error?.details;
      if (details != null) buffer.write(', path: ${details.path}, reason: ${details.reason}');
    }

    if (rawBody != null) buffer.write(', rawBody: $rawBody');

    buffer.write(')');
    return buffer.toString();
  }
}

/// The mailbox no longer has the message this was about.
///
/// Deleted from another device or from the IVR, emptied out of the trash, acted
/// on twice - a list is drawn from what was true when it was read, and the
/// mailbox moves on. Named because it is the one refusal that says something
/// about the state rather than about the request: whoever asked can read their
/// list again and know the row is gone, instead of guessing from a status.
class VoicemailMessageGoneException extends RequestFailure {
  VoicemailMessageGoneException({
    required super.url,
    required super.requestId,
    required super.statusCode,
    super.token,
    super.error,
  }) : super();
}

/// The backend no longer has the notification this was about.
///
/// Deleted from another device, or removed by the retention cleaner, after the
/// list was read. Named because it says the row is gone rather than that the
/// request was wrong: whoever asked can drop it locally instead of retrying.
class SystemNotificationGoneException extends RequestFailure {
  SystemNotificationGoneException({
    required super.url,
    required super.requestId,
    required super.statusCode,
    super.token,
    super.error,
  }) : super();
}

/// The user is not an agent of the call queue this was about.
///
/// The queue was taken away from them, or the list on screen is older than the
/// PBX. Named because it says something about the list rather than about the
/// request: whoever asked can read their queues again instead of leaving a row
/// that no longer exists switched the way they left it.
class CallQueueNotFoundException extends RequestFailure {
  CallQueueNotFoundException({
    required super.url,
    required super.requestId,
    required super.statusCode,
    super.token,
    super.error,
  }) : super();
}

/// The backend failed on its own side, and nothing follows from it about what
/// the request did.
///
/// Named rather than left as a bare [RequestFailure] because the difference
/// matters to a caller: a 4xx is an answer about the thing being asked for and
/// can be acted on, while this says only that the other side broke. A caller
/// that was changing something learns nothing about whether it changed, so
/// guessing at the new state after one of these is inventing an answer the
/// backend did not give.
class ServerFailureException extends RequestFailure {
  ServerFailureException({
    required super.url,
    required super.requestId,
    required super.statusCode,
    super.token,
    super.error,
    super.rawBody,
  }) : super();
}

class EndpointNotSupportedException extends RequestFailure {
  EndpointNotSupportedException({
    required super.url,
    required super.requestId,
    required super.statusCode,
    required List<String> recognizedNotSupportedCodes,
  }) : super();
}

class VoicemailNotConfiguredException extends RequestFailure {
  VoicemailNotConfiguredException({
    required super.url,
    required super.requestId,
    required super.statusCode,
    super.token,
    super.error,
  }) : super();
}

/// A refusal that ends the session, whichever request received it: the token
/// is no longer accepted, the backend holds no session for it, or the account
/// behind it is gone. [WebtritApiClient.sessionRejections] publishes each
/// one, so a caller needs no handling of its own to have the session closed.
abstract interface class SessionRejection implements Exception {}

class UserNotFoundException extends RequestFailure implements SessionRejection {
  UserNotFoundException({required super.url, required super.requestId, required super.statusCode});

  @override
  String toString() => 'UserNotFoundException($statusCode, $url)';
}

class UnauthorizedException extends RequestFailure implements SessionRejection {
  UnauthorizedException({
    required super.url,
    required super.requestId,
    required super.statusCode,
    super.token,
    super.error,
  });

  @override
  String toString() {
    final code = error?.code;
    return 'UnauthorizedException(statusCode: $statusCode, requestId: $requestId, url: $url'
        '${code != null ? ', code: $code' : ''})';
  }
}

/// The login and password sent to create a session were refused.
///
/// The adapters disagree on how to name it - some send an
/// `incorrect_credentials` code, the PortaSwitch one sends only a message - so
/// on the session-create route the status itself is what identifies it, which
/// is why this is built by a rule declared on that endpoint.
class IncorrectCredentialsException extends RequestFailure {
  IncorrectCredentialsException({required super.url, required super.requestId, required super.statusCode, super.error});

  @override
  String toString() => 'IncorrectCredentialsException(statusCode: $statusCode, requestId: $requestId, url: $url)';
}

class SessionMissingException extends RequestFailure implements SessionRejection {
  SessionMissingException({
    required super.url,
    required super.requestId,
    required super.statusCode,
    super.token,
    super.error,
  });

  @override
  String toString() => 'SessionMissingException(statusCode: $statusCode, requestId: $requestId, url: $url)';
}

class PasswordChangeRequiredException extends RequestFailure {
  PasswordChangeRequiredException({
    required super.url,
    required super.requestId,
    required super.statusCode,
    super.token,
    super.error,
  });
}

/// The recipient named for a forward is not a user of this tenant.
///
/// The backend checks `to_user_id` against the contacts it serves, and that
/// lookup is the only thing binding a recipient to the sender's tenant, so this
/// is a rejection rather than a lookup miss worth retrying.
class VoicemailForwardRecipientNotFoundException extends RequestFailure {
  VoicemailForwardRecipientNotFoundException({
    required super.url,
    required super.requestId,
    required super.statusCode,
    super.token,
    super.error,
  });

  @override
  String toString() => 'VoicemailForwardRecipientNotFoundException(requestId: $requestId, url: $url)';
}

/// The recording is larger than this deployment copies when forwarding.
///
/// Forwarding stores a copy rather than a reference, so the ceiling is on the
/// bytes actually kept; the message itself is untouched and can still be played.
class VoicemailForwardAttachmentTooLargeException extends RequestFailure {
  VoicemailForwardAttachmentTooLargeException({
    required super.url,
    required super.requestId,
    required super.statusCode,
    super.token,
    super.error,
  });

  @override
  String toString() => 'VoicemailForwardAttachmentTooLargeException(requestId: $requestId, url: $url)';
}

/// The recipient already holds as many forwarded messages as this deployment
/// allows, so nothing more can be sent to them.
///
/// The count includes what is in their trash, so the way out is theirs and not
/// the sender's: they empty it or delete some.
class VoicemailForwardLimitReachedException extends RequestFailure {
  VoicemailForwardLimitReachedException({
    required super.url,
    required super.requestId,
    required super.statusCode,
    super.token,
    super.error,
  });

  @override
  String toString() => 'VoicemailForwardLimitReachedException(requestId: $requestId, url: $url)';
}

/// A login was refused because the account, or the customer it belongs to,
/// already has as many signed-in devices as its package allows.
///
/// Unlike the other refusals of a login this one can be answered: it carries
/// the account's own [sessions] and a [pendingLoginToken], and revoking one of
/// them with [WebtritApiClient.completeSession] finishes the login without the
/// password or the OTP being asked for again - an OTP is already spent by then.
///
/// Without a token there is nothing the user can do from here: the devices
/// filling the limit belong to other accounts of the same customer.
class DeviceLimitReachedException extends RequestFailure {
  DeviceLimitReachedException({
    required super.url,
    required super.requestId,
    required super.statusCode,
    super.error,
    this.sessions = const [],
    this.pendingLoginToken,
  });

  /// The account's active sessions, one of which may be revoked. Empty when
  /// the limit is taken by other accounts.
  final List<UserSession> sessions;

  /// Completes the login together with the id of the session to revoke. Valid
  /// for a few minutes, and for another try while the limit is still reached.
  final String? pendingLoginToken;

  /// Whether revoking one of [sessions] can finish this login.
  bool get canBeCompleted => pendingLoginToken != null;

  // The token is left out on purpose: it finishes a login.
  @override
  String toString() =>
      'DeviceLimitReachedException(statusCode: $statusCode, requestId: $requestId, '
      'sessions: ${sessions.length}, canBeCompleted: $canBeCompleted)';
}

/// A login from a device the account has not used before was refused because
/// the account has started using as many new devices as its package allows
/// within the period.
///
/// Nothing on this side helps: signing another device out frees a place, not a
/// switch. The period runs out by itself, or the administrator raises the limit.
class DeviceSwitchLimitReachedException extends RequestFailure {
  DeviceSwitchLimitReachedException({
    required super.url,
    required super.requestId,
    required super.statusCode,
    super.error,
  });

  @override
  String toString() => 'DeviceSwitchLimitReachedException(statusCode: $statusCode, requestId: $requestId, url: $url)';
}

/// The login being completed is no longer waiting: its token ran out or was
/// already used.
///
/// The way on is to sign in again from the start.
class PendingLoginNotFoundException extends RequestFailure {
  PendingLoginNotFoundException({required super.url, required super.requestId, required super.statusCode, super.error});

  @override
  String toString() => 'PendingLoginNotFoundException(statusCode: $statusCode, requestId: $requestId, url: $url)';
}

/// The session picked to make room for a login is not there to revoke any
/// more: it was signed out in the meantime.
///
/// The pending login is untouched by this, so another session can be picked
/// with the same token.
class PendingLoginSessionNotFoundException extends RequestFailure {
  PendingLoginSessionNotFoundException({
    required super.url,
    required super.requestId,
    required super.statusCode,
    super.error,
  });

  @override
  String toString() =>
      'PendingLoginSessionNotFoundException(statusCode: $statusCode, requestId: $requestId, url: $url)';
}
