# Remote logging

How the app sends its logs to WebTrit Core: the core decides through its system
info, the app buffers until it knows, and the decision outlives logout.

Last reviewed: 2026-11-10

## Where it lives

- `lib/common/logging/core_remote_logging_service.dart` - `CoreRemoteLoggingService`,
  the state machine behind `RemoteLoggingService`.
- `lib/common/logging/remote_logging_config.dart` - `RemoteLoggingConfig`: the
  settings in effect, bound to the address they post to.
- `lib/common/logging/remote_logging_config_store.dart` - the copy in shared
  preferences (`remote-logging-config`).
- `lib/common/logging/filtered_logz_io_appender.dart` - the sender. The log
  receiver of the core accepts the newline-delimited JSON of `LogzIoApiAppender`
  and ignores its `token` query parameter.
- `lib/common/logging/anonymizing_formatter.dart` - what is masked when the core
  asks for anonymization.
- `lib/repositories/system_info/system_info_remote_datasource.dart` - `onFetched`,
  through which every system info answer reaches the service.

## The source of truth

`GET /api/v1/system-info` (no authentication) carries, under `core`:

```json
"mobile_remote_logging": {
  "available": true,
  "enabled": true,
  "level": "INFO",
  "anonymization": true,
  "expires_at": "2026-11-12T00:00:00Z",
  "path": "/mobile-logs"
}
```

- `enabled` is the effective value; the app does not combine it with anything.
- An absent block (an older core), `enabled: false` or no `path` mean disabled.
- `level` is a `package:logging` level name; without one the app uses
  `WEBTRIT_APP_REMOTE_LOGZIO_LOG_LEVEL`.
- `anonymization` defaults to true when the core does not send it.
- Records are posted to the tenant URL of the core (`<core>/tenant/<id>` for a
  non-empty tenant id, as `WebtritApiClient.tenantUrl` builds it) followed by
  `path`.

Firebase Remote Config no longer switches remote logging or anonymization, and
there is no build-time log endpoint or token.

## States

| State | Records |
|-------|---------|
| unknown | held in memory, at most 2000, oldest dropped first; nothing sent |
| enabled | sent from the configured level up, anonymized if asked |
| disabled | dropped; the held records are discarded |

- unknown -> enabled: the held records go out first, filtered by level.
- enabled -> disabled (the core says so, or `expires_at` passes): the appender
  is discarded without sending the records it still batches.
- A changed config while enabled (level, anonymization, endpoint) replaces the
  appender.
- `expires_at` is checked on the device, on every record and by a timer, so
  logging stops on time even when the core cannot be reached.

## When the config is known

- Cold start: the stored config applies at once. Without one the service waits
  in `unknown` for the first system info answer.
- Login screen: the system info the login flow fetches for the entered core
  passes through `SystemInfoRemoteDatasource`, so the config is known before
  sign-in.
- Signed in: the system info polling of `MainShell` (boot, resume, every 5
  minutes) applies each answer.
- Logout: the system info cache is cleared, the logging config is not; the
  logged-out app keeps the last answer until a core says otherwise.
- Background isolates (`IsolateContext`): the stored config only. An isolate
  never asks the core, so without a stored config it sends nothing and holds
  nothing.

## Anonymization

`AnonymizingFormatter` masks the message, the error text and the stack trace
(emails, IP addresses, ports, phone numbers, tokens, SIP URI user parts and the
known personal JSON fields).

## Redesign / in progress

- Records logged before `AppLogger.init` in `bootstrap()` are not buffered.
- Autoprovisioning fetches system info with its own client, outside the
  datasource; its config arrives with the first poll after sign-in.
- The logged-out app does not fetch system info at start on its own; with no
  stored config it buffers until the login flow asks a core.
