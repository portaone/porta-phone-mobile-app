import 'exceptions.dart';
import 'models/models.dart';

/// What a failing response carries, handed to whichever rule recognises it.
class FailureContext {
  const FailureContext({
    required this.url,
    required this.requestId,
    required this.statusCode,
    this.token,
    this.error,
    this.rawBody,
  });

  final Uri url;
  final String requestId;
  final int statusCode;
  final String? token;
  final ErrorResponse? error;
  final String? rawBody;

  /// The backend's own error code, absent when the body carried none.
  String? get code => error?.code;

  /// The failure as it would surface with no rule recognising it.
  RequestFailure get unrecognised => RequestFailure(
    url: url,
    statusCode: statusCode,
    requestId: requestId,
    token: token,
    error: error,
    rawBody: rawBody,
  );
}

/// One recognised failure and the exception that names it.
///
/// A rule is a declaration rather than a branch in the transport, which is what
/// lets it live where the condition belongs: the ones that hold for every call
/// are in [defaultFailureRules], and anything true of a single endpoint is
/// declared by that endpoint through `ResponseOptions.failures`.
class FailureRule {
  const FailureRule({this.status, this.code, required this.build});

  /// The status this rule answers to; null matches any.
  final int? status;

  /// The backend error code this rule answers to; null matches any.
  ///
  /// A rule with neither a status nor a code matches every failure, which is
  /// only ever what an endpoint wants, never a default.
  final String? code;

  final RequestFailure Function(FailureContext failure) build;

  bool matches(FailureContext failure) =>
      (status == null || status == failure.statusCode) && (code == null || code == failure.code);
}

/// The failures that mean the same thing whichever endpoint returned them.
///
/// All five are about the session or the account behind it rather than about
/// what was being asked for, which is why they belong to every call. A rule
/// that is true of one endpoint does not belong here - it goes on that
/// endpoint, or it starts firing on requests that cannot produce it.
final List<FailureRule> defaultFailureRules = [
  // The session is gone from the backend's side.
  FailureRule(
    status: 401,
    code: 'session_missing',
    build: (f) => SessionMissingException(
      url: f.url,
      requestId: f.requestId,
      statusCode: f.statusCode,
      token: f.token,
      error: f.error,
    ),
  ),

  // Every token was invalidated, as after a backend restart. Mapped so the
  // SessionGuard chain logs the user out rather than showing a bare failure.
  FailureRule(
    status: 401,
    code: 'token_invalid',
    build: (f) => UnauthorizedException(
      url: f.url,
      requestId: f.requestId,
      statusCode: f.statusCode,
      token: f.token,
      error: f.error,
    ),
  ),

  // A refused refresh is the same condition reported at a different status, and
  // higher layers should not have to know that.
  FailureRule(
    status: 422,
    code: 'refresh_token_invalid',
    build: (f) => UnauthorizedException(
      url: f.url,
      requestId: f.requestId,
      statusCode: f.statusCode,
      token: f.token,
      error: f.error,
    ),
  ),

  // The user behind the session no longer exists on the backend.
  FailureRule(
    status: 404,
    code: 'user_not_found',
    build: (f) => UserNotFoundException(url: f.url, requestId: f.requestId, statusCode: f.statusCode),
  ),

  // The self-care password expired, so the caller can say so instead of
  // reporting something unactionable.
  FailureRule(
    code: 'password_change_required',
    build: (f) => PasswordChangeRequiredException(
      url: f.url,
      requestId: f.requestId,
      statusCode: f.statusCode,
      token: f.token,
      error: f.error,
    ),
  ),
];

/// Voicemail is switched off for this subscriber.
///
/// Declared by the voicemail endpoints rather than globally: only the mailbox
/// calls can produce it, and a generic layer checking every response for it is
/// a fact about one feature living in the transport.
final FailureRule voicemailNotConfiguredRule = FailureRule(
  code: 'voicemail_not_configured',
  build: (f) => VoicemailNotConfiguredException(
    url: f.url,
    requestId: f.requestId,
    statusCode: f.statusCode,
    token: f.token,
    error: f.error,
  ),
);

/// This endpoint reports a missing subject as a plain 404, with no code to read.
///
/// Two endpoints answer that way, and both mean the account rather than the
/// thing being fetched, so the rule is theirs rather than everyone's.
final FailureRule userNotFoundOn404Rule = FailureRule(
  status: 404,
  build: (f) => UserNotFoundException(url: f.url, requestId: f.requestId, statusCode: f.statusCode),
);
