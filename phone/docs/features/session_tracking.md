# Session tracking

The settings screen that lists the sessions the account is signed in with and
lets the user sign the other ones out; and the screen shown at login when the
account is signed in on as many devices as it is allowed.

Last reviewed: 2026-10-15

## Where it lives

- `lib/features/settings/features/sessions/` - the whole feature:
    - `cubit/sessions_cubit.dart` - `SessionsCubit` + `SessionsState`.
    - `view/sessions_screen_page.dart` - `@RoutePage`; refreshes the shared
      cubit on open and passes the `DateFormat` taken from `AppTime`.
    - `view/sessions_screen.dart` - app bar, pull-to-refresh list, placeholders
      (how every list refreshes: [`../architecture/data_refresh.md`](../architecture/data_refresh.md)).
    - `view/widgets/` - the idle-sessions row and the sheet it opens, with
      the page "Other..." opens inside it for a number of days of one's own.
- `lib/features/settings/view/settings_router_page.dart` - owns the
  `SessionsCubit`, above both the settings screen and the sessions screen.
- `lib/features/settings/view/settings_screen.dart` - the settings row
  with the session-count badge.
- `lib/repositories/sessions/sessions_repository.dart` - `SessionsRepository`
  and its API implementation.
- `lib/widgets/session_tile.dart` - one session row, shared with the device
  limit screen of the login.
- `lib/models/active_session.dart` - `ActiveSession`, the domain model.
- `lib/models/session_auto_terminate.dart` - `SessionAutoTerminate` (when idle
  sessions end), `SessionList` (one answer of the list) and the refusals.
- `lib/mappers/api/active_session_mapper.dart` - `api.UserSession` ->
  `ActiveSession`.
- `packages/api` - `getUserSessionList` / `deleteUserSession` /
  `updateUserSessionsSettings` and the `UserSession`, `UserSessionList` and
  `UserSessionsAutoTerminate` DTOs.

## Backend contract

| Endpoint                        | Purpose                                                     |
|---------------------------------|-------------------------------------------------------------|
| `GET /user/sessions`            | All active sessions of the current user, `current` flagging the caller's own |
| `DELETE /user/sessions/{id}`    | Revokes one session and tears down its SIP registration; 404 `session_not_found` when it is not the user's |
| `PUT /user/sessions/settings`   | After how many idle days the user's sessions end; `null` returns to the installation's period |

A session carries the `User-Agent` captured at creation, the app type /
identifier / bundle id, the creation and last-activity timestamps, and two ISO
3166-1 alpha-2 country codes: `location` (resolved once, at creation) and
`last_activity_location` (resolved per request, so it can differ for a roaming
device).

## What labels a session: the User-Agent the app sends

The core simply reads the `user-agent` request header when it creates the
session (`WebtritCoreWeb.ClientInfo.user_agent/1`) and stores it as received -
nothing is parsed or validated server-side. Whatever the app sends is what the
user later reads in this list, so the app sends its own value instead of
leaving the platform default (`Dart/3.x (dart:io)`).

`WebtritApiClient` takes a `userAgent` and puts it on every request.
It is filled from the same string presence uses as its device name -
`AppMetadataProvider.userAgent`, format
`AppName/AppVersion (DeviceName; OSName: OSVersion)` - so a device is labelled
identically in both places. `DefaultAppMetadataProvider.buildUserAgent` holds
that format and is also called directly in `bootstrap`, which builds the API
client factory before the provider exists (the provider needs `featureAccess`).

`DeviceName` is the name a person knows the device by (`Samsung Galaxy XCover
5`, `iPhone 12 mini`), read by the `device_display_name` plugin into
`DeviceInfo.displayName`; the platform model (`SM-G525F`, `iPhone`) is sent only
where the plugin gives no name. The name the user gave the device is never
used: it can carry a person's name, and the core stores and logs the header.
`buildUserAgent` escapes the name for the header: `;` becomes `,`, parentheses
become brackets, anything outside ASCII is percent-encoded as UTF-8
(`Uri.decodeComponent` turns it back). The core keeps the User-Agent a session
was created with, so a session opened by an older build shows its name only
after that device signs in again.

