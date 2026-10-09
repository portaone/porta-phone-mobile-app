import 'package:logging/logging.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/mappers/mappers.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/utils.dart';

import '../system_info/system_info.dart';

final _logger = Logger('AuthRepository');

/// A login was refused because the account is signed in on as many devices as
/// it is allowed.
///
/// Thrown by every call of [AuthRepository] that ends in a session. With a
/// [pendingLogin] the backend is holding the login until one of the account's
/// devices is signed out ([AuthRepository.completeLogin]); without one the
/// places are taken by other accounts and nothing here can be signed out.
class LoginDeviceLimitReached implements Exception {
  const LoginDeviceLimitReached({this.pendingLogin});

  final PendingLogin? pendingLogin;

  // The token of the waiting login is left out: it finishes a login.
  @override
  String toString() => 'LoginDeviceLimitReached(devices to pick from: ${pendingLogin?.sessions.length ?? 0})';
}

/// Abstract interface defining the contract for authentication-related operations.
///
/// This repository handles the interactions with the core API regarding
/// session creation, OTP verification, and initial system configuration retrieval.
abstract class AuthRepository {
  /// Performs a one-off "discovery" request for the given [coreUrl] and [tenantId].
  ///
  /// Used during the login flow to validate that:
  /// - the Core instance is reachable,
  /// - the tenant exists and is supported,
  /// - and to fetch capabilities/routing information that drives which
  ///   screens and flows should be rendered.
  ///
  /// This call does not use any caching and only affects the local login state.
  /// If the user successfully completes the login flow with this Core URL,
  /// the returned [WebtritSystemInfo] should be passed to
  /// [SystemInfoRepository.preload] to initialize the shared system info state.
  Future<WebtritSystemInfo> getSystemInfo(String coreUrl, String tenantId);

  /// Performs a password-based login to create a session.
  Future<SessionToken> login({
    required String coreUrl,
    required String tenantId,
    required String userRef,
    required String password,
  });

  /// Initiates the OTP flow by requesting a temporary session.
  Future<SessionOtpProvisional> requestOtp({
    required String coreUrl,
    required String tenantId,
    required String userRef,
  });

  /// Completes the OTP flow by verifying the [code] against the provisional session.
  Future<SessionToken> verifyOtp({
    required String coreUrl,
    required String tenantId,
    required SessionOtpProvisional sessionOtpProvisional,
    required String code,
  });

  /// Registers a new user (Signup) and optionally logs them in.
  Future<SessionResult> signup({
    required String coreUrl,
    required String tenantId,
    String? email,
    Map<String, dynamic>? extraPayload,
  });

  /// Finishes a login that was refused because the account is signed in on as
  /// many devices as it is allowed, by signing the session [revokeSessionId] out.
  ///
  /// [pendingLoginToken] is what that refusal carried; no credentials are sent.
  Future<SessionToken> completeLogin({
    required String coreUrl,
    required String tenantId,
    required String pendingLoginToken,
    required String revokeSessionId,
  });

  /// Executes an arbitrary HTTP request (e.g., a callback) after a successful login.
  ///
  /// This is typically used in embedded flows where the host application
  /// requires a webhook notification upon successful authentication.
  Future<void> executePostLoginHttpRequest(RawHttpRequest? request);
}

/// Concrete implementation of [AuthRepository].
///
/// This implementation uses [WebtritApiClientFactory] to create ad-hoc clients
/// with specific `coreUrl` and `tenantId` parameters.
///
/// This approach is necessary for the login business case where the user is
/// attempting to connect to a custom Core URL that has not yet been validated
/// or stored in the application's persistent settings.
class AuthRepositoryImpl with ActiveSessionApiMapper implements AuthRepository {
  AuthRepositoryImpl({
    required this.apiClientFactory,
    required this.systemInfoRemoteDatasource,
    required String appIdentifier,
    required String appBundleId,
  }) : _appIdentifier = appIdentifier,
       _appBundleId = appBundleId;

  final WebtritApiClientFactory apiClientFactory;
  final SystemInfoRemoteDatasource systemInfoRemoteDatasource;

  final String _appBundleId;
  final String _appIdentifier;

