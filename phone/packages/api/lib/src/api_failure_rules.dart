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
  const FailureRule({this.status, this.code, this.when, required this.build});

  /// The status this rule answers to; null matches any.
  final int? status;

  /// The backend error code this rule answers to; null matches any.
  ///
  /// A rule with neither a status, a code nor a [when] matches every failure,
  /// which is only ever what an endpoint wants, never a default.
  final String? code;

  /// Anything the other two cannot say - a class of statuses rather than one.
  ///
  /// Kept to that: a rule is a declaration, and a predicate that reads the body
  /// or the url would be a branch in the transport wearing a rule's clothes.
  final bool Function(FailureContext failure)? when;

  final RequestFailure Function(FailureContext failure) build;

  bool matches(FailureContext failure) =>
      (status == null || status == failure.statusCode) &&
      (code == null || code == failure.code) &&
      (when == null || when!(failure));
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

  // Anything the backend answered for with its own failure. Last in the list on
  // purpose: a 5xx that some endpoint or code recognises is that answer first,
  // and only what nobody claimed arrives here.
  FailureRule(
    when: (f) => f.statusCode >= 500 && f.statusCode < 600,
    build: (f) => ServerFailureException(
      url: f.url,
      requestId: f.requestId,
      statusCode: f.statusCode,
      token: f.token,
      error: f.error,
      rawBody: f.rawBody,
    ),
  ),
];

/// A message the mailbox no longer has.
///
/// Declared by the voicemail endpoints, and by the error code rather than by
/// the status: these calls are optional, so a bare 404 is how a deployment says
/// it has no such route at all. The code is what tells "this message is gone"
/// from "this backend cannot do this".
final FailureRule voicemailMessageGoneRule = FailureRule(
  code: 'message_not_found',
  build: (f) => VoicemailMessageGoneException(
    url: f.url,
    requestId: f.requestId,
    statusCode: f.statusCode,
    token: f.token,
    error: f.error,
  ),
);

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

/// Creating a session was refused because the credentials are wrong.
///
/// Declared on that endpoint rather than globally: everywhere else a 401 is
/// about the session that carried the request, and this is the one call made
/// without a session, so the status can only mean the login and password were
/// refused. It reads the status alone because the adapters disagree on the code
/// and the PortaSwitch one sends none - and a failure no rule recognises is a
/// failure nobody can word for the user.
final FailureRule incorrectCredentialsOn401Rule = FailureRule(
  status: 401,
  build: (f) =>
      IncorrectCredentialsException(url: f.url, requestId: f.requestId, statusCode: f.statusCode, error: f.error),
);

/// This endpoint reports a missing subject as a plain 404, with no code to read.
///
/// Two endpoints answer that way, and both mean the account rather than the
/// thing being fetched, so the rule is theirs rather than everyone's.
final FailureRule userNotFoundOn404Rule = FailureRule(
  status: 404,
  build: (f) => UserNotFoundException(url: f.url, requestId: f.requestId, statusCode: f.statusCode),
);

/// The three refusals that belong to forwarding a voicemail on.
///
/// Forwarding is the one call that writes into another subscriber's storage, so
/// it is the one with refusals of its own, and each asks something different of
/// the person: pick someone else, this recording cannot travel, or wait for that
/// colleague to clear space. The codes are declared here rather than globally
/// because they mean this only on this route - a generic-sounding
/// `attachment_too_large` from any other endpoint that grew an attachment would
/// otherwise start arriving as a forwarding error.
final List<FailureRule> voicemailForwardRules = [
  FailureRule(
    code: 'recipient_not_found',
    build: (f) => VoicemailForwardRecipientNotFoundException(
      url: f.url,
      requestId: f.requestId,
      statusCode: f.statusCode,
      token: f.token,
      error: f.error,
    ),
  ),
  FailureRule(
    code: 'attachment_too_large',
    build: (f) => VoicemailForwardAttachmentTooLargeException(
      url: f.url,
      requestId: f.requestId,
      statusCode: f.statusCode,
      token: f.token,
      error: f.error,
    ),
  ),
  FailureRule(
    code: 'recipient_forward_limit_reached',
    build: (f) => VoicemailForwardLimitReachedException(
      url: f.url,
      requestId: f.requestId,
      statusCode: f.statusCode,
      token: f.token,
      error: f.error,
    ),
  ),
];