Wired at every client that can create a session:

| Site                                     | Path                                    |
|------------------------------------------|-----------------------------------------|
| `WebtritApiClientFactory`                | login / OTP / session refresh / signout |
| `main_shell.dart` `WebtritApiClient`      | the authenticated app client            |
| `AutoprovisionCubit`                     | autoprovisioned login                   |

Not wired: the background client in `bootstrap` that fetches system
notifications - it never creates a session, and building the string there would
mean re-initialising package/device info inside the isolate.

On web the header is left to the browser: `User-Agent` is a forbidden header
name there, so the value is dropped rather than sent.

## Entry point and version gate

The row sits in the fixed group at the top of the settings screen and is
deliberately NOT a configurable settings item: there is no `sessions` type in
`app.config.json` and no `SettingsFlavor` for it. It carries a `CountBadge` with
the number of active sessions, which stays blank until the list has loaded, and
the count is spoken after the row's own name. Logging out is not next to it any
more - it is an action in the app bar of that screen.

Both endpoints are core endpoints with no adapter involvement, so there is no
capability flag to advertise them. Availability is decided by the core version
instead: `SettingsMapper` sets `SettingsConfig.sessionsEnabled` from
`CoreInfo.supportsSessionTracking` (`>=0.35.0-alpha <2.0.0`), and
`SettingsScreen` hides the row when it is false, rather than opening a screen
that cannot load.

## Behaviour

- `SettingsRouterPage` provides the `SessionsCubit` above both screens, so the
  badge and the list are one state: revoking a session on the sessions screen
  updates the badge immediately.
- The list is fetched when the settings router is entered, again when the
  sessions screen opens, and on pull-to-refresh. Nothing is cached locally and
  nothing polls: a session list is only interesting while the user is looking
  at it.
- A failed fetch keeps whatever was already loaded and only shows the failure
  placeholder when there is nothing to show.
- The current session gets a "This device" chip and no revoke action - signing
  this device out is what logout in settings is for.
- Revoking removes the row on success and reports failure through a snack bar,
  leaving the row in place.
- "Sign out other sessions" revokes every non-current session one by one, since
  the core has no bulk endpoint. Each success drops its own row, so a partial
  failure still shows exactly what survived; the snack bar reports that
  something failed.

## Idle sessions (WT-2103)

The core (WT-1789) ends a session that has seen no request, no signaling
connection and no signaling message for longer than a period: the
installation's (`SESSION_INACTIVITY_TIMEOUT_DAYS`, 90 by default, none at
`0`), or a shorter one the user chose where the adapter reports
`sessionAutoTerminate`.

The list answer carries `auto_terminate`:
`{inactivity_timeout_days, installation_max_days}`. The first is the period in
force - the shorter of the user's choice and the installation's - not the
choice itself, so a choice equal to the installation's period reads the same as
no choice, and an administrator lowering the limit below a choice simply shows
the lower one. Either is `null` when there is none. A core without WT-1789
sends no `auto_terminate` and the screen shows nothing new.

| Adapter has `sessionAutoTerminate` | Period in force | Above the list |
|------------------------------------|-----------------|----------------|
| yes                                | any             | the row "End inactive sessions" with the period ("Never" for `null`); a tap opens the sheet |
| no                                 | N days          | the line "Inactive sessions end after N days", no action |
| no                                 | `null`          | nothing |

The sheet offers "Default (<installation's period>)", the presets 1 week / 1
month / 3 months shorter than the installation's period (one equal to it is the
default, a longer one the core refuses; 365 days caps them where there is no
limit), the period in force as a row of its own when it is none of those (set
by another client), and "Other..." - a page inside the sheet (the list slides
away; back, its arrow or the system one, returns to the list) with a field for
a number of days from 1 to the limit (or 365), saved by its own button. A note says the limit is the administrator's when there is one.