  @override
  Future<WebtritSystemInfo> getSystemInfo(String coreUrl, String tenantId) async {
    // Delegates to the datasource using override parameters to bypass default/cached configuration.
    return systemInfoRemoteDatasource.getSystemInfo(overrideCoreUrl: Uri.parse(coreUrl), overrideTenantId: tenantId);
  }

  @override
  Future<SessionToken> login({
    required String coreUrl,
    required String tenantId,
    required String userRef,
    required String password,
  }) async {
    final client = apiClientFactory.createWebtritApiClient(coreUrl: Uri.parse(coreUrl), tenantId: tenantId);

    return _namingDeviceLimit(
      tenantId,
      () => client.createSession(
        SessionLoginCredential(
          bundleId: _appBundleId,
          type: PlatformInfo.appType,
          identifier: _appIdentifier,
          login: userRef,
          password: password,
        ),
      ),
    );
  }

  @override
  Future<SessionOtpProvisional> requestOtp({
    required String coreUrl,
    required String tenantId,
    required String userRef,
  }) async {
    final client = apiClientFactory.createWebtritApiClient(coreUrl: Uri.parse(coreUrl), tenantId: tenantId);

    return await client.createSessionOtp(
      SessionOtpCredential(
        bundleId: _appBundleId,
        type: PlatformInfo.appType,
        identifier: _appIdentifier,
        userRef: userRef,
      ),
    );
  }

  @override
  Future<SessionToken> verifyOtp({
    required String coreUrl,
    required String tenantId,
    required SessionOtpProvisional sessionOtpProvisional,
    required String code,
  }) async {
    final client = apiClientFactory.createWebtritApiClient(coreUrl: Uri.parse(coreUrl), tenantId: tenantId);

    return _namingDeviceLimit(tenantId, () => client.verifySessionOtp(sessionOtpProvisional, code));
  }

  @override
  Future<SessionResult> signup({
    required String coreUrl,
    required String tenantId,
    String? email,
    Map<String, dynamic>? extraPayload,
  }) async {
    final client = apiClientFactory.createWebtritApiClient(coreUrl: Uri.parse(coreUrl), tenantId: tenantId);

    return _namingDeviceLimit(
      tenantId,
      () => client.createUser(
        SessionUserCredential(
          bundleId: _appBundleId,
          type: PlatformInfo.appType,
          identifier: _appIdentifier,
          email: email,
        ),
        extraPayload: extraPayload,
        options: RequestOptions.withExtraRetries(),
      ),
    );
  }

  @override
  Future<SessionToken> completeLogin({
    required String coreUrl,
    required String tenantId,
    required String pendingLoginToken,
    required String revokeSessionId,
  }) async {
    final client = apiClientFactory.createWebtritApiClient(coreUrl: Uri.parse(coreUrl), tenantId: tenantId);

    return _namingDeviceLimit(
      tenantId,
      () => client.completeSession(pendingLoginToken: pendingLoginToken, revokeSessionId: revokeSessionId),
    );
  }

  /// Runs a call that ends in a session and turns the backend's device limit
  /// refusal into [LoginDeviceLimitReached].
  ///
  /// The refusal is read here because this is where both halves of a waiting
  /// login are known: the sessions and the token it carries, and the tenant the
  /// request was made in, where finishing it has to be made too.
  Future<T> _namingDeviceLimit<T>(String tenantId, Future<T> Function() request) async {
    try {
      return await request();
    } on DeviceLimitReachedException catch (e) {
      final token = e.pendingLoginToken;
      final sessions = e.sessions.map(activeSessionFromApi).toList();
      _logger.warning('Login refused for the device limit: $e');
      if (token != null && sessions.isEmpty) {
        // The backend holds the login and named no session this could read, so
        // there is nothing to show to pick from.
        _logger.severe('The device limit refusal carries a token and no readable session');
      }

      throw LoginDeviceLimitReached(
        pendingLogin: token == null || sessions.isEmpty
            ? null
            : PendingLogin(token: token, tenantId: tenantId, sessions: sessions),
      );
    }
  }

  @override
  Future<void> executePostLoginHttpRequest(RawHttpRequest? request) async {
    if (request == null) return;

    try {
      await apiClientFactory.createHttpRequestExecutor().execute(
        method: request.method,
        url: request.url,
        headers: request.headers,
        data: request.data,
      );
    } catch (e) {
      _logger.warning('Post login request failed: $e');
    }
  }
}
