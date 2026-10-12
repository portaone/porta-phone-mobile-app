import 'package:api/api.dart';

import 'package:webtrit_phone/app/notifications/notifications.dart';

import 'login_operation.dart';
import 'notifications.dart';
import 'otp_signin_identifier.dart';

/// The message a refusal the login flow knows is told to the user with, or null
/// for a failure it has no wording for.
///
/// [otpSigninIdentifiers] are the identifiers the backend accepts for a
/// one-time code, named in the message when that is the request refused.
Notification? loginErrorNotification(
  RequestFailure error, {
  required LoginOperation operation,
  required List<OtpSigninIdentifier> otpSigninIdentifiers,
}) {
  if (error is UserNotFoundException) return const LoginUserNotFoundNotification();

  final readable = switch (error.error?.code) {
    'otp_not_found' => const LoginOtpNotFoundNotification(),
    'incorrect_otp_code' => const LoginIncorrectOtpCodeNotification(),
    'otp_expired' => const LoginOtpExpiredNotification(),
    'otp_verification_attempts_exceeded' => const LoginOtpVerificationAttemptsExceededNotification(),
    'otp_already_verified' => const LoginOtpAlreadyVerifiedNotification(),
    'phone_not_found' => const LoginPhoneNotFoundNotification(),
    'incorrect_credentials' => const LoginIncorrectCredentialsNotification(),
    'user_not_found' => const LoginUserNotFoundNotification(),
    'unconfigured_bundle_id' => const LoginUnconfiguredBundleIdNotification(),
    'addon_required' => const LoginAddonRequiredNotification(),
    'validation_error' => const LoginValidationErrorNotification(),
    'parameters_apply_issue' => const LoginParametersApplyIssueNotification(),
    'empty_email' => const LoginEmptyEmailNotification(),
    // The identifier-specific wording only makes sense for the request of a
    // one-time code (the code is declared on otp-create only, but signup
    // passes adapter 422 bodies through verbatim).
    'delivery_channel_unspecified' => LoginDeliveryChannelUnspecifiedNotification(
      operation == LoginOperation.otpRequest ? otpSigninIdentifiers : const [],
    ),
    _ => null,
  };
  if (readable != null) return readable;

  // Read after the codes so a backend that does name the refusal keeps its
  // own wording; this one covers the adapters that answer a wrong login or
  // password with a bare 401 and no code at all. A mistyped password is the
  // person's own doing, so it is worth telling them and not worth a
  // Crashlytics record.
  if (error is IncorrectCredentialsException) return const LoginIncorrectCredentialsNotification();

  return null;
}