A pick is saved at once with `PUT /user/sessions/settings` and the sheet waits
for the answer, the picked row showing progress; it closes when the core
answered and the row shows what the core now holds. Nothing is shown as saved
before that. The outcome is reported by the screen rather than
by the sheet, so a failure is still said - with its retry - when the sheet was
dragged away while the core was being asked. On a refusal of the period itself - 422
`exceeds_installation_limit` (the limit was lowered while the screen was open)
or 501 `functionality_not_implemented` (the adapter stopped letting users
choose) - the screen reloads and says so; any other failure (503
`external_api_issue`, no network) keeps the period that was in force and offers
to try again from the snack bar.

The capability comes from `system-info`, which the running app reads at start:
an adapter that turns `sessionAutoTerminate` on or off is picked up at the next
start, and until then the core's 501 covers a row shown by mistake.

## Device limits at login

A PortaPhone package can limit how many devices an account is signed in on and
how many new devices it starts using within a period. The backend checks both
after it has accepted the credentials, on every call that ends in a session.

| Answer                                                                              | What the app does                                                                                                                                             |
|-------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 409 `device_limit_reached`, with the account's sessions and a `pending_login_token` | The login waits: the device limit screen lists the devices; signing one out finishes the login with `POST /session/complete`, no password or code asked again |
| the same without a token                                                            | Message: device limit reached, contact your administrator                                                                                                     |
| 403 `device_switch_limit_reached`                                                   | Message: device switch limit reached, contact your administrator                                                                                              |
| `/session/complete`: 409 again                                                      | The list is replaced by the one in the answer, with a message                                                                                                 |
| `/session/complete`: 404 `session_not_found`                                        | That device leaves the list; the token is still good                                                                                                          |
| `/session/complete`: 404 `pending_login_not_found`                                  | Back to where the login started, with a message                                                                                                               |

- `packages/api` names the refusals (`DeviceLimitReachedException`,
  `DeviceSwitchLimitReachedException`, `PendingLoginNotFoundException`,
  `PendingLoginSessionNotFoundException`) and has `completeSession`.
- `lib/repositories/auth/auth_repository.dart` turns the first into
  `LoginDeviceLimitReached` carrying a `PendingLogin` (`lib/models/pending_login.dart`):
  the token, the devices as `ActiveSession` and the tenant of the refused request.
- `lib/features/login/cubit/login_cubit.dart` keeps the waiting login in
  `LoginState.pendingLogin`. The screen is there for as long as it is set; the
  app keeps no time of its own - the backend says when the wait is over.
- `lib/features/login/view/login_device_limit_screen.dart` - the screen, the
  last route of `LoginRouterPage`. It cannot be left while a device is being
  signed out.

A one-time code that led to a refusal was accepted and is spent, so the flow
that verified it returns to where a code is requested. Auto-provision does not
handle these answers yet.

Known limit of the backend: with the account over its limit by two or more
devices, signing one out is rolled back and the same list comes again, so the
login cannot be finished from the app.

The identifier that tells one device from another is described in
[`../architecture/startup.md`](../architecture/startup.md) (`app-info`).

## Tests

- `packages/api/test/api_test.dart` - the two endpoints,
  including an unknown session status and the 404 `session_not_found` body, plus
  the `User-Agent` header being sent (and omitted when the app provides none).
- `test/data/app_metadata_provider_test.dart` - the User-Agent format and that
  it is the same string presence uses as the device name.
- `test/features/settings/features/sessions/cubit/sessions_cubit_test.dart` -
  fetch, single revoke, revoke-all-others incl. partial failure.
- `test/widgets/session_tile_test.dart` -
  row title per app type, current-session badge, revoke action.
- `test/data/settings_mapper_test.dart` - the core-version gate behind
  `sessionsEnabled`.
- `test/app/core_version_test.dart` - `supportsSessionTracking` boundaries.
- `test/features/login/login_cubit_device_limit_test.dart`,
  `test/features/login/login_device_limit_semantics_test.dart`,
  `test/repository/auth_repository_device_limit_test.dart`,
  `packages/api/test/api_client_device_limits_test.dart` - the device limits
  at login.
