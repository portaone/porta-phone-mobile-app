import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'package:_http_client/_http_client.dart';

import 'exceptions.dart';
import 'utils/request_utils.dart';
import 'api_request_options.dart';
import 'api_failure_rules.dart';
import 'api_response_options.dart';
import 'models/models.dart';

// TODO(Serdun): Use correct naming for request and response options
class WebtritApiClient {
  final Logger _logger;

  static const _apiBasePath = 'api';
  static const _apiBasePathSegmentsV1 = [_apiBasePath, 'v1'];

  @visibleForTesting
  static Uri buildTenantUrl(Uri baseUrl, String tenantId) {
    if (tenantId.isEmpty) {
      return baseUrl;
    } else {
      final baseUrlPathSegments = List.of(baseUrl.pathSegments.where((segment) => segment.isNotEmpty));
      if (baseUrlPathSegments.length >= 2 && baseUrlPathSegments[baseUrlPathSegments.length - 2] == 'tenant') {
        baseUrlPathSegments.removeRange(baseUrlPathSegments.length - 2, baseUrlPathSegments.length);
      }
      return baseUrl.replace(
        pathSegments: [
          ...baseUrlPathSegments,
          ...['tenant', tenantId],
        ],
      );
    }
  }

  WebtritApiClient(
    Uri baseUrl,
    String tenantId, {
    Duration? connectionTimeout,
    TrustedCertificates certs = TrustedCertificates.empty,
    bool isDebug = false,
    String? userAgent,
  }) : this.inner(
         baseUrl,
         tenantId,
         httpClient: createHttpClient(connectionTimeout: connectionTimeout, certs: certs),
         isDebug: isDebug,
         userAgent: userAgent,
       );

  @visibleForTesting
  WebtritApiClient.inner(
    Uri baseUrl,
    String tenantId, {
    required http.Client httpClient,
    Logger? logger,
    this.isDebug = false,
    this.userAgent,
  }) : _httpClient = httpClient,
       _logger = Logger('WebtritApiClient'),
       tenantUrl = buildTenantUrl(baseUrl, tenantId);

  // Endpoint optional in the adapter contract, JSON response.
  static const _optionalEndpoint = ResponseOptions(optionalEndpoint: true);

  // The one call made without a session, so a 401 on it is about the
  // credentials just sent rather than about a session that has gone.
  static final _sessionCreateEndpoint = ResponseOptions(failures: [incorrectCredentialsOn401Rule]);

  // Two endpoints report a missing account as a bare 404 with no code to read,
  // and mean the account rather than the thing being fetched.
  static final _userNotFoundOn404 = ResponseOptions(failures: [userNotFoundOn404Rule]);

  // Forwarding: a voicemail endpoint like the others, plus the three refusals
  // that only this route can produce.
  static final _voicemailForwardEndpoint = ResponseOptions(
    optionalEndpoint: true,
    failures: [voicemailNotConfiguredRule, ...voicemailForwardRules],
  );

  // The voicemail endpoints, which are optional like the rest and are also the
  // only ones that can report the mailbox as unconfigured.
  static final _voicemailEndpoint = ResponseOptions(optionalEndpoint: true, failures: [voicemailNotConfiguredRule]);

  static final _voicemailEndpointBytes = ResponseOptions(
    responseType: ResponseType.bytes,
    optionalEndpoint: true,
    failures: [voicemailNotConfiguredRule],
  );

  final Uri tenantUrl;
  final http.Client _httpClient;
  final bool isDebug;

  /// Value sent as the `User-Agent` request header, identifying the app build
  /// and device. The backend stores it on the session it creates, so the user
  /// can recognize their devices in the active-sessions list.
  ///
  /// `null` leaves the header to the platform (browsers forbid setting it, so
  /// on web it is always the browser's own value).
  final String? userAgent;

  /// Maximum number of characters of an unparsed error body carried into
  /// [RequestFailure.rawBody].
  static const _rawErrorBodyLimit = 256;

  void close() {
    _httpClient.close();
  }

