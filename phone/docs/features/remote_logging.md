# Remote logging

How the app sends its logs to WebTrit Core: the core decides through its system
info, the app buffers until it knows, and the decision outlives logout.

Last reviewed: 2026-11-12

## Where it lives

- `lib/common/logging/core_remote_logging_service.dart` - `CoreRemoteLoggingService`,
  the state machine behind `RemoteLoggingService`.
- `lib/common/logging/remote_logging_config.dart` - `RemoteLoggingConfig`: the
  settings in effect, bound to the address they post to.
- `lib/common/logging/remote_logging_config_store.dart` - the copy in shared
  preferences (`remote-logging-config`).
- `lib/common/logging/filtered_logz_io_appender.dart` - the sender. It posts
  the newline-delimited JSON of `LogzIoApiAppender` as `application/json` to the
  endpoint with `?type=flutterlog` and nothing else in the query: the receiver
  takes no credential from the app, and the request line ends up in its log.
  It batches on its own (see Sending) and never posts an empty body.
- `lib/data/app_logger.dart` - sets the root logger level to the lower of the
  local level and the level remote logging sends from.
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
- An absent block (an older core), a block that cannot be read (a date that
  does not parse, a flag sent as a string), `enabled: false`, and a missing or
  invalid `path` (one with a scheme or a host, a query or a fragment) all mean
  disabled.
- `level` is a `package:logging` level name; without one the app uses
  `WEBTRIT_APP_REMOTE_LOGZIO_LOG_LEVEL`.
- `anonymization` defaults to true when the core does not send it.
- Records are posted to the tenant URL of the core (`<core>/tenant/<id>` for a
  non-empty tenant id, as `WebtritApiClient.tenantUrl` builds it) followed by
  `path`, without the query and the credentials the core URL may carry.

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
  appender; the old one sends what it holds first. A config that moves only
  `expires_at` reschedules the end and keeps the appender, and the same config
  again changes nothing and is not stored again.
- New labels replace the appender; the same labels again (the shell asks on
  every build) do not.
- After `dispose` the service ignores every config and label update.
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

## Levels

The root logger drops a record before any appender sees it, so `AppLogger`
sets it to the lower of the local level (`feature_log_level`, app config) and
the level remote logging sends from while it is enabled, and recomputes it
whenever that changes. The console keeps the local level; the log file on the
device follows the root logger and so also holds the lower level while a core
asks for it.

## Sending

A batch is posted once it holds `WEBTRIT_APP_REMOTE_LOGZIO_LOGGING_BUFFER_SIZE`
records (default 100), or 10 seconds after its first record. The records held
while the config was unknown go out the same way, in full batches. `dispose`
sends what is still batched and waits for it before it closes the HTTP client;
`discard` (logging switched off or expired) drops it.

## Anonymization

`AnonymizingFormatter` masks the message, the error text and the stack trace
(emails, IP addresses, ports, phone numbers, JWTs and Core session tokens, the
`token`, `access_token` and `refresh_token` fields, SIP URI user parts and the
known personal JSON fields), and the error text of the `e` label. Remote text
carries no colour codes, so a rule anchored at a word boundary also sees what
opens the message.

## Redesign / in progress

- Records logged before `AppLogger.init` in `bootstrap()` are not buffered.
- Autoprovisioning fetches system info with its own client, outside the
  datasource; its config arrives with the first poll after sign-in.
- The logged-out app does not fetch system info at start on its own; with no
  stored config it buffers until the login flow asks a core.
- A background isolate reads the stored config once, when it starts; a change
  the app stores while the isolate runs reaches it only at its next start.
