part of 'login_cubit.dart';

typedef SessionOtpProvisionalWithDateTime = (SessionOtpProvisional, DateTime);

@freezed
class LoginState with _$LoginState {
  const LoginState({
    this.processing = false,
    this.mode,
    this.coreUrl,
    this.tenantId,
    this.systemInfo,
    this.supportedLoginTypes,
    this.otpSigninSessionOtpProvisionalWithDateTime,
    this.passwordSigninPasswordInputObscureText = true,
    this.signupSessionOtpProvisionalWithDateTime,
    this.token,
    this.userId,
    // Used to represent an embedded launch page or a login type within tabbed navigation
    this.embedded,
    // Extras and callback data that returned from the embedded page
    this.embeddedExtras,
    this.embeddedCallbackData,
    this.embeddedRequestError,
    this.embeddedSignupFailure,
    this.coreUrlInput = const UrlInput.pure(),
    this.coreUrlAssignError,
    this.otpSigninUserRefInput = const UserRefInput.pure(),
    this.otpSigninCodeInput = const CodeInput.pure(),
    this.passwordSigninUserRefInput = const UserRefInput.pure(),
    this.passwordSigninPasswordInput = const PasswordInput.pure(),
    this.signupEmailInput = const EmailInput.pure(),
    this.signupCodeInput = const CodeInput.pure(),
    this.pendingLogin,
    this.pendingLoginRevokingSessionId,
    this.pendingLoginCallbackData,
  });

  final bool processing;

  final LoginMode? mode;

  final String? coreUrl;

  final String? tenantId;

  final WebtritSystemInfo? systemInfo;

  final List<LoginType>? supportedLoginTypes;

  final SessionOtpProvisionalWithDateTime? otpSigninSessionOtpProvisionalWithDateTime;

  final bool passwordSigninPasswordInputObscureText;

  final SessionOtpProvisionalWithDateTime? signupSessionOtpProvisionalWithDateTime;

  final String? token;

  final String? userId;

  final EmbeddedData? embedded;

  final Map<String, dynamic>? embeddedExtras;

  final Map<String, dynamic>? embeddedCallbackData;

  final Object? embeddedRequestError;

  /// The last signup of the embedded page that ended without a session, until the page asks
  /// again. The page waits for an answer it cannot get by itself; the screen answers it from this.
  final EmbeddedSignupFailure? embeddedSignupFailure;

  final UrlInput coreUrlInput;

  /// Failure of the last Core URL submit meaning the entered address does not
  /// host a reachable Cloud Backend; rendered inline under the URL field.
  final Object? coreUrlAssignError;

  final UserRefInput otpSigninUserRefInput;

  final CodeInput otpSigninCodeInput;

  final UserRefInput passwordSigninUserRefInput;

  final PasswordInput passwordSigninPasswordInput;

  final EmailInput signupEmailInput;

  final CodeInput signupCodeInput;

  /// The login the backend is holding back until one of the account's devices
  /// is signed out. The device limit screen is shown for as long as it is set.
  final PendingLogin? pendingLogin;

  /// The session being signed out to finish [pendingLogin], while that request
  /// is out.
  final String? pendingLoginRevokingSessionId;

  /// The request an embedded page asked to be made after the login that is now
  /// [pendingLogin]. It waits with that login and goes with it: a login started
  /// another way has none.
  final Map<String, dynamic>? pendingLoginCallbackData;

  /// OTP login identifiers supported by the backend adapter.
  ///
  /// Derived from `system-info` (`adapter.custom.otp_login_identifiers`).
  /// Falls back to all known identifiers when the backend does not advertise
  /// the field (e.g. older cores), preserving the legacy "phone or email" UI.
  List<OtpSigninIdentifier> get otpSigninIdentifiers {
    final identifiers = OtpSigninIdentifier.fromValues(systemInfo?.adapter?.otpLoginIdentifiers ?? const []);
    return identifiers.isNotEmpty ? identifiers : OtpSigninIdentifier.values;
  }
}
