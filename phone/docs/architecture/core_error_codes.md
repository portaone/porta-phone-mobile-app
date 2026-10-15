# Core Error Codes

How Core translates an adapter's refusal before it reaches the app, and which of the resulting
codes the app acts on. The short version: the app only ever sees Core's codes, and only the
`code` field of the body says whether the session is over - never the status alone.
Last reviewed: 2026-10-15.

## Adapter refusals in Core

Core does not react to a 401 from the adapter; it reacts to the `code` in the adapter's body.
The adapter's own code never reaches the client: Core either replaces it with one of its own or
passes the response through unchanged.

| Adapter answers Core | Core | Client receives |
|---|---|---|
| 401 `access_token_invalid` | marks the session invalid | 401 `token_invalid` |
| 401 `access_token_expired` or `session_upgrade_needed` | tries a refresh; on failure marks it expired | 401 `token_expired` |
| 404 `session_not_found` | marks the session missing | 401 `session_issue` |
| 401 with no code, or a code Core does not know | nothing, the session stays active | the same 401, adapter body unchanged |

Once a session is marked invalid, Core stops calling the adapter for it: every later request,
including the ones Core answers itself (`/app/status`), gets 401 `session_missing`.

## Failure rules in the app

The rules live in `packages/api/lib/src/api_failure_rules.dart`. `defaultFailureRules` hold
for every endpoint; an endpoint adds its own through `ResponseOptions.failures`, which are
checked first.

| Response | Exception | Session ends |
|---|---|---|
| 401 `session_missing` | `SessionMissingException` | yes |
| 401 `token_invalid` | `UnauthorizedException` | yes |
| 422 `refresh_token_invalid` | `UnauthorizedException` | yes |
| 404 `user_not_found` | `UserNotFoundException` | yes, with the "account not found" message |
| any status, `password_change_required` | `PasswordChangeRequiredException` | no, the caller words it |
| 5xx not claimed by another rule | `ServerFailureException` | no |
| anything else, including 401 `token_expired`, 401 `session_issue`, a bare 401 | `RequestFailure` | no |

`SessionMissingException`, `UnauthorizedException` and `UserNotFoundException` implement
`SessionRejection`. `WebtritApiClient` publishes each one on `sessionRejections`; `MainShell`
(`lib/app/router/main_shell.dart`) takes the first, shows `SessionExpiredNotification` or
`AccountNotFoundNotification`, and dispatches `AppLogoutRequested`. A caller needs no handling
of its own for the session to close. The rules are pinned by
`packages/api/test/api_client_failure_rules_test.dart` and
`packages/api/test/api_client_session_rejection_test.dart`.

The session-create endpoint is the one place a bare 401 means something:
`incorrectCredentialsOn401Rule` reads it as wrong credentials, because the adapters disagree on
the code and the PortaSwitch one sends none.

## Signaling

The signaling socket reports a lost session as close code 4201
(`SignalingDisconnectCode.sessionMissedError`). `CallBloc` hands it to
`SessionInvalidationHandler`, which asks `SessionVerifier` to probe the REST API
(`getRemoteInfo`) for a more specific reason: a password change gives its own logout reason, a
REST session rejection leaves the logout to the shell, anything else logs out as
`AppLogoutReason.sessionMissed`. The signaling report itself is treated as final.

Observed on Core, not enforced by the app:

- A 401 with no code leaves SIP registration and calls working: the signaling controller takes
  SIP credentials from a cache in Core when the adapter refuses.
- A session marked invalid gives 4201 on a new connection, but a socket opened before that is
  not closed by Core (watched for 40 seconds).

## Traps

**A rule on an adapter code.** What you do: add a rule for `access_token_invalid` or another
adapter code. What happens: it never fires; the logout happens on `session_missing` instead.
Why: Core replaces adapter codes before the response leaves it. Instead: match Core's codes
only - `token_invalid`, `token_expired`, `session_missing`, `session_issue`.

**Logging out on any 401.** What you do: treat every 401 as the end of the session. What
happens: a refusal of one operation signs the user out. Why: Core passes a bare adapter 401
through unchanged, and the adapter uses that for refusals of the request itself. Instead: end
the session only on a recognised code, through a `SessionRejection`; declare an endpoint's own
meaning of a bare 401 on that endpoint, as the session-create rule does.

**An adapter that ends a session with a bare 401.** What you do: have an adapter refuse a
deactivated account or tenant with a 401 and no code. What happens: Core keeps the session
active, the app keeps it too, and calls go on working. Why: Core reads a 401 without a known
code as a failure of the request, not of the session. Instead: the adapter must answer with a
code Core knows (`access_token_invalid`, `session_not_found`).
