# AGENTS.md - api

Typed REST client for WebTrit Core, pure Dart: no Flutter, nothing from `lib/` of the app. What
you usually do here is add an endpoint, give an endpoint a failure of its own, or add a model;
the steps for all three, with the tests, are the skill `core-endpoint`
([SKILL.md](../../../.agents/skills/core-endpoint/SKILL.md)). Which error codes Core sends and
which of them end the session: [core_error_codes.md](../../docs/architecture/core_error_codes.md).
Backend reference (Swagger UI): <https://webtrit.github.io/webtrit_core_pages/>.

## Layout

```
lib/api.dart                       the barrel
lib/src/api_client.dart            WebtritApiClient: one method per endpoint, the per-endpoint ResponseOptions
lib/src/api_failure_rules.dart     FailureContext, FailureRule, defaultFailureRules, the endpoint rules
lib/src/exceptions.dart            RequestFailure, SessionRejection and every typed exception
lib/src/api_request_options.dart   RequestOptions (retries)
lib/src/api_response_options.dart  ResponseOptions (response type, optional endpoint, failures)
lib/src/webtrit_http_request_executor.dart  HttpRequestExecutor
lib/src/models/                    request and response models, barrel models.dart
test/                              one file per area: api_client_<area>_test.dart
```

## Public surface

`lib/api.dart` exports `exceptions.dart`, `models/models.dart`, `api_client.dart`,
`api_request_options.dart` and `webtrit_http_request_executor.dart`, plus `HttpStatus` from
`dart:io` and `ClientException` from `package:http`. Not exported: `ResponseOptions`,
`FailureRule` and the rules - a caller cannot choose how a response is read; the client method
does.

- `WebtritApiClient` - the Core API. `HttpRequestExecutor` is also public and is used by the app
  for requests outside the Core API (embedded pages, the connectivity check); it applies no
  failure rules and no retries and throws a plain `RequestFailure` for any status but 200 and
  204.
- Constructor:

  ```dart
  WebtritApiClient(Uri baseUrl, String tenantId, {
    Duration? connectionTimeout,
    TrustedCertificates certs = TrustedCertificates.empty,
    bool isDebug = false,
    String? userAgent,
  })
  ```

  `WebtritApiClient.inner(...)` (`@visibleForTesting`) takes an `http.Client` for tests.
  `buildTenantUrl` (`@visibleForTesting`) appends `tenant/<tenantId>` and drops a tenant segment
  the base URL already carries; an empty tenant id leaves the base URL as it is. Endpoints live
  under `api/v1/...` of that URL (`healthCheck` is `api/health-check`). Query parameters of the
  base URL are kept on every call.
- `sessionRejections` - a broadcast stream of every `SessionRejection` the client receives,
  published as it is rethrown. `UnauthorizedException`, `SessionMissingException` and
  `UserNotFoundException` implement it. `MainShell` listens and ends the session, so a request
  needs no handling of its own for these. `close()` closes it.

## Options

- `RequestOptions` - retries of transport failures only. Default (`const RequestOptions()` and
  `withDefaultRetries()`): 3 retries, 1 s apart. `withExtraRetries()`: 5 retries, 2 s apart.
  `withNoRetries()`: none. A response with a status, a 5xx included, is never retried: it
  surfaces as `RequestFailure` at once.
- `ResponseOptions`, built inside `api_client.dart` as static fields:
  - `responseType`: `json` (default), `bytes` (downloads), `raw` (the `http.Response`);
  - `optionalEndpoint`: the endpoint is optional in the adapter contract, so 501 or a 404
    without a backend code becomes `EndpointNotSupportedException`. A flag, not a rule, because
    it reads the absence of a code;
  - `failures`: the `FailureRule`s of this endpoint, checked before `defaultFailureRules`.

Success is 200, 201, 204 or 304. An error body is read for what it adds: a body in an unknown
shape leaves `error` null and keeps up to 256 characters in `rawBody`; the status always
survives.

## Failures

Order on an error status: the optional-endpoint check, then `ResponseOptions.failures`, then
`defaultFailureRules`, then a plain `RequestFailure`. The default rules (session and account
codes, then any unclaimed 5xx as `ServerFailureException`) and the codes behind them are in
[core_error_codes.md](../../docs/architecture/core_error_codes.md); do not repeat them here.

`RequestFailure` carries the status, `requestId`, the parsed `error`, `rawBody`, and
`isClientError` (4xx), `isServerError` (5xx), `isTransient` (408, 425, 429), `errorCode`.

Rules an endpoint declares (all in `api_failure_rules.dart`):