  Future<dynamic> _httpClientExecute(
    String method,
    List<String> pathSegments,
    String? token,
    Object? requestDataJson, {
    String? requestId,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    RequestOptions requestOptions = const RequestOptions(),
    ResponseOptions responseOptions = const ResponseOptions(),
  }) async {
    // The call's own parameters are merged into whatever the configured base URL
    // already carries rather than replacing it: `replace` swaps the whole query,
    // so a deployment whose URL carries something of its own would keep it on
    // every call that asks for nothing and lose it on every call that does - the
    // same endpoint behaving two ways depending on a flag.
    final mergedQueryParameters = {...tenantUrl.queryParameters, ...?queryParameters};

    final url = tenantUrl.replace(
      pathSegments: [...tenantUrl.pathSegments.where((segment) => segment.isNotEmpty), ...pathSegments],
      queryParameters: mergedQueryParameters.isEmpty ? null : mergedQueryParameters,
    );

    final xRequestId = requestId ?? RequestUtil.generate();

    final requestHeaders = {
      'content-type': 'application/json; charset=utf-8',
      'accept': 'application/json',
      'x-request-id': xRequestId,
      'user-agent': ?userAgent,
      if (token != null) 'authorization': 'Bearer $token',
    };

    final requestData = requestDataJson != null ? jsonEncode(requestDataJson) : null;

    int requestAttempt = 0;

    while (true) {
      try {
        // Create a new `http.Request` instance for each iteration.
        // Once sent, a request is finalized and cannot be reused.
        // A fresh instance prevents "Can't finalize a finalized Request" errors.
        final httpRequest = http.Request(method, url);

        httpRequest.headers.addAll(requestHeaders);

        if (headers != null) httpRequest.headers.addAll(headers);

        if (requestData != null) httpRequest.body = requestData;

        _logger.info(
          ' ${method.toUpperCase()} request($requestAttempt) to $url with requestId: $xRequestId'
          '${isDebug ? ' headers: ${jsonEncode(httpRequest.headers)}' : ''}'
          '${isDebug && requestData != null ? ', request body: $requestData' : ''}',
        );

        final httpResponse = await http.Response.fromStream(await _httpClient.send(httpRequest));

        final responseData = httpResponse.body;

        // A successful non-JSON response (binary download, raw access) must not
        // be JSON-decoded or logged as text; only json responses and error
        // bodies (which the backend serves as JSON) go through jsonDecode.
        final logBody =
            responseOptions.responseType == ResponseType.json ||
            !(httpResponse.statusCode == 200 ||
                httpResponse.statusCode == 201 ||
                httpResponse.statusCode == 204 ||
                httpResponse.statusCode == 304);
        _logger.info(
          '${method.toUpperCase()} response with status code: ${httpResponse.statusCode} for requestId: $xRequestId'
          '${logBody ? ', response body: ${httpResponse.body}' : ', response bytes: ${httpResponse.bodyBytes.length}'}',
        );

        // 201 belongs here with the rest: it is how a backend says it created
        // something, and voicemail forwarding is the first call in this client to
        // be answered that way. Without it a created resource arrives as a
        // RequestFailure carrying a 2xx, which reads as a server fault.
        if (httpResponse.statusCode == 200 ||
            httpResponse.statusCode == 201 ||
            httpResponse.statusCode == 204 ||
            httpResponse.statusCode == 304) {
          // Return response in the requested format depending on the response type:
          // - JSON-decoded map for API data responses (a malformed body still
          //   throws FormatException: the endpoint promised JSON and broke it)
          // - Raw bytes for binary downloads (e.g., files)
          // - Full http.Response object for advanced access (headers, status, etc.)
          return switch (responseOptions.responseType) {
            ResponseType.json => responseData.isEmpty ? {} : jsonDecode(responseData),
            ResponseType.bytes => httpResponse.bodyBytes,
            ResponseType.raw => httpResponse,
          };
        } else {
          // An error status with a non-JSON body (e.g. a bare "404 page not found"
          // from an ingress in front of a dead backend) is still a definitive
          // server response: it must surface as RequestFailure with the real
          // status code, not as a FormatException the retry loop below would
          // treat as a transport error and pointlessly retry.
          ErrorResponse? error;
          String? rawErrorBody;
          try {
            final responseDataJson = responseData.isEmpty ? {} : jsonDecode(responseData);
            error = switch (responseDataJson) {
              Map(isEmpty: true) => null,
              {'errors': {'detail': _}} => null,
              _ => ErrorResponse.fromJson(responseDataJson),
            };
            // Anything at all: a body in a shape this does not know must not
            // take the failure with it. The status code is the part the caller
            // acts on, and it is already known here - throwing instead hands
            // them a cast error from inside a parse and no status at all.
          } catch (_) {
            rawErrorBody = responseData.length > _rawErrorBodyLimit
                ? '${responseData.substring(0, _rawErrorBodyLimit)}...'
                : responseData;
          }

          final failure = FailureContext(
            url: tenantUrl,
            requestId: xRequestId,
            statusCode: httpResponse.statusCode,
            token: token,
            error: error,
            rawBody: rawErrorBody,
          );

          // For endpoints declared optional in the adapter contract, "not
          // implemented" is a 501 or a 404 without a backend error code (absent
          // route); a 404 carrying an error code is a domain rejection produced
          // by a live endpoint. This reads the absence of a code rather than a
          // code, which is why it is a flag rather than one of the rules below.
          if (responseOptions.optionalEndpoint &&
              (httpResponse.statusCode == 501 || (httpResponse.statusCode == 404 && error?.code == null))) {
            throw EndpointNotSupportedException(
              url: tenantUrl,
              requestId: xRequestId,
              statusCode: httpResponse.statusCode,
              recognizedNotSupportedCodes: ['404', '501'],
            );
          }

          // What this one endpoint knows about first, then what holds for every
          // call. The order is the point: a rule about one endpoint is declared
          // on it and wins there, instead of being added to a chain that every
          // other request also walks.
          for (final rule in [...responseOptions.failures, ...defaultFailureRules]) {
            if (rule.matches(failure)) throw rule.build(failure);
          }

          throw failure.unrecognised;
        }
      } catch (e) {
        if (e is! VoicemailNotConfiguredException && e is! EndpointNotSupportedException) {
          final message = '${method.toUpperCase()} failed for requestId: $xRequestId with error: $e';
          // A client error (4xx) is a rejection of this particular request;
          // severe is reserved for server-side and transport failures.
          if (e is RequestFailure && e.isClientError) {
            _logger.warning(message);
          } else {
            _logger.severe(message);
          }
        }

        // Do not retry for valid server responses with a defined HTTP status code.
        if (e is RequestFailure || requestAttempt >= requestOptions.retries) rethrow;

        requestAttempt++;
        await Future.delayed(requestOptions.retryDelay);
      }
    }
  }

