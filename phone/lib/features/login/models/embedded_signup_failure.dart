/// Why a signup that an embedded page asked for ended without a session.
enum EmbeddedSignupFailureReason {
  /// Refused because the account or its customer is on as many devices as it is allowed.
  deviceLimit('device_limit'),

  /// Refused because the account ran out of new devices for the period.
  deviceSwitchLimit('device_switch_limit'),

  /// The request failed: an error answer, no connection, or an answer the app cannot use.
  failed('request_failed'),

  /// The backend and this build do not fit, so there is nothing to sign in to.
  unsupportedBackend('unsupported_backend');

  const EmbeddedSignupFailureReason(this.code);

  /// The value an embedded page receives for this reason; part of the page contract
  /// (`docs/reference/custom_login.md`), so it never changes once released.
  final String code;
}

/// A signup that an embedded page asked for ended without a session.
///
/// The page put itself into a waiting state when it posted the signup and cannot learn the
/// outcome on its own, so this is what the app answers the page from. Each failure is a new object
/// and is compared by identity: two refusals in a row are two failures, each answered once.
class EmbeddedSignupFailure {
  EmbeddedSignupFailure(this.reason);

  final EmbeddedSignupFailureReason reason;

  @override
  String toString() => 'EmbeddedSignupFailure(${reason.name})';
}
