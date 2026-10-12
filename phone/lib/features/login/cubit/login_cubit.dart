import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/app/notifications/notifications.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/crashlytics_utils.dart';

import '../login.dart';

part 'login_cubit.freezed.dart';

part 'login_state.dart';

typedef LoginSuccessCallback = void Function(Session session, WebtritSystemInfo systemInfo);

final _logger = Logger('LoginCubit');

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({
    required this.authRepository,
    required this.notificationsBloc,
    required this.appInfo,
    required this.packageInfo,
    required this.appCompatibilityResolver,
    required this.onLoginSuccess,
    this.signinOrder = const [],
    QrSigninConfig? qrSigninConfig,
  }) : qrSigninConfig = qrSigninConfig ?? QrSigninConfig.disabled,
       super(const LoginState());

  final AuthRepository authRepository;

  final LoginSuccessCallback onLoginSuccess;

  final NotificationsBloc notificationsBloc;

  final AppInfo appInfo;

  final PackageInfo packageInfo;

  final AppCompatibilityResolver appCompatibilityResolver;

  /// Configured order of the sign-in tabs, by login type name (from app config).
  final List<String> signinOrder;

  /// Configuration of the QR-code sign-in tab (from app config).
  final QrSigninConfig qrSigninConfig;

  // Environment getters
  String? get coreUrlFromEnvironment => EnvironmentConfig.CORE_URL;

  String? get credentialsRequestUrl => EnvironmentConfig.APP_CREDENTIALS_REQUEST_URL;

  String? get demoCoreUrlFromEnvironment => EnvironmentConfig.DEMO_CORE_URL;

  String get coreVersionConstraint => EnvironmentConfig.CORE_VERSION_CONSTRAINT;

  Version get appVersion => appInfo.version;

  String get defaultTenantId => '';

  bool get isDemoModeEnabled => coreUrlFromEnvironment == null;

  bool get isCredentialsRequestUrlEnabled => credentialsRequestUrl != null;

  /// Finishes a login the backend answered with a session: the one place every
  /// sign-in ends in, called once for the token it was given.
  ///
  /// The session and the system information go to [onLoginSuccess] together,
  /// so the parent persists them atomically before the authenticated lifecycle
  /// starts. `processing` is left set, to hold the widgets as they are while
  /// the app navigates away.
  ///
  /// The tenant of the answer is the truth for a finished session; a backend
  /// that names none leaves the login in [requestTenantId], the tenant the
  /// request was made in.
  void _finishLogin(SessionToken sessionToken, {required String? requestTenantId}) {
    final systemInfo = state.systemInfo!;
    final tenantId = sessionToken.tenantId ?? requestTenantId ?? defaultTenantId;
    // Use an empty user ID as a fallback for outdated core versions that do not support this field.
    final userId = sessionToken.userId ?? '';

    emit(state.copyWith(tenantId: tenantId, token: sessionToken.token, userId: userId));

    final session = Session(coreUrl: state.coreUrl!, tenantId: tenantId, token: sessionToken.token, userId: userId);
    onLoginSuccess(session, systemInfo);
  }

  Future<void> _processSystemInfo(
    String coreUrl,
    String tenantId, {
    bool demo = false,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    emit(state.copyWith(processing: true));

    try {
      final systemInfo = await _loadAndValidateSystemInfo(coreUrl, tenantId);
      if (systemInfo == null) {
        emit(state.copyWith(processing: false));
        return;
      }

      final supportedLoginTypes = resolveLoginTypes(
        systemInfo.adapter?.supported ?? const [],
        qrEnabled: qrSigninConfig.enabled,
        orderConfig: signinOrder,
        demo: demo,
      );

      if (supportedLoginTypes.isEmpty) {
        notificationsBloc.add(const NotificationsSubmitted(SupportedLoginTypeMissedErrorNotification()));
        emit(state.copyWith(processing: false));
        return;
      }

      emit(
        state.copyWith(
          processing: false,
          coreUrl: coreUrl,
          tenantId: tenantId,
          supportedLoginTypes: supportedLoginTypes,
          systemInfo: systemInfo,
        ),
      );
    } catch (e, s) {
      if (onError != null) {
        onError(e, s);
      } else {
        handleError(e, s, LoginOperation.systemInfo);
      }
      emit(state.copyWith(processing: false));
    }
  }

  Future<WebtritSystemInfo?> _loadAndValidateSystemInfo(String coreUrl, String tenantId) async {
    final systemInfo = await authRepository.getSystemInfo(coreUrl, tenantId);

    // Shared version gate (see [AppCompatibility]). Aborting here means no
    // session is created and signaling is never connected for an unsupported build.
    final compatibility = appCompatibilityResolver.resolve(
      systemInfo: systemInfo,
      appVersion: appVersion,
      coreVersionConstraint: coreVersionConstraint,
    );
    switch (compatibility) {
      case CoreVersionUnsupported(:final coreVersion, :final constraint):
        final notification = CoreVersionUnsupportedErrorNotification(coreVersion.toString(), constraint.toString());
        notificationsBloc.add(NotificationsSubmitted(notification));
        return null;
      case AppVersionTooOld(:final appVersion, :final minSupportedVersion):
        final notification = AppVersionUnsupportedErrorNotification(
          appVersion: appVersion.toString(),
          minSupported: minSupportedVersion.toString(),
          storeVersion: packageInfo.fullVersion,
        );
        notificationsBloc.add(NotificationsSubmitted(notification));
        return null;
      case AppCompatible():
        return systemInfo;
    }
  }

  // LoginModeSelect

  void loginModeSelectSubmitted(LoginMode mode) async {
    emit(state.copyWith(mode: mode));

    final demo = mode == LoginMode.demoCore;
    final coreUrl = demo ? demoCoreUrlFromEnvironment : coreUrlFromEnvironment;

    if (coreUrl != null) await _processSystemInfo(coreUrl, defaultTenantId, demo: demo);
  }

  void setEmbedded(EmbeddedData embedded) {
    emit(
      state.copyWith(
        embedded: embedded,
        coreUrl: isDemoModeEnabled ? demoCoreUrlFromEnvironment : coreUrlFromEnvironment,
      ),
    );
  }

  // LoginCoreUrlAssign

  void coreUrlInputChanged(String value) {
    emit(state.copyWith(coreUrlInput: UrlInput.dirty(value), coreUrlAssignError: null));
  }

  void loginCoreUrlAssignSubmitted() async {
    if (state.processing || !state.coreUrlInput.isValid) {
      return;
    }

    var coreUrlInputValue = state.coreUrlInput.value;
    if (!coreUrlInputValue.startsWith(RegExp(r'(https|http)://'))) {
      coreUrlInputValue = 'https://$coreUrlInputValue';
    }

    emit(state.copyWith(coreUrlAssignError: null));

    await _processSystemInfo(
      coreUrlInputValue,
      defaultTenantId,
      onError: (error, stackTrace) {
        // On this step an unreachable or unrecognised address is an expected
        // user mistake: surface it inline under the URL field instead of the
        // generic error path (which stays silent for such failures).
        if (_isCoreUnreachableError(error)) {
          _logger.warning('Core URL assign failed: $error');
          emit(state.copyWith(coreUrlAssignError: error));
        } else {
          handleError(error, stackTrace, LoginOperation.coreUrlAssign);
        }
      },
    );
  }

  /// Whether [error] means the entered address does not host a reachable
  /// Cloud Backend: a transport failure, a non-JSON payload, or an HTTP
  /// error without a structured error body (e.g. a bare ingress 404
  /// while the backend restarts).
  static bool _isCoreUnreachableError(Object error) {
    if (error is RequestFailure) return error.error == null;
    return error is SocketException ||
        error is http.ClientException ||
        error is TimeoutException ||
        error is FormatException;
  }

  void loginCoreUrlAssignBack() async {
    emit(state.copyWith(mode: null, coreUrlInput: const UrlInput.pure(), coreUrlAssignError: null));
  }

  void credentialsRequestUrlAssignBack() async {
    emit(state.copyWith(mode: null));
  }

  void embeddedPageAssignBack() async {
    emit(state.copyWith(embedded: null));
  }

  // LoginSwitch

  void loginSwitchBack() async {
    emit(
      state.copyWith(
        mode: state.mode == LoginMode.customCore ? state.mode : null,
        coreUrl: null,
        tenantId: null,
        supportedLoginTypes: null,
        embedded: null,
        otpSigninSessionOtpProvisionalWithDateTime: null,
        passwordSigninPasswordInputObscureText: true,
        signupSessionOtpProvisionalWithDateTime: null,
        otpSigninUserRefInput: const UserRefInput.pure(),
        otpSigninCodeInput: const CodeInput.pure(),
        passwordSigninUserRefInput: const UserRefInput.pure(),
        passwordSigninPasswordInput: const PasswordInput.pure(),
        signupEmailInput: const EmailInput.pure(),
        signupCodeInput: const CodeInput.pure(),
      ),
    );
  }

  // LoginOtpSigninRequest

  void otpSigninUserRefInputChanged(String value) {
    emit(state.copyWith(otpSigninUserRefInput: UserRefInput.dirty(value)));
  }

  void loginOptSigninRequestSubmitted() async {
    if (state.processing || !state.otpSigninUserRefInput.isValid) {
      return;
    }

    emit(state.copyWith(processing: true));

    try {
      final sessionOtpProvisional = await authRepository.requestOtp(
        coreUrl: state.coreUrl!,
        tenantId: state.tenantId!,
        userRef: state.otpSigninUserRefInput.value,
      );

      emit(
        state.copyWith(
          processing: false,
          otpSigninSessionOtpProvisionalWithDateTime: (sessionOtpProvisional, DateTime.now()),
        ),
      );
    } catch (e, s) {
      emit(state.copyWith(processing: false));

      handleError(e, s, LoginOperation.otpRequest);
    }
  }

  // LoginOtpSigninVerify

  void otpSigninCodeInputChanged(String value) {
    emit(state.copyWith(otpSigninCodeInput: CodeInput.dirty(value)));
  }

  void loginOptSigninVerifySubmitted() async {
    if (state.processing || !state.otpSigninCodeInput.isValid) {
      return;
    }

    emit(state.copyWith(processing: true));
    try {
      final sessionToken = await authRepository.verifyOtp(
        coreUrl: state.coreUrl!,
        tenantId: state.tenantId!,
        sessionOtpProvisional: state.otpSigninSessionOtpProvisionalWithDateTime!.$1,
        code: state.otpSigninCodeInput.value,
      );

      _finishLogin(sessionToken, requestTenantId: state.tenantId);
    } catch (e, s) {
      emit(state.copyWith(processing: false));
      if (_isDeviceLimitRefusal(e)) loginOptSigninVerifyBack();

      handleError(e, s, LoginOperation.otpVerify);
    }
  }

  void loginOptSigninVerifyBack() async {
    emit(state.copyWith(otpSigninSessionOtpProvisionalWithDateTime: null, otpSigninCodeInput: const CodeInput.pure()));
  }

  void loginOptSigninVerifyRepeat() {
    loginOptSigninRequestSubmitted();
  }

  // LoginPasswordSignin

  void passwordSigninUserRefInputChanged(String value) {
    emit(state.copyWith(passwordSigninUserRefInput: UserRefInput.dirty(value)));
  }

  void passwordSigninPasswordInputChanged(String value) {
    emit(state.copyWith(passwordSigninPasswordInput: PasswordInput.dirty(value)));
  }

  void passwordSigninPasswordInputObscureTextToggled() {
    emit(state.copyWith(passwordSigninPasswordInputObscureText: !state.passwordSigninPasswordInputObscureText));
  }

  void loginPasswordSigninSubmitted() async {
    if (!state.passwordSigninUserRefInput.isValid || !state.passwordSigninPasswordInput.isValid) {
      return;
    }

    await _submitPasswordLogin(
      userRef: state.passwordSigninUserRefInput.value,
      password: state.passwordSigninPasswordInput.value,
      operation: LoginOperation.passwordSignin,
    );
  }

  // LoginQrSignin

  /// Signs in with credentials decoded from a scanned QR code.
  ///
  /// Follows the same session path as [loginPasswordSigninSubmitted]; the
  /// credentials come from the scanner instead of the input fields. Completes
  /// when the attempt is over so the caller can resume scanning on failure.
  Future<void> loginQrSigninSubmitted({required String userRef, required String password}) {
    return _submitPasswordLogin(userRef: userRef, password: password, operation: LoginOperation.qrSignin);
  }

  /// Shared session-creation path of the password-based sign-ins (manual entry
  /// and scanned QR credentials).
  Future<void> _submitPasswordLogin({
    required String userRef,
    required String password,
    required LoginOperation operation,
  }) async {
    // A login already left waiting is answered on the device limit screen; a
    // code still in front of the camera under it must not start another one.
    if (state.processing || state.pendingLogin != null) return;

    emit(state.copyWith(processing: true));

    try {
      final sessionToken = await authRepository.login(
        coreUrl: state.coreUrl!,
        tenantId: state.tenantId!,
        userRef: userRef,
        password: password,
      );

      _finishLogin(sessionToken, requestTenantId: state.tenantId);
    } catch (e, s) {
      emit(state.copyWith(processing: false));

      handleError(e, s, operation);
    }
  }

  void loginPasswordSigninBack() async {
    emit(
      state.copyWith(
        passwordSigninUserRefInput: const UserRefInput.pure(),
        passwordSigninPasswordInput: const PasswordInput.pure(),
      ),
    );
  }

  // LoginSignupRequest

  void signupEmailInputChanged(String value) {
    emit(state.copyWith(signupEmailInput: EmailInput.dirty(value)));
  }

  /// Performs a custom signup flow initiated from an embedded page.
  ///
  /// Derives the tenant once (from extras -> state -> default) and reuses it for:
  ///   - `POST /user` request
  ///   - systemInfo loading (if required)
  ///   - OTP verification via `_applyLoginResult`
  ///
  /// Guarantees that all signup-related requests share the same tenant context.
  /// This avoids OTP verification mismatches across tenants.
  Future<void> loginCustomSignupRequest(
    Map<String, dynamic>? extras,
    Map<String, dynamic>? embeddedCallbackData,
  ) async {
    emit(
      state.copyWith(
        processing: true,
        embeddedExtras: extras,
        embeddedCallbackData: embeddedCallbackData,
        embeddedRequestError: null,
      ),
    );

    try {
      final tenantId = extras?['tenant_id'] ?? state.tenantId ?? defaultTenantId;

      // In cases where the embedded page acts as the launch welcome screen,
      // the systemInfo might not be loaded yet. Perform an additional check
      // and attempt to load it if necessary.
      final result = await authRepository.signup(coreUrl: state.coreUrl!, tenantId: tenantId, extraPayload: extras);

      if (state.systemInfo == null) {
        final systemInfo = await _loadAndValidateSystemInfo(state.coreUrl!, tenantId);
        if (systemInfo == null) {
          // The backend and this build do not fit, and the user has been told:
          // there is no session to enter, whatever the request came to.
          emit(state.copyWith(processing: false));
          return;
        }
        emit(state.copyWith(systemInfo: systemInfo, processing: false));
      }

      // Executes optional post-login callback request if provided by embedded flow.
      if (result is SessionToken) {
        final postRequest = embeddedCallbackData != null ? RawHttpRequest.fromJson(embeddedCallbackData) : null;
        await authRepository.executePostLoginHttpRequest(postRequest);
      }

      // Applies login result and ensures tenant consistency.
      _applyLoginResult(result, propagatedTenantId: tenantId);
    } catch (e, s) {
      handleError(e, s, LoginOperation.signup);
      // The device limits are told to the user by the cubit itself - on the
      // device limit screen or in a message - so the error dialog of the
      // embedded page, which words a failed request, stays away.
      emit(
        state.copyWith(
          processing: false,
          embeddedRequestError: _isDeviceLimitRefusal(e) ? null : e,
          // The call the page asked for waits with the login it belongs to.
          pendingLoginCallbackData: e is LoginDeviceLimitReached && state.pendingLogin != null
              ? embeddedCallbackData
              : state.pendingLoginCallbackData,
        ),
      );
    }
  }

  void clearEmbeddedRequestError() {
    emit(state.copyWith(embeddedRequestError: null));
  }

  /// Handles standard (non-embedded) signup flow.
  ///
  /// Ensures tenant consistency by reusing the tenant stored in `state` for:
  /// - `POST /user`
  /// - subsequent OTP verification (propagated via `_applyLoginResult`)
  ///
  /// Early-exits if already processing or email is invalid. Emits errors and
  /// resets `processing` on failure.
  void loginSignupRequestSubmitted() async {
    if (state.processing || !state.signupEmailInput.isValid) {
      return;
    }

    emit(state.copyWith(processing: true));

    try {
      final result = await authRepository.signup(
        coreUrl: state.coreUrl!,
        tenantId: state.tenantId!,
        email: state.signupEmailInput.value,
      );

      _applyLoginResult(result, propagatedTenantId: state.tenantId);
    } catch (e, s) {
      handleError(e, s, LoginOperation.signup);
      emit(state.copyWith(processing: false));
    }
  }

  /// Applies the login result while maintaining tenant consistency across the OTP flow.
  ///
  /// Ensures that both `POST /user` and `otp-verify` use the same tenant context.
  /// In embedded flows, the tenant may come from the embedded extras.
  /// Fallback order:
  ///   1. Explicit tenantId argument (propagated from POST /user request)
  ///   2. Tenant from the result object
  ///   3. Default tenant
  ///
  /// This prevents OTP verification issues when the backend stores OTPs under
  /// a default tenant ("") if tenantId was not provided during creation.
  void _applyLoginResult(SessionResult result, {String? propagatedTenantId}) {
    if (result is SessionOtpProvisional) {
      emit(
        state.copyWith(
          processing: false,
          signupSessionOtpProvisionalWithDateTime: (result, DateTime.now()),
          // Uses the same tenant as POST /user when provided; falls back safely otherwise.
          tenantId: propagatedTenantId ?? result.tenantId ?? defaultTenantId,
        ),
      );
    } else if (result is SessionToken) {
      _finishLogin(result, requestTenantId: propagatedTenantId);
    } else {
      throw UnimplementedError('Unexpected login result type');
    }
  }

  // LoginSignupVerify

  void signupCodeInputChanged(String value) {
    emit(state.copyWith(signupCodeInput: CodeInput.dirty(value)));
  }

  void loginSignupVerifySubmitted() async {
    if (state.processing || !state.signupCodeInput.isValid) {
      return;
    }

    emit(state.copyWith(processing: true));

    try {
      final sessionToken = await authRepository.verifyOtp(
        coreUrl: state.coreUrl!,
        tenantId: state.tenantId!,
        sessionOtpProvisional: state.signupSessionOtpProvisionalWithDateTime!.$1,
        code: state.signupCodeInput.value,
      );

      _finishLogin(sessionToken, requestTenantId: state.tenantId);
    } catch (e, s) {
      if (_isDeviceLimitRefusal(e)) loginSignupVerifyBack();
      handleError(e, s, LoginOperation.signupVerify);
      emit(state.copyWith(processing: false));
    }
  }

  void loginSignupVerifyBack() async {
    emit(state.copyWith(signupSessionOtpProvisionalWithDateTime: null, signupCodeInput: const CodeInput.pure()));
  }

  void loginSignupVerifyRepeat() {
    loginSignupRequestSubmitted();
  }

  // LoginDeviceLimit

  /// Signs the picked device out and finishes the login left waiting.
  ///
  /// The login is the one the backend accepted before refusing it for the
  /// device limit, so nothing is asked of the user again.
  Future<void> loginDeviceLimitSessionPicked(String sessionId) async {
    final pendingLogin = state.pendingLogin;
    if (state.processing || pendingLogin == null) return;

    emit(state.copyWith(processing: true, pendingLoginRevokingSessionId: sessionId));

    try {
      // An embedded page shown as the launch screen signs up before the system
      // info is read; the refusal came out of that request, so the steps that
      // follow it there are made here. Everything that can fail is done before
      // the device is signed out: after that the login is finished, and a
      // failure would leave its token with nowhere to go.
      if (state.systemInfo == null) {
        final systemInfo = await _loadAndValidateSystemInfo(state.coreUrl!, pendingLogin.tenantId);
        if (systemInfo == null) {
          // The backend and this build do not fit, and the user has been told:
          // there is no session to enter, so no device is signed out for it.
          _dropPendingLogin();
          return;
        }
        emit(state.copyWith(systemInfo: systemInfo));
      }
      final callbackData = state.pendingLoginCallbackData;
      final postRequest = callbackData != null ? RawHttpRequest.fromJson(callbackData) : null;

      final sessionToken = await authRepository.completeLogin(
        coreUrl: state.coreUrl!,
        tenantId: pendingLogin.tenantId,
        pendingLoginToken: pendingLogin.token,
        revokeSessionId: sessionId,
      );

      if (postRequest != null) await authRepository.executePostLoginHttpRequest(postRequest);

      _finishLogin(sessionToken, requestTenantId: pendingLogin.tenantId);
    } on PendingLoginSessionNotFoundException catch (e) {
      _logger.warning('Known login error occurred: $e', e);
      _onPendingLoginSessionGone(pendingLogin, sessionId);
    } on PendingLoginNotFoundException catch (e) {
      _logger.warning('Known login error occurred: $e', e);
      _dropPendingLogin();
      notificationsBloc.add(const NotificationsSubmitted(LoginPendingLoginNotFoundNotification()));
    } catch (e, s) {
      emit(state.copyWith(processing: false, pendingLoginRevokingSessionId: null));

      handleError(e, s, LoginOperation.deviceLimitSessionPicked);
    }
  }

  /// Ignored while a device is being signed out: the answer to that request
  /// belongs to the login being left, and the screen does not let go of it.
  void loginDeviceLimitBack() {
    if (state.processing) return;

    _dropPendingLogin();
  }

  /// The device limit was met: either the login is left waiting for one of the
  /// account's devices to be signed out, or the places are taken by other
  /// accounts and there is nothing to pick here.
  void _onDeviceLimitReached(LoginDeviceLimitReached error) {
    final pendingLogin = error.pendingLogin;

    if (pendingLogin == null) {
      _dropPendingLogin();
      notificationsBloc.add(const NotificationsSubmitted(LoginDeviceLimitReachedNotification()));
      return;
    }

    // Refused again while already waiting: the device signed out was not
    // enough, and the list on screen is replaced by the one that is true now.
    final stillReached = state.pendingLogin != null;

    emit(
      state.copyWith(
        processing: false,
        pendingLogin: pendingLogin,
        pendingLoginRevokingSessionId: null,
        // A login newly left waiting starts with nothing of an earlier one.
        pendingLoginCallbackData: stillReached ? state.pendingLoginCallbackData : null,
      ),
    );

    if (stillReached) {
      notificationsBloc.add(const NotificationsSubmitted(LoginDeviceLimitStillReachedNotification()));
    }
  }

  /// The session picked was signed out by somebody else in the meantime. The
  /// login is still waiting, so the rest of the list stays to pick from.
  void _onPendingLoginSessionGone(PendingLogin pendingLogin, String sessionId) {
    final remaining = pendingLogin.withoutSession(sessionId);

    if (remaining.sessions.isEmpty) {
      // Nothing left to pick, and a place has just been freed: signing in
      // again is the way through.
      _dropPendingLogin();
      notificationsBloc.add(const NotificationsSubmitted(LoginPendingLoginNotFoundNotification()));
      return;
    }

    emit(state.copyWith(processing: false, pendingLogin: remaining, pendingLoginRevokingSessionId: null));
    notificationsBloc.add(const NotificationsSubmitted(LoginPendingLoginSessionNotFoundNotification()));
  }

  /// Leaves the device limit behind and returns to where the login started.
  void _dropPendingLogin() {
    emit(
      state.copyWith(
        processing: false,
        pendingLogin: null,
        pendingLoginRevokingSessionId: null,
        pendingLoginCallbackData: null,
      ),
    );
  }

  /// Whether the login was refused for a device limit.
  ///
  /// The limits are checked after the credentials, which is what the callers
  /// read from it: a one-time code refused this way was accepted and is spent,
  /// so the flow that verified it leaves the screen asking for it (a code
  /// waiting on another tab is still good); and the user is told by the cubit
  /// itself, on the device limit screen or in a message.
  bool _isDeviceLimitRefusal(Object error) {
    return error is LoginDeviceLimitReached || error is DeviceSwitchLimitReachedException;
  }

  /// Tells the user what a failed request of the login came to.
  ///
  /// A device limit changes where the login stands and is followed here; a
  /// refusal with wording of its own is told with it; anything else is
  /// unexpected and is both reported and shown.
  void handleError(Object error, StackTrace stackTrace, LoginOperation operation) {
    if (error is LoginDeviceLimitReached) {
      _logger.warning('Known login error occurred: $error', error);
      _onDeviceLimitReached(error);
      return;
    }

    if (error is DeviceSwitchLimitReachedException) {
      _logger.warning('Known login error occurred: $error', error);
      _dropPendingLogin();
      notificationsBloc.add(const NotificationsSubmitted(LoginDeviceSwitchLimitReachedNotification()));
      return;
    }

    if (error is RequestFailure) {
      final notification = loginErrorNotification(
        error,
        operation: operation,
        otpSigninIdentifiers: state.otpSigninIdentifiers,
      );
      if (notification != null) {
        _logger.warning('Known login error occurred: ${error.error ?? error}', error);
        notificationsBloc.add(NotificationsSubmitted(notification));
        return;
      }
    }

    // Anything left is unexpected, and is still reported as such - but it also
    // reaches the user, because a sign-in that fails in silence sends them
    // retyping credentials that were never the problem.
    _logger.severe('Unexpected error during login process', error, stackTrace);
    CrashlyticsUtils.recordError(error, stack: stackTrace, reason: operation.reportReason);
    notificationsBloc.add(NotificationsSubmitted(LoginUnexpectedErrorNotification(error)));
  }
}
