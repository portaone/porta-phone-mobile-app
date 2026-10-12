/// The request of the login flow a failure came out of.
///
/// Named by the request, not by what happens to be typed into the forms: a
/// field left filled on another tab says nothing about where an error is from.
enum LoginOperation {
  systemInfo('LoginSystemInfoRequested'),
  coreUrlAssign('LoginCoreUrlAssignSubmitted'),
  otpRequest('LoginOtpSigninRequestSubmitted'),
  otpVerify('LoginOtpSigninVerifySubmitted'),
  passwordSignin('LoginPasswordSigninSubmitted'),
  qrSignin('LoginQrSigninSubmitted'),
  signup('LoginSignupRequestSubmitted'),
  signupVerify('LoginSignupVerifySubmitted'),
  deviceLimitSessionPicked('LoginDeviceLimitSessionPicked');

  const LoginOperation(this.reportReason);

  /// What an unexpected failure of this request is reported under.
  final String reportReason;
}
