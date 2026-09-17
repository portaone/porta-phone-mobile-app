import 'dart:io';

import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/app/notifications/models/notification.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../extensions/otp_signin_identifier.dart';
import 'otp_signin_identifier.dart';

@Deprecated.instantiate('will be removed, (see [app/notifications/models/notification.dart] for details)')
final class LoginErrorNotification extends DefaultErrorNotification {
  LoginErrorNotification(super.error);

  @override
  String l10n(BuildContext context) {
    final error = this.error;
    if (error is RequestFailure) {
      switch (error.error?.code) {
        case 'parameters_apply_issue':
          return context.l10n.login_RequestFailureParametersApplyIssueError;
        // sessionOtpRequest
        case 'unconfigured_bundle_id':
          return context.l10n.login_RequestFailureUnconfiguredBundleIdError;
        case 'phone_not_found':
          return context.l10n.login_RequestFailurePhoneNotFoundError;
        case 'empty_email':
          return context.l10n.login_RequestFailureEmptyEmailError;
        case 'delivery_channel_unspecified':
          return context.l10n.login_RequestFailureDeliveryChannelUnspecifiedError;
        case 'validation_error':
          return context.l10n.login_RequestFailureIdentifierIsNotValid;
        // sessionOtpVerify
        case 'otp_already_verified':
          return context.l10n.login_RequestFailureOtpAlreadyVerifiedError;
        case 'otp_verification_attempts_exceeded':
          return context.l10n.login_RequestFailureOtpVerificationAttemptsExceededError;
        case 'otp_expired':
          return context.l10n.login_RequestFailureOtpExpiredError;
        case 'incorrect_otp_code':
          return context.l10n.login_RequestFailureIncorrectOtpCodeError;
        case 'otp_not_found':
          return context.l10n.login_RequestFailureOtpNotFoundError;
      }
    }
    return super.l10n(context);
  }
}

final class LoginOtpNotFoundNotification extends MessageNotification {
  const LoginOtpNotFoundNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.login_RequestFailureOtpNotFoundError;
  }
}

final class LoginIncorrectOtpCodeNotification extends MessageNotification {
  const LoginIncorrectOtpCodeNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.login_RequestFailureIncorrectOtpCodeError;
  }
}

final class LoginOtpExpiredNotification extends MessageNotification {
  const LoginOtpExpiredNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.login_RequestFailureOtpExpiredError;
  }
}

final class LoginOtpVerificationAttemptsExceededNotification extends MessageNotification {
  const LoginOtpVerificationAttemptsExceededNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.login_RequestFailureOtpVerificationAttemptsExceededError;
  }
}

final class LoginOtpAlreadyVerifiedNotification extends MessageNotification {
  const LoginOtpAlreadyVerifiedNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.login_RequestFailureOtpAlreadyVerifiedError;
  }
}

final class LoginPhoneNotFoundNotification extends MessageNotification {
  const LoginPhoneNotFoundNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.login_RequestFailurePhoneNotFoundError;
  }
}

final class LoginIncorrectCredentialsNotification extends MessageNotification {
  const LoginIncorrectCredentialsNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.login_RequestFailureIncorrectCredentialsError;
  }
}

/// The login failure the app has no particular wording for.
///
/// It exists so that an attempt never ends in silence: a form that merely stops
/// spinning leaves the person retyping a password that was never the problem.
/// [defaultErrorL10n] turns transport failures and bare HTTP statuses into
/// something readable, which is all that can honestly be said about a failure
/// the backend did not name.
final class LoginUnexpectedErrorNotification extends MessageNotification {
  const LoginUnexpectedErrorNotification(this.error);

  final Object error;

  @override
  String l10n(BuildContext context) => defaultErrorL10n(context, error);

  /// The snackbar can only name the kind of failure; behind this action are the
  /// fields support actually asks for - status, request id, the backend's own
  /// message - on a screen that copies and shares them. Offered only for the
  /// errors that carry such fields: on anything else the action would open a
  /// screen with nothing on it.
  @override
  SnackBarAction? action(BuildContext context) {
    final error = this.error;
    final fields = switch (error) {
      RequestFailure() => error.errorFields(context),
      SocketException() => error.errorFields(context),
      _ => null,
    };
    if (fields == null) return null;

    final title = l10n(context);
    return SnackBarAction(
      label: context.l10n.default_ErrorDetails,
      onPressed: () => context.router.push(ErrorDetailsScreenPageRoute(title: title, fields: fields)),
    );
  }
}

final class LoginUserNotFoundNotification extends MessageNotification {
  const LoginUserNotFoundNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.login_RequestFailureUserNotFoundError;
  }
}

final class LoginUnconfiguredBundleIdNotification extends MessageNotification {
  const LoginUnconfiguredBundleIdNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.login_RequestFailureUnconfiguredBundleIdError;
  }
}

final class LoginValidationErrorNotification extends MessageNotification {
  const LoginValidationErrorNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.login_RequestFailureIdentifierIsNotValid;
  }
}

final class LoginParametersApplyIssueNotification extends MessageNotification {
  const LoginParametersApplyIssueNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.login_RequestFailureParametersApplyIssueError;
  }
}

final class LoginEmptyEmailNotification extends MessageNotification {
  const LoginEmptyEmailNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.login_RequestFailureEmptyEmailError;
  }
}

final class LoginDeliveryChannelUnspecifiedNotification extends MessageNotification {
  const LoginDeliveryChannelUnspecifiedNotification([this.identifiers = const []]);

  /// Advertised OTP sign-in identifiers at the moment of the failure; an empty
  /// list keeps the message generic (e.g. when the error did not come from the
  /// OTP sign-in form).
  final List<OtpSigninIdentifier> identifiers;

  @override
  String l10n(BuildContext context) {
    return identifiers.deliveryChannelUnspecifiedMessage(context);
  }
}

final class SupportedLoginTypeMissedErrorNotification extends MessageNotification {
  const SupportedLoginTypeMissedErrorNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.login_SupportedLoginTypeMissedExceptionError;
  }
}

final class CoreVersionUnsupportedErrorNotification extends MessageNotification {
  const CoreVersionUnsupportedErrorNotification(this.actual, this.supportedConstraint);

  final String actual;
  final String supportedConstraint;

  @override
  String l10n(BuildContext context) {
    return context.l10n.login_CoreVersionUnsupportedExceptionError(actual, supportedConstraint);
  }
}

final class AppVersionUnsupportedErrorNotification extends MessageNotification {
  const AppVersionUnsupportedErrorNotification({
    required this.appVersion,
    required this.minSupported,
    required this.storeVersion,
  });

  /// Internal app_version the gate compared against [minSupported].
  final String appVersion;
  final String minSupported;

  /// Per-client build version+code of the installed build (versionName +
  /// versionCode, e.g. "4.4.9+449000002"); shown in parentheses so users and
  /// support can match the numbers from the store console (debug/sideload
  /// builds carry the literal 0.0.0+0 placeholder).
  final String storeVersion;

  @override
  String l10n(BuildContext context) {
    final actual = context.l10n.main_AppUpdateRequiredDialog_currentVersionValue(storeVersion, appVersion);
    return context.l10n.login_AppVersionUnsupportedExceptionError(actual, minSupported);
  }
}