| Rule | Exception | Declared by |
|---|---|---|
| `incorrectCredentialsOn401Rule` (status only) | `IncorrectCredentialsException` | `createSession` (`_sessionCreateEndpoint`) |
| `deviceLimitRules`: 409 `device_limit_reached`, 403 `device_switch_limit_reached` | `DeviceLimitReachedException` (with `sessions`, `pendingLoginToken`), `DeviceSwitchLimitReachedException` | `createSession`, `createUser`, `verifySessionOtp`, `createSessionAutoProvision`, `completeSession` |
| `pendingLoginRules`: 404 `pending_login_not_found`, 404 `session_not_found` | `PendingLoginNotFoundException`, `PendingLoginSessionNotFoundException` | `completeSession` |
| `userNotFoundOn404Rule` (status only) | `UserNotFoundException` | `getUserInfo`, `createSessionOtp` |
| `voicemailNotConfiguredRule`, `voicemailMessageGoneRule` (`message_not_found`) | `VoicemailNotConfiguredException`, `VoicemailMessageGoneException` | the voicemail endpoints |
| `voicemailForwardRules`: `recipient_not_found`, `attachment_too_large`, `recipient_forward_limit_reached` | `VoicemailForward*Exception` | `forwardUserVoicemail` |
| `callQueueNotFoundRule` | `CallQueueNotFoundException` | the call queue endpoints |
| `systemNotificationGoneRule` (`notification_not_found`) | `SystemNotificationGoneException` | `markSystemNotificationAsSeen`, `deleteSystemNotification` |

Logging: a 4xx logs as `warning`, a 5xx or transport failure as `severe`;
`EndpointNotSupportedException` and `VoicemailNotConfiguredException` are not logged.

## Adding an endpoint

- A method in `api_client.dart` built on `_httpClientExecuteGet` / `Post` / `Patch` / `Delete`
  with `[..._apiBasePathSegmentsV1, ...]`, taking `RequestOptions options = const RequestOptions()`.
- An endpoint an adapter may lack passes `responseOptions: _optionalEndpoint`, or its own
  `ResponseOptions(optionalEndpoint: true, failures: [...])`.
- A failure that means something on this endpoint only: a `FailureRule` keyed on Core's `code`
  (a status alone only when the endpoint gives no code) in `api_failure_rules.dart`, a typed
  exception extending `RequestFailure` in `exceptions.dart`, and a static
  `ResponseOptions(failures: [...])` field on the client used by that method. Never add it to
  `defaultFailureRules`: that list is for what holds for every call.
- A refusal that hands data back reads it from `FailureContext.body` inside the rule, forgivingly
  (see `_sessionsOf`).

## Models

- `@freezed` + `json_serializable` with `FieldRename.snake`, exported from `models/models.dart`.
  Fields the backend may omit are nullable or have a default.
- An enum read from the wire always has a fallback: `@JsonKey(unknownEnumValue: X.unknown)`
  (`cdr.dart`, `user_session.dart`), or `X.values.asNameMap()[raw] ?? X.unknown` in hand-written
  code. Never `X.values.byName(raw)`: a value the app does not know yet then throws and takes the
  whole response with it.
- Several existing models do not follow this yet - `SystemNotification.type`, `UserInfo.status`,
  `UserContact.sipStatus`, `Favorite*.sourceType`, `SipSubscription*.type` decode without a
  fallback. Do not copy them.
- Never edit `*.freezed.dart` / `*.g.dart`; regenerate (skill `codegen-l10n`).

| Prefix | Domain |
|---|---|
| `Session*` | auth and session lifecycle |
| `User*` | the signed-in user, contacts, sessions, voicemail |
| `App*` | app status, contacts, push tokens |
| `System*` | system info, notifications |
| `Cdr*` | call detail records |
| `CallQueue*`, `CallerIdSettings` | call queues, caller id |
| `Favorite*`, `SipSubscription*` | server-side favorites and SIP subscriptions, batch sync |
| `IceServer*`, `SelfConfigResponse`, `ExternalPageAccessToken`, `Demo*` | the rest |

## Tests

- `MockClient` (`package:http/testing.dart`) or `mocktail`, never the network. Assert method, URL
  and headers, then answer with a status and a JSON body; one case per failure the endpoint maps.
- Patterns to follow: `api_client_failure_rules_test.dart`, `api_client_optional_endpoint_test.dart`,
  `api_client_session_rejection_test.dart`.
- The pre-push gate does not run these tests; Jenkins does. Run them yourself.

## Commands

From `phone/packages/api/`:

```bash
fvm dart test
fvm dart test test/api_client_failure_rules_test.dart
fvm dart test --name "buildTenantUrl"
fvm dart analyze
fvm dart run build_runner build --delete-conflicting-outputs
```