  Future<dynamic> _httpClientExecuteGet(
    List<String> pathSegments,
    Map<String, String>? headers,
    String? token, {
    Map<String, String>? queryParameters,
    RequestOptions requestOptions = const RequestOptions(),
    ResponseOptions responseOptions = const ResponseOptions(),
  }) {
    return _httpClientExecute(
      'get',
      pathSegments,
      token,
      null,
      headers: headers,
      queryParameters: queryParameters,
      requestOptions: requestOptions,
      responseOptions: responseOptions,
    );
  }

  Future<dynamic> _httpClientExecutePost(
    List<String> pathSegments,
    Map<String, String>? headers,
    String? token,
    Object? requestDataJson, {
    Map<String, String>? queryParameters,
    RequestOptions requestOptions = const RequestOptions(),
    ResponseOptions responseOptions = const ResponseOptions(),
  }) {
    return _httpClientExecute(
      'post',
      pathSegments,
      token,
      requestDataJson,
      headers: headers,
      queryParameters: queryParameters,
      requestOptions: requestOptions,
      responseOptions: responseOptions,
    );
  }

  Future<dynamic> _httpClientExecutePatch(
    List<String> pathSegments,
    Map<String, String>? headers,
    String? token,
    Object? requestDataJson, {
    RequestOptions requestOptions = const RequestOptions(),
    ResponseOptions responseOptions = const ResponseOptions(),
  }) {
    return _httpClientExecute(
      'patch',
      pathSegments,
      token,
      requestDataJson,
      headers: headers,
      requestOptions: requestOptions,
      responseOptions: responseOptions,
    );
  }

  Future<dynamic> _httpClientExecuteDelete(
    List<String> pathSegments,
    Map<String, String>? headers,
    String? token, {
    Map<String, String>? queryParameters,
    RequestOptions requestOptions = const RequestOptions(),
    ResponseOptions responseOptions = const ResponseOptions(),
  }) {
    return _httpClientExecute(
      'delete',
      pathSegments,
      token,
      null,
      headers: headers,
      queryParameters: queryParameters,
      requestOptions: requestOptions,
      responseOptions: responseOptions,
    );
  }

  Future<bool> healthCheck({RequestOptions options = const RequestOptions()}) async {
    try {
      await _httpClientExecuteGet([_apiBasePath, 'health-check'], null, null, requestOptions: options);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<SystemInfo> getSystemInfo({RequestOptions options = const RequestOptions()}) async {
    final responseJson = await _httpClientExecuteGet(
      [..._apiBasePathSegmentsV1, 'system-info'],
      null,
      null,
      requestOptions: options,
    );

    return SystemInfo.fromJson(responseJson);
  }

  Future<SessionResult> createUser(
    SessionUserCredential sessionUserCredential, {
    Map<String, dynamic>? extraPayload,
    RequestOptions options = const RequestOptions(),
  }) async {
    final requestPayload = {...sessionUserCredential.toJson(), if (extraPayload?.isNotEmpty == true) ...extraPayload!};

    final responseJson = await _httpClientExecutePost(
      [..._apiBasePathSegmentsV1, 'user'],
      null,
      null,
      requestPayload,
      requestOptions: options,
    );

    return SessionResult.fromJson(responseJson);
  }

  Future<SessionOtpProvisional> createSessionOtp(
    SessionOtpCredential sessionOtpCredential, {
    RequestOptions options = const RequestOptions(),
  }) async {
    final requestJson = sessionOtpCredential.toJson();

    final responseJson = await _httpClientExecutePost(
      [..._apiBasePathSegmentsV1, 'session', 'otp-create'],
      null,
      null,
      requestJson,
      requestOptions: options,
      responseOptions: _userNotFoundOn404,
    );

    return SessionOtpProvisional.fromJson(responseJson);
  }

  Future<SessionToken> verifySessionOtp(
    SessionOtpProvisional sessionOtpProvisional,
    String code, {
    RequestOptions options = const RequestOptions(),
  }) async {
    final requestJson = {'otp_id': sessionOtpProvisional.otpId, 'code': code};

    final responseJson = await _httpClientExecutePost(
      [..._apiBasePathSegmentsV1, 'session', 'otp-verify'],
      null,
      null,
      requestJson,
      requestOptions: options,
    );
    return SessionToken.fromJson(responseJson);
  }

  Future<SessionToken> createSession(
    SessionLoginCredential sessionLoginCredential, {
    RequestOptions options = const RequestOptions(),
  }) async {
    final requestJson = sessionLoginCredential.toJson();

    final responseJson = await _httpClientExecutePost(
      [..._apiBasePathSegmentsV1, 'session'],
      null,
      null,
      requestJson,
      requestOptions: options,
      responseOptions: _sessionCreateEndpoint,
    );

    return SessionToken.fromJson(responseJson);
  }

  Future<SessionToken> createSessionAutoProvision(
    SessionAutoProvisionCredential sessionAutoProvisionCredential, {
    RequestOptions options = const RequestOptions(),
  }) async {
    final requestJson = sessionAutoProvisionCredential.toJson();

    final responseJson = await _httpClientExecutePost(
      [..._apiBasePathSegmentsV1, 'session', 'auto-provision'],
      null,
      null,
      requestJson,
      requestOptions: options,
    );

    return SessionToken.fromJson(responseJson);
  }

  Future<void> deleteSession(String token, {RequestOptions options = const RequestOptions()}) async {
    await _httpClientExecuteDelete([..._apiBasePathSegmentsV1, 'session'], null, token, requestOptions: options);
  }

  Future<UserInfo> getUserInfo(String token, {RequestOptions options = const RequestOptions()}) async {
    final responseJson = await _httpClientExecuteGet(
      [..._apiBasePathSegmentsV1, 'user'],
      null,
      token,
      requestOptions: options,
      responseOptions: _userNotFoundOn404,
    );

    return UserInfo.fromJson(responseJson);
  }

  /// Retrieves the deployment's own STUN/TURN configuration.
  ///
  /// Declared as an optional endpoint: a core that does not bundle ICE servers
  /// answers 501 (or 404 without a backend error code), which surfaces as
  /// [EndpointNotSupportedException] rather than a generic failure.
  Future<IceServersResponse> getUserIceServers(String token, {RequestOptions options = const RequestOptions()}) async {
    final responseJson = await _httpClientExecuteGet(
      [..._apiBasePathSegmentsV1, 'user', 'ice-servers'],
      null,
      token,
      requestOptions: options,
      responseOptions: _optionalEndpoint,
    );

    return IceServersResponse.fromJson(responseJson);
  }

  Future<List<UserContact>> getUserContactList(String token, {RequestOptions options = const RequestOptions()}) async {
    final responseJson = await _httpClientExecuteGet(
      [..._apiBasePathSegmentsV1, 'user', 'contacts'],
      null,
      token,
      requestOptions: options,
    );

    return (responseJson['items'] as List<dynamic>).map((e) {
      return UserContact.fromJson(e as Map<String, dynamic>);
    }).toList();
  }

  Future<UserContact> getUserContact(
    String userId,
    String token, {
    RequestOptions options = const RequestOptions(),
  }) async {
    final responseJson = await _httpClientExecuteGet(
      [..._apiBasePathSegmentsV1, 'user', 'contacts', userId],
      null,
      token,
      requestOptions: options,
    );
    return UserContact.fromJson(responseJson as Map<String, dynamic>);
  }

  Future<List<UserSession>> getUserSessions(String token, {RequestOptions options = const RequestOptions()}) async {
    final responseJson = await _httpClientExecuteGet(
      [..._apiBasePathSegmentsV1, 'user', 'sessions'],
      null,
      token,
      requestOptions: options,
    );

    return (responseJson['items'] as List<dynamic>).map((e) {
      return UserSession.fromJson(e as Map<String, dynamic>);
    }).toList();
  }

  Future<void> deleteUserSession(
    String token,
    String sessionId, {
    RequestOptions options = const RequestOptions(),
  }) async {
    await _httpClientExecuteDelete(
      [..._apiBasePathSegmentsV1, 'user', 'sessions', sessionId],
      null,
      token,
      requestOptions: options,
    );
  }

  Future<void> deleteUserInfo(String token, {RequestOptions options = const RequestOptions()}) async {
    await _httpClientExecuteDelete(
      [..._apiBasePathSegmentsV1, 'user'],
      null,
      token,
      requestOptions: options,
      responseOptions: _optionalEndpoint,
    );
  }

  Future<AppStatus> getAppStatus(String token, {RequestOptions options = const RequestOptions()}) async {
    final responseJson = await _httpClientExecuteGet(
      [..._apiBasePathSegmentsV1, 'app', 'status'],
      null,
      token,
      requestOptions: options,
    );

    return AppStatus.fromJson(responseJson);
  }

  Future<void> updateAppStatus(
    String token,
    AppStatus appStatus, {
    RequestOptions options = const RequestOptions(),
  }) async {
    final requestJson = appStatus.toJson();

    await _httpClientExecutePatch(
      [..._apiBasePathSegmentsV1, 'app', 'status'],
      null,
      token,
      requestJson,
      requestOptions: options,
    );
  }

  Future<void> createAppContact(
    String token,
    List<AppContact> appContacts, {
    RequestOptions options = const RequestOptions(),
  }) async {
    final requestJson = appContacts.map((e) => e.toJson()).toList();

    await _httpClientExecutePost(
      [..._apiBasePathSegmentsV1, 'app', 'contacts'],
      null,
      token,
      requestJson,
      requestOptions: options,
    );
  }

  Future<List<AppSmartContact>> getAppSmartContactList(
    String token, {
    RequestOptions options = const RequestOptions(),
  }) async {
    final responseJson = await _httpClientExecuteGet(
      [..._apiBasePathSegmentsV1, 'app', 'contacts', 'smart'],
      null,
      token,
      requestOptions: options,
    );

    return (responseJson as List<dynamic>).map((e) => AppSmartContact.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createAppPushToken(
    String token,
    AppPushToken appPushToken, {
    RequestOptions options = const RequestOptions(),
  }) async {
    final requestJson = appPushToken.toJson();

    await _httpClientExecutePost(
      [..._apiBasePathSegmentsV1, 'app', 'push-tokens'],
      null,
      token,
      requestJson,
      requestOptions: options,
    );
  }

  Future<DemoCallToActionsResponse> getCallToActions(
    String token,
    String locale,
    DemoCallToActionsParam callToActionsParam, {
    RequestOptions options = const RequestOptions(),
  }) async {
    final requestJson = callToActionsParam.toJson();

    final responseJson = await _httpClientExecutePost(
      [..._apiBasePathSegmentsV1, 'custom', 'private', 'call-to-actions'],
      {'Accept-Language': locale},
      token,
      requestJson,
      requestOptions: options,
    );

    return DemoCallToActionsResponse.fromJson(responseJson);
  }

  Future<SelfConfigResponse> getSelfConfig(String token, {RequestOptions options = const RequestOptions()}) async {
    final responseJson = await _httpClientExecutePost(
      [..._apiBasePathSegmentsV1, 'custom', 'private', 'self-config-portal-url'],
      null,
      token,
      {},
      requestOptions: options,
    );

    return SelfConfigResponse.fromJson(responseJson);
  }

  Future<ExternalPageAccessToken> getExternalPageAccessToken(
    String token, {
    RequestOptions options = const RequestOptions(),
  }) async {
    final responseJson = await _httpClientExecutePost(
      [..._apiBasePathSegmentsV1, 'custom', 'private', 'external-page-access-token'],
      null,
      token,
      {},
      requestOptions: options,
      responseOptions: _optionalEndpoint,
    );

    return ExternalPageAccessToken.fromJson(responseJson);
  }

  /// The user's voicemail messages: the mailbox merged with everything other
  /// users forwarded to them, newest first.
  ///
  /// [folder] picks which side of the trash to list and defaults to the inbox.
  /// `has_new_messages` is computed over what the answer actually contains, so a
  /// trash listing never reports new messages.
  Future<UserVoicemailListResponse> getUserVoicemailList(
    String token, {
    VoicemailFolder folder = VoicemailFolder.inbox,
    String? locale,
    RequestOptions options = const RequestOptions(),
  }) async {
    final folderValue = folder.queryValue;

    final responseJson = await _httpClientExecuteGet(
      [..._apiBasePathSegmentsV1, 'user', 'voicemails'],
      locale != null ? {'Accept-Language': locale} : null,
      token,
      queryParameters: folderValue != null ? {'folder': folderValue} : null,
      requestOptions: options,
      responseOptions: _voicemailEndpoint,
    );

    return UserVoicemailListResponse.fromJson(responseJson);
  }

  Future<UserVoicemail> getUserVoicemail(
    String token,
    String messageId, {
    String? locale,
    RequestOptions options = const RequestOptions(),
  }) async {
    final responseJson = await _httpClientExecuteGet(
      [..._apiBasePathSegmentsV1, 'user', 'voicemails', messageId],
      locale != null ? {'Accept-Language': locale} : null,
      token,
      requestOptions: options,
      responseOptions: _voicemailEndpoint,
    );

    return UserVoicemail.fromJson(responseJson);
  }

  /// Moves a voicemail message to the trash, or deletes it outright when
  /// [permanent] is set.
  ///
  /// Space is freed only by a permanent delete or by emptying the trash;
  /// nothing in there expires on its own.
  ///
  /// Which way a plain delete goes is the thing the backend changed. It used to
  /// mean "to the trash" wherever there was one, and is becoming permanent, so
  /// that a client built before the trash existed goes on deleting rather than
  /// quietly filling a mailbox nobody empties. A move to the trash therefore
  /// asks for the trash by name.
  ///
  /// A backend that has not made that change yet declares no such parameter and
  /// refuses the request outright. That refusal is left to be seen rather than
  /// worked around here: a client quietly speaking two contracts hides which
  /// one the backend speaks, and the answer to a backend that has not shipped
  /// the change is a release that waits for it, not a second request.
  Future<void> deleteUserVoicemail(
    String token,
    String messageId, {
    bool permanent = false,
    String? locale,
    RequestOptions options = const RequestOptions(),
  }) async {
    await _httpClientExecuteDelete(
      [..._apiBasePathSegmentsV1, 'user', 'voicemails', messageId],
      locale != null ? {'Accept-Language': locale} : null,
      token,
      queryParameters: permanent ? {'permanent': 'true'} : {'trash': 'true'},
      requestOptions: options,
      responseOptions: _voicemailEndpoint,
    );
  }

  /// Puts a trashed voicemail message back in the inbox.
  ///
  /// Answers 404 when nothing with that id is in this user's trash, including a
  /// message that exists but was never trashed. That is worth treating as
  /// "already restored" rather than as a failure, but the decision is the
  /// caller's: this call reports it as an ordinary [RequestFailure] like any
  /// other rejection. A backend with no trash at all has no such route and
  /// answers 404 without an error code, which surfaces as
  /// [EndpointNotSupportedException] instead.
  Future<void> restoreUserVoicemail(
    String token,
    String messageId, {
    String? locale,
    RequestOptions options = const RequestOptions(),
  }) async {
    await _httpClientExecutePost(
      [..._apiBasePathSegmentsV1, 'user', 'voicemails', messageId, 'restore'],
      locale != null ? {'Accept-Language': locale} : null,
      token,
      null,
      requestOptions: options,
      responseOptions: _voicemailEndpoint,
    );
  }

  /// Passes a voicemail message on to another user of the same backend, and
  /// answers with the id the message now has in the RECIPIENT's list.
  ///
  /// That id is of little use to the sender: the forwarded message does not
  /// appear in their own list, and their copy of the original is untouched.
  ///
  /// [toUserId] is a user id as the contacts endpoint reports it, not a phone
  /// number - the backend checks it against that endpoint, and the check is what
  /// authorises writing a recording into someone else's storage.
  ///
  /// [idempotencyKey] is required here even though the backend treats it as
  /// optional, because this client retries a request that failed below the HTTP
  /// layer. A forward that timed out may well have been delivered, so retrying
  /// without a key is how one message becomes several; retrying with the same
  /// key returns the original result instead. Use a fresh key for each
  /// deliberate forward and reuse it when retrying that one.
  Future<String> forwardUserVoicemail(
    String token,
    String messageId, {
    required String toUserId,
    required String idempotencyKey,
    String? locale,
    RequestOptions options = const RequestOptions(),
  }) async {
    final responseJson = await _httpClientExecutePost(
      [..._apiBasePathSegmentsV1, 'user', 'voicemails', messageId, 'forward'],
      locale != null ? {'Accept-Language': locale} : null,
      token,
      {'to_user_id': toUserId, 'idempotency_key': idempotencyKey},
      requestOptions: options,
      responseOptions: _voicemailForwardEndpoint,
    );

    return responseJson['id'] as String;
  }

  /// Deletes every message in the user's trash for good.
  ///
  /// This is the operation that frees mailbox space; a message sitting in the
  /// trash still occupies it. Emptying is resumable: whatever could be deleted
  /// stays deleted, so a retry repeats only what is left.
  ///
  /// Unlike [restoreUserVoicemail], a backend without a trash does not report
  /// this call as an absent route: `voicemails/trash` is shaped like a message
  /// id, so the plain delete route answers it, and the refusal comes back as an
  /// ordinary message-not-found rejection. There is nothing to read from that,
  /// which is why the caller must gate this call on the trash being advertised
  /// rather than probe for it.
  Future<void> emptyUserVoicemailTrash(
    String token, {
    String? locale,
    RequestOptions options = const RequestOptions(),
  }) async {
    await _httpClientExecuteDelete(
      [..._apiBasePathSegmentsV1, 'user', 'voicemails', 'trash'],
      locale != null ? {'Accept-Language': locale} : null,
      token,
      requestOptions: options,
      responseOptions: _voicemailEndpoint,
    );
  }

  /// Changes attributes of a voicemail message.
  ///
  /// Only the attributes given are sent, and only those are changed: `seen` and
  /// `saved` are independent flags set by separate calls, so saving a message
  /// does not mark it read and marking it read does not unsave it. An attribute
  /// left out is not sent at all rather than sent as null, which the backend
  /// would read as "not given" anyway but which would put a value in the body
  /// that nobody asked to change.
  ///
  /// Passing neither is refused rather than sent. The backend answers such a
  /// patch without doing anything, so a call that reaches here with nothing to
  /// change is a mistake at the call site and is worth hearing about there.
  Future<void> updateUserVoicemail(
    String token,
    String messageId, {
    bool? seen,
    bool? saved,
    String? locale,
    RequestOptions options = const RequestOptions(),
  }) async {
    final requestJson = {'seen': ?seen, 'saved': ?saved};
    if (requestJson.isEmpty) {
      throw ArgumentError('updateUserVoicemail needs at least one of seen or saved to change');
    }

    await _httpClientExecutePatch(
      [..._apiBasePathSegmentsV1, 'user', 'voicemails', messageId],
      locale != null ? {'Accept-Language': locale} : null,
      token,
      requestJson,
      requestOptions: options,
      responseOptions: _voicemailEndpoint,
    );
  }

  Future<Uint8List> getUserVoicemailAttachment(
    String token,
    String messageId, {
    String? locale,
    String? fileFormat,
    RequestOptions options = const RequestOptions(),
  }) async {
    final responseJson = await _httpClientExecuteGet(
      [..._apiBasePathSegmentsV1, 'user', 'voicemails', messageId, 'attachment'],
      locale != null ? {'Accept-Language': locale} : null,
      token,
      queryParameters: fileFormat != null && fileFormat.isNotEmpty ? {'file_format': fileFormat} : null,
      requestOptions: options,
      responseOptions: _voicemailEndpointBytes,
    );

    return responseJson;
  }

  String getVoicemailAttachmentUrl(String voicemailId, {String fileFormat = 'mp3'}) {
    final url = tenantUrl.replace(
      pathSegments: [
        ...tenantUrl.pathSegments.where((segment) => segment.isNotEmpty),
        ..._apiBasePathSegmentsV1,
        ...['user', 'voicemails', voicemailId, 'attachment'],
      ],
      queryParameters: fileFormat.isNotEmpty ? {'file_format': fileFormat} : null,
    );
    return url.toString();
  }

  Future<SystemNotificationResponce> getSystemNotificationsHistory(
    String token, {
    DateTime? since,
    int? limit,
    String? locale,
    RequestOptions options = const RequestOptions(),
  }) async {
    final responseJson = await _httpClientExecuteGet(
      [..._apiBasePathSegmentsV1, 'user', 'notifications'],
      locale != null ? {'Accept-Language': locale} : null,
      token,
      requestOptions: options,
      queryParameters: {
        if (since != null) 'created_before': since.toUtc().toIso8601String(),
        if (limit != null) 'limit': limit.toString(),
      },
    );

    return SystemNotificationResponce.fromJson(responseJson as Map<String, dynamic>);
  }

  Future<SystemNotificationResponce> getSystemNotificationsUpdates(
    String token, {
    required DateTime since,
    int? limit,
    String? locale,
    RequestOptions options = const RequestOptions(),
  }) async {
    final responseJson = await _httpClientExecuteGet(
      [..._apiBasePathSegmentsV1, 'user', 'notifications', 'updates'],
      locale != null ? {'Accept-Language': locale} : null,
      token,
      requestOptions: options,
      queryParameters: {'updated_after': since.toUtc().toIso8601String(), if (limit != null) 'limit': limit.toString()},
    );
    print('Response JSON: $responseJson');

    return SystemNotificationResponce.fromJson(responseJson as Map<String, dynamic>);
  }

  Future<void> markSystemNotificationAsSeen(
    String token,
    int notificationId, {
    RequestOptions options = const RequestOptions(),
  }) async {
    final requestJson = {'seen': true};

    await _httpClientExecutePatch(
      [..._apiBasePathSegmentsV1, 'user', 'notifications', notificationId.toString()],
      {},
      token,
      requestJson,
      requestOptions: options,
    );
  }

  Future<CdrHistoryResponse> getCdrHistory(
    String token, {
    DateTime? from,
    DateTime? to,
    int? page,
    int? limit,
    String? locale,
    RequestOptions options = const RequestOptions(),
  }) async {
    final responseJson = await _httpClientExecuteGet(
      [..._apiBasePathSegmentsV1, 'user', 'history'],
      locale != null ? {'Accept-Language': locale} : null,
      token,
      requestOptions: options,
      queryParameters: {
        if (from != null) 'time_from': from.toUtc().toIso8601String(),
        if (to != null) 'time_to': to.toUtc().toIso8601String(),
        if (page != null) 'page': page.toString(),
        if (limit != null) 'items_per_page': limit.toString(),
      },
    );

    return CdrHistoryResponse.fromJson(responseJson as Map<String, dynamic>);
  }

  Future<CallerIdSettings> getCallerIdSettings(String token, {RequestOptions options = const RequestOptions()}) async {
    final responseJson = await _httpClientExecuteGet(
      [..._apiBasePathSegmentsV1, 'user', 'preferences', 'caller-id'],
      null,
      token,
      requestOptions: options,
    );

    return CallerIdSettings.fromJson(responseJson as Map<String, dynamic>);
  }

  Future<CallerIdSettings> updateCallerIdSettings(
    String token,
    CallerIdSettings settings, {
    RequestOptions options = const RequestOptions(),
  }) async {
    final requestJson = settings.toJson();

    final responseJson = await _httpClientExecutePost(
      [..._apiBasePathSegmentsV1, 'user', 'preferences', 'caller-id'],
      null,
      token,
      requestJson,
      requestOptions: options,
    );
    return CallerIdSettings.fromJson(responseJson as Map<String, dynamic>);
  }

  Future<FavoritesGetResult> getFavorites(
    String token, {
    String? ifNoneMatch,
    RequestOptions options = const RequestOptions(),
  }) async {
    final response =
        await _httpClientExecuteGet(
              [..._apiBasePathSegmentsV1, 'user', 'favorites'],
              ifNoneMatch != null ? {'If-None-Match': ifNoneMatch} : null,
              token,
              requestOptions: options,
              responseOptions: ResponseOptions(responseType: ResponseType.raw),
            )
            as http.Response;

    if (response.statusCode == 304) {
      return FavoritesGetResult(notModified: true, etag: response.headers['etag'] ?? '0');
    }

    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
    return FavoritesGetResult(
      notModified: false,
      etag: response.headers['etag'] ?? '0',
      data: FavoritesListResponse.fromJson(responseJson),
    );
  }

  Future<FavoriteBatchSyncResult> batchSyncFavorites(
    String token,
    List<FavoriteBatchAction> actions, {
    RequestOptions options = const RequestOptions(),
  }) async {
    final response =
        await _httpClientExecutePost(
              [..._apiBasePathSegmentsV1, 'user', 'favorites', 'batch_sync'],
              null,
              token,
              {'actions': actions.map((a) => a.toJson()).toList()},
              requestOptions: options,
              responseOptions: ResponseOptions(responseType: ResponseType.raw),
            )
            as http.Response;

    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

    return FavoriteBatchSyncResult(
      data: FavoriteBatchSyncResponse.fromJson(responseJson),
      etag: response.headers['etag'] ?? '0',
    );
  }

  Future<SipSubscriptionsGetResult> getSipSubscriptions(
    String token, {
    String? ifNoneMatch,
    RequestOptions options = const RequestOptions(),
  }) async {
    final response =
        await _httpClientExecuteGet(
              [..._apiBasePathSegmentsV1, 'user', 'sip_subscriptions'],
              ifNoneMatch != null ? {'If-None-Match': ifNoneMatch} : null,
              token,
              requestOptions: options,
              responseOptions: ResponseOptions(responseType: ResponseType.raw),
            )
            as http.Response;

    if (response.statusCode == 304) {
      return SipSubscriptionsGetResult(notModified: true, etag: response.headers['etag'] ?? '0');
    }

    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
    return SipSubscriptionsGetResult(
      notModified: false,
      etag: response.headers['etag'] ?? '0',
      data: SipSubscriptionsListResponse.fromJson(responseJson),
    );
  }

  Future<SipSubscriptionBatchSyncResult> batchSyncSipSubscriptions(
    String token,
    List<SipSubscriptionBatchAction> actions, {
    RequestOptions options = const RequestOptions(),
  }) async {
    final response =
        await _httpClientExecutePost(
              [..._apiBasePathSegmentsV1, 'user', 'sip_subscriptions', 'batch_sync'],
              null,
              token,
              {'actions': actions.map((a) => a.toJson()).toList()},
              requestOptions: options,
              responseOptions: ResponseOptions(responseType: ResponseType.raw),
            )
            as http.Response;

    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;

    return SipSubscriptionBatchSyncResult(
      data: SipSubscriptionBatchSyncResponse.fromJson(responseJson),
      etag: response.headers['etag'] ?? '0',
    );
  }
}
