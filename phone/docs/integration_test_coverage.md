# Integration Test Coverage

The native scenarios below live in `patrol_test/` and use [Patrol](https://patrol.dev/).
Companion host integration suites are linked where available and run in ordinary `flutter test`.
App-flow tests bootstrap the full app and log in or reuse an existing session.
Focused native-integration guards may construct only the services under test.
Every test tears down its device state.
Last reviewed: 2026-09-11.

---

## Login

**File:** `patrol_test/login_system_test.dart`

Three independent tests — each skipped automatically if the required credentials are absent in the environment.

| Test | Credential variables required |
|------|-------------------------------|
| Login by email | `WEBTRIT_APP_TEST_EMAIL_CREDENTIAL`, `WEBTRIT_APP_TEST_EMAIL_VERIFY_CREDENTIAL` |
| Login by OTP | `WEBTRIT_APP_TEST_OTP_CREDENTIAL`, `WEBTRIT_APP_TEST_OTP_VERIFY_CREDENTIAL` |
| Login by password | `WEBTRIT_APP_TEST_PASSWORD_USER_CREDENTIAL`, `WEBTRIT_APP_TEST_PASSWORD_PASSWORD_CREDENTIAL` |

**Steps (shared structure):**
1. Bootstrap app and wait for `AppShell`.
2. Optionally navigate to a custom core URL (`WEBTRIT_APP_TEST_CUSTOM_CORE_URL`).
3. Enter credentials for the chosen method and confirm.
4. Accept agreements and permissions until `MainShell` is visible.
5. Wait 5 seconds on the main screen.
6. Log out and verify return to `LoginModeSelectScreen`.

---

## Profile & SIP Registration

**File:** `patrol_test/profile_and_registration_test.dart`

**Verifies:** Account info is displayed correctly and SIP re-registration works.

**Steps:**
1. Log in if needed.
2. Open the profile screen via the main app bar.
3. Verify account name (`WEBTRIT_APP_TEST_ACCOUNT_NAME`) appears in `UserInfoListTile`.
4. Verify main number (`WEBTRIT_APP_TEST_ACCOUNT_MAIN_NUMBER`) appears in `UserInfoListTile`.
5. Verify `SessionStatus` shows `CallStatus.ready` (registered).
6. Toggle the registration `SwitchListTile` off — verify status changes to `CallStatus.appUnregistered`.
7. Toggle it back on — verify status returns to `CallStatus.ready`.

---

## Contacts — External Tab

**File:** `patrol_test/contacts_ext_tab_test.dart`

**Verifies:** Contact search and tab navigation in the PBX contacts screen.

**Steps:**
1. Log in if needed.
2. Navigate to the Contacts tab.
3. Switch between local and external contact tabs.
4. Search with `WEBTRIT_APP_TEST_EXT_CONTACT_MULTI_SEARCH_QUERY` — verify more than one result appears.
5. Search by `WEBTRIT_APP_TEST_EXT_CONTACT_A_UNIQUE_NAME` — verify only contact A appears.
6. Search by `WEBTRIT_APP_TEST_EXT_CONTACT_A_UNIQUE_NUMBER` — verify only contact A appears.
7. Search by `WEBTRIT_APP_TEST_EXT_CONTACT_B_UNIQUE_NAME` — verify only contact B appears.
8. Search by `WEBTRIT_APP_TEST_EXT_CONTACT_B_UNIQUE_NUMBER` — verify only contact B appears.

---

## Contacts — Detail View

**File:** `patrol_test/contacts_details_test.dart`

**Verifies:** Contact detail fields are shown correctly and calling from a contact works.

**Steps (repeated for contact A and contact B):**
1. Log in if needed.
2. Navigate to Contacts → External tab.
3. Search for the contact if not already visible.
4. Tap the contact tile to open the detail view.
5. Verify ext number, main number, additional number, SMS number, and email address are displayed (fields are optional — skipped if the corresponding variable is empty).
6. Initiate a call from the detail view and verify it connects.
7. Navigate back to the contacts list.

---

## Favorites

**File:** `patrol_test/favorites_tab_test.dart`

**Verifies:** Adding, persisting, calling from, and removing favorites.

**Steps:**
1. Log in if needed.
2. Check which of contact A and B are already in favorites (to avoid duplicates).
3. Add contact A to favorites if not already there.
4. Add contact B to favorites if not already there.
5. Verify both contacts appear in the Favorites tab.
6. Log out and log back in — verify favorites persisted.
7. Open contact A's context menu (three-dots icon) — verify actions: "Audio call", "Video call", "View Contact", "Delete".
8. Tap "Audio call" for contact A — verify the call connects after 5 seconds.
9. Delete contact A from favorites via the menu.
10. Open contact B's context menu (long-press) — verify the same four actions.
11. Tap "Audio call" for contact B — verify the call connects after 5 seconds.
12. Delete contact B from favorites via long-press menu.
13. Verify the Favorites tab is empty.
14. Log out and log back in — verify deletion persisted.

---

## Incoming Call — Answer via App UI

**File:** `patrol_test/call_answer_via_app_ui_test.dart`

**Verifies:** Answering an incoming call using the in-app call screen.

**Steps:**
1. Log in if needed.
2. pjsua companion places an incoming call to the app using contact A's SIP credentials.
3. Wait for `CallActiveScaffold` to appear.
4. Tap the answer button (green phone icon) in the app UI.
5. Verify the call is active (call timer shows `00:0`).
6. Remote side hangs up.
7. Verify `CallActiveScaffold` disappears.

---

## Incoming Call — Answer via Foreground Push

**File:** `patrol_test/call_answer_via_foreground_push_test.dart`

**Verifies:** Answering an incoming call via push notification while the app is in the foreground.

**Steps:**
1. Log in if needed.
2. pjsua companion places an incoming call (app remains in the foreground).
3. Verify a push notification appears with text "You have an incoming call from …".
4. Open the notification shade and tap "Answer".
5. Verify the call is active.
6. Remote side hangs up.
7. Verify `CallActiveScaffold` disappears.

---

## Incoming Call — Answer via Background Push

**File:** `patrol_test/call_answer_via_background_push_test.dart`

**Verifies:** Answering an incoming call via push notification while the app is in the background.

**Steps:**
1. Log in if needed.
2. Press the Home button — app moves to the background.
3. pjsua companion places an incoming call.
4. Verify a push notification appears with text "You have an incoming call from …".
5. Open the notification shade and tap "Answer".
6. Verify the call is active.
7. Remote side hangs up.
8. Verify `CallActiveScaffold` disappears.

---

## Active Call Push Notification

**File:** `patrol_test/call_active_call_push_test.dart`

**Verifies:** The ongoing-call push notification is shown and can be used to hang up.

**Steps:**
1. Log in if needed.
2. pjsua companion places an incoming call.
3. Answer the call via the app UI (green phone icon).
4. Verify a persistent push notification with the text "Active call" is present.
5. Tap the "Hung up" action on the notification.
6. Verify `CallActiveScaffold` disappears.

---

## Outgoing Call — From Keypad

**File:** `patrol_test/call_outgoing_from_keypad_test.dart`

**Verifies:** Placing an outgoing call by dialling a number on the keypad.

**Steps:**
1. Log in if needed.
2. pjsua companion registers with auto-answer enabled.
3. Navigate to the Keypad tab.
4. Enter the callee number digit by digit via `KeypadKeyButton`.
5. Tap the call button.
6. Verify the call connects (`CallActiveScaffold` visible, timer running).
7. Tap the hang-up button.
8. Verify `CallActiveScaffold` disappears.

---

## Outgoing Call — Sub-functions

**File:** `patrol_test/call_outgoing_subfunctions_test.dart`

**Verifies:** In-call controls: minimize/restore, mute, speaker, hold, and video.

**Steps:**
1. Log in if needed.
2. Place an outgoing call to the external contact (pjsua auto-answers).
3. Swipe back to minimize the call — verify `CallActiveThumbnail` appears.
4. Tap the thumbnail to restore the full call screen.
5. **Mute:** tap the mute button — verify `Icons.mic_off`; tap again — verify `Icons.mic`.
6. **Speaker:** tap the speaker button — verify `Icons.volume_up`; tap again — verify `Icons.phone_in_talk`.
7. **Hold:** tap the hold button — verify "On hold" text appears; tap again — verify the timer resumes.
8. **Video:** tap the video-call button — verify the front-camera preview appears and the video renderer is active.
9. Hang up the call.

---

## Recent Calls

**File:** `patrol_test/call_recents_test.dart`

**Verifies:** Recent call entries are created and ordered correctly after each call.

**Steps:**
1. Log in if needed.
2. pjsua companion (contact A) places an incoming call → app answers → remote hangs up.
3. Navigate to the Recents tab.
4. Verify contact A appears first with an incoming call icon.
5. pjsua companion (contact B) places an incoming call → app answers → remote hangs up.
6. Verify order: contact B first (incoming), contact A second (incoming).
7. Place an outgoing call to contact A by tapping their recents tile.
8. Verify order: contact A first (outgoing, `Icons.call_made`), contact B second (incoming), contact A third (incoming).
9. Verify contact names are displayed correctly throughout.

---

## Background Polling - User Repository Refresh

**File:** [user_repository_refresh_test.dart](../patrol_test/user_repository_refresh_test.dart)

Two focused native-integration tests compose the real `UserRepository`, API
client, remote/local datasources, mappers, preferences plugin and `PollingService`,
with `UserInfoSyncWorker` registered as the polling listener over that repository.
Only HTTP responses and connectivity eligibility are controlled. They do not
bootstrap the full app, log in, contact a backend or toggle device connectivity.

1. Two HTTP 503 responses retain the cached user and delay automatic retries
   by 2 and 4 seconds with a one-second test interval and zero jitter. Recovery
   persists the mapped user, emits one data update and restores the base cadence.
   Reloading native preferences verifies the value beyond the in-memory cache.
2. HTTP 401 `token_invalid` is published on the client's `sessionRejections`
   and reaches the manual caller as a failed task, without overwriting the native
   cache or retrying HTTP. This verifies the report, not the full app logout flow.

Teardown restores the previous `user-info` preference and disposes the polling
service. To retain unrelated application data, follow the
[runner configuration and no-uninstall instructions](integration_test_commands.md#run-the-user-repository-refresh-guards).

The companion [host integration suite](../test/repository/user_repository_integration_test.dart)
runs in ordinary `flutter test`/CI with an in-memory preferences backend. It also
covers HTTP 429, transport retry exhaustion, original timeout/stack propagation,
`session_missing`, `user_not_found`, invalid payloads and cache replay. Exact
20/40/10-second scheduling assertions use virtual time. The
[worker unit tests](../test/features/user_info/user_info_sync_worker_test.dart)
cover injected persistence failures and delayed-write completion through the
worker over the real repository; these native tests do not simulate a device
storage failure.

---

## Startup - An Unreachable Core With No Cache

**File:** [core_unreachable_recovery_test.dart](../test/app/router/core_unreachable_recovery_test.dart)

A host suite over the real system-info pipeline (repository, datasources,
mapper and API client against a refusing HTTP client), the real `AppBloc`
teardown sequence and the real route guards. Only the session, cleanup and
agreement repositories are mocked.

The state under test is the one a storage move leaves behind: the session
survives, the system-info cache does not. It is harmless while the core
answers - the next fetch refills the cache - and it is the one state the main
shell cannot be built from when the core does not.

1. An authenticated start with an empty cache reaches the network, is refused,
   and ends the session with `AppLogoutReason.coreUnreachable`: the teardown
   screen replaces the stack, local cleanup runs, the remote session is left
   alone, and the teardown guard hands the user to login - where another core
   can be entered. Routing to login directly instead is what used to spin
   between the two guards on a white screen; leaving the stack unreplaced is
   the same white screen with the session ending behind it.
2. The same dead core with a cached value signs nobody out: the guard reads the
   cache, never reaches the network, and the session stays authenticated.
3. A second guard pass while the teardown runs does not start another one.

The device counterpart is
[core_unreachable_recovery_test.dart](../patrol_test/core_unreachable_recovery_test.dart):
it seeds native storage with a session pointing at a port nothing listens on and
no cached system info, boots the real app, and waits for the login screen. It
drives the real navigator, which is what the host suite cannot stand in for -
`replaceAll` returning is not the same thing as a screen being on the display,
and that gap is exactly where the first attempt at this fix left a white screen.
DESTRUCTIVE: it signs the device out and clears local application data, so run
it on a device whose session you are willing to lose.

---

## Background Polling - Voicemail Refresh

**File:** [voicemail_repository_refresh_test.dart](../patrol_test/voicemail_repository_refresh_test.dart)

Two component-integration guards compose the real API client, voicemail
repository/mappers, polling service and file-backed SQLite on the device.
HTTP responses, connectivity eligibility and cache-boundary faults are controlled;
these are not live-backend E2E, OS connectivity or physical disk-failure tests.

1. An automatic HTTP 503 fails both polling and direct-fetch joiners with the
   same error and stack, even when cache fallback also fails. The cached row
   survives. The retry starts after two seconds with a one-second test interval;
   the cycle remains running until the gated SQLite write finishes.
2. HTTP 401 releases both a polling joiner and a waiting delete with the same
   failure, is published once on the client's `sessionRejections`, and leaves
   the cached row untouched. This verifies the report, not the full application
   logout flow.

Each scenario uses an isolated temporary database and removes it in teardown.
The application's database is never opened. Use the
[safe runner configuration](integration_test_commands.md#run-the-voicemail-refresh-guards)
to retain unrelated application data.

The [host integration suite](../test/repository/voicemail_repository_integration_test.dart)
also covers failed detail requests, failed writes, delayed persistence and
unsupported/unconfigured voicemail. The
[unit contract suite](../test/repository/voicemail_refresh_contract_test.dart)
covers every waiting mutation, eager-fetch error ownership, inactive no-work
and exact 20/40/10-second backoff recovery in virtual time.

---

## Background Polling - Favorites Refresh

**File:** [favorites_repository_refresh_test.dart](../patrol_test/favorites_repository_refresh_test.dart)

Two component-integration guards use the real repository, API client/mapping,
polling and isolated file-backed SQLite on the device. HTTP responses and
connectivity eligibility are controlled; these are not live-backend E2E or OS
connectivity/disk-failure tests.

1. Two failed HTTP 503 pulls preserve the cached favorite and delay automatic
   retries by two and four seconds with a one-second test interval. Recovery
   persists the response, restores the base cadence and sends an ETag on the
   next GET; a `304` leaves the stored snapshot intact.
2. A local add succeeds despite a failed immediate batch sync and leaves a
   durable outbox action. An automatic retry fails as a task and increases the
   entry's attempt count. A later backed-off success drains the outbox and
   writes the server snapshot to SQLite.

Each scenario removes only its own temporary database in teardown. Follow the
[safe runner instructions](integration_test_commands.md#run-the-favorites-refresh-guards)
to preserve unrelated application data.

The [host integration suite](../test/repository/favorites_repository_integration_test.dart)
shares the same API/SQLite harness and additionally covers 401/429, invalid
payloads and request-body mapping. The
[contract tests](../test/repository/favorites_repository_test.dart) cover
original errors/stacks, persistence ordering, bookkeeping failures, local
mutations and exact backoff recovery with virtual time.

---

## Background Polling - SIP Subscriptions Refresh

**File:** [sip_subscriptions_repository_refresh_test.dart](../patrol_test/sip_subscriptions_repository_refresh_test.dart)

Two component-integration guards compose the real API client, mapping,
repository, polling service and isolated file-backed SQLite. HTTP responses
and connectivity eligibility are controlled; no account, live backend, app
bootstrap, OS network toggle or application database is involved.

1. Two HTTP 503 pulls retain cached subscriptions and delay automatic retries
   by two and four seconds with a one-second test base and zero jitter.
   Recovery persists the new snapshot, restores the base cadence, and sends
   the ETag on a later GET; `304` preserves the stored subscriptions.
2. A local upsert survives an immediate failed batch sync and retains a durable
   outbox entry. A failing polling cycle increments its attempt count; a later
   backed-off success drains the outbox and persists the server snapshot.

The [host integration suite](../test/repository/sip_subscriptions_repository_integration_test.dart)
also covers 401/429, malformed payloads, and deletion of a presence subscription
with its resolved contact user ID preserved across retries. The
[unit contract tests](../test/repository/sip_subscriptions_repository_test.dart)
cover injected write/acknowledgement failures, original errors and stacks,
secondary bookkeeping failures, disabled sync and exact virtual-time backoff.
They do not simulate a physical disk failure or change the production backoff cap.

Each native scenario removes only its own temporary database. Follow the
[safe runner instructions](integration_test_commands.md#run-the-sip-subscriptions-refresh-guards).

---

## Background Polling - System Info Persistence

**File:** [system_info_repository_refresh_test.dart](../patrol_test/system_info_repository_refresh_test.dart)

The native scenario composes the real repository, remote/local datasources,
API client, mappers, preferences plugin and polling service. The client factory
returns that test client; HTTP and a hook before the preferences write are
controlled. The hook is not a simulation of native filesystem failure.

1. Return HTTP 200 but fail the cache-write boundary. The task must report the
   original failure while keeping the old cache and leaving `infoStream` silent.
2. Allow the automatic retry after two seconds (one-second test base interval).
   Hold persistence and verify the successful HTTP response has not published
   data or completed the cycle yet.
3. Release the write, await success and one data update, then reload native
   preferences to verify that the new snapshot was actually stored.

The scenario restores the prior `system-info` preference in teardown. No login,
backend credentials or connectivity toggles are needed. Use the same
[safe runner configuration](integration_test_commands.md#run-the-system-info-refresh-guard)
as the User Repository guard.

The [host integration suite](../test/repository/system_info_repository_integration_test.dart)
also covers `preload()`, network-only/cache-first fetches, original write errors
and stacks, remote HTTP 503 failures, 20/40/10-second retry/recovery cadence in
virtual time, and unchanged cache-only behavior. The
[AppBloc tests](../test/blocs/app/app_compatibility_gate_test.dart) verify that
login awaits preload and handles its failure without discarding the valid session.

---

## Background Polling - Connectivity Probe Ordering

**File:** `patrol_test/connectivity_probe_ordering_test.dart`

**Verifies:** An older HTTP liveness probe cannot overwrite the online state
from a newer Android connectivity event or stop the recovered polling schedule.

**Steps:**
1. Disable Wi-Fi and cellular connectivity and create the connectivity and
   polling services while offline.
2. Enable Wi-Fi to start probe P1, disable it again, then enable it to start P2.
3. Complete P2 as online and verify that polling runs its leading refresh.
4. Complete P1 as offline after P2 and verify that the last connection state
   remains online.
5. Wait for a periodic tick and verify that polling is still scheduled.
6. Restore both device transports during teardown.

The network transitions and `connectivity_plus` event stream are real. Probe
completion is controlled to make the otherwise timing-dependent race
deterministic. No account credentials are required.

---

## Background Polling - Leading Refresh Freshness

**File:** `patrol_test/polling_freshness_test.dart`

**Verifies:** The leading-only freshness gate across the real scheduler, API
mapping, `UserInfoSyncWorker` over `UserRepository`, and native preferences on
Android. Successful requests
include a response delay, so deadlines are checked against completion.

1. With a 10-second interval, send connectivity flaps every 6 seconds through a
   controlled stream. Observe four successful HTTP requests and require every
   periodic start to remain 9.9-12 seconds after the previous completion.
2. Toggle Android Wi-Fi/cellular through Patrol and observe the real
   `ConnectivityServiceImpl` stream. A fresh recovery restores the completed
   state without another request; recovery after the 30-second cap requests
   once. No requests run during the offline wait.
3. Press Home and reopen the app, recording actual Flutter lifecycle events.
   A fresh resume skips the request; an aged resume triggers exactly one.
4. A manual 503 after success must not suppress reconnect recovery. `runNow`,
   a deferred invalidation at its deadline, and an invalidation due while offline
   all bypass freshness, without duplicate or early requests.
5. Hold HTTP responses across an offline interval. A trailing invalidation
   survives the in-flight request, and an old request start does not override
   freshness established by its recent completion.
6. Read a zero cap from environment overrides when constructing the service.
   Reconnects continue refreshing even after the override changes to 120.

Each scenario reopens native preferences to verify the persisted user record;
teardown restores the previous key. Request and completion traces provide the
actual timing evidence. The suite uses no fake clock. Only scenarios 2 and 3
change Android network/lifecycle state; scenario 1 controls events to produce
repeatable 6-second flaps. HTTP responses and liveness answers are controlled:
this verifies scheduling and persistence, not a live backend or internet health.
Shell-specific env wiring is additionally covered by
`test/app/router/main_shell_polling_config_test.dart`.

Native lifecycle callbacks enter outside the test zone. The shared User
integration harness runs HTTP assertions in its captured test zone, while
response timers stay in their caller's zone. A host regression test invokes
refresh through `Zone.root` to keep native resume from failing inside the mock
with `OutsideTestException`.

---

## Background Polling - Connect Invariant

**File:** `patrol_test/polling_connect_invariant_test.dart`

**Verifies:** Fresh login, aged foreground resume, and aged network recovery each produce
exactly one user-info request, without a retry or a back-to-back duplicate.
The test sets the leading freshness cap to 3 seconds and backgrounds for 4 seconds;
fresh skips and periodic deadline preservation are covered by service unit tests.

**Steps:**
1. Bootstrap and log in, capture API client request logs, and assert one `/user` request.
2. Background and reopen the app, then assert one `/user` request after resume.
3. Disable Wi-Fi and cellular connectivity, restore them, and wait for polling recovery.
4. Assert one `/user` request after recovery.

This scenario stays focused on the user-info endpoint. Contacts has its own
worker-driven lifecycle scenario below.

---

## Background Polling - Contacts Worker Sync

**File:** `patrol_test/contacts_worker_sync_e2e_test.dart`

**Verifies:** External Contacts uses one worker-owned request path across login,
manual refresh, resume, failure, and recovery, while synced data reaches the UI
and excludes the signed-in number.

**Steps:**
1. Start from a fresh session, log in, and assert one `/user/contacts` request
   with no transport retry.
2. Open External Contacts and verify a configured contact reaches the screen.
3. Search by number and verify the signed-in number is absent while the known
   external contact remains discoverable.
4. Pull the list down and assert one request and a completed refresh indicator.
5. Background for 4 seconds and reopen the app, then assert one request after
   aged resume (the test sets the leading freshness cap to 3 seconds).
6. Pull while offline and verify the refresh indicator still completes.
7. Restore connectivity and assert one recovery request.

---

## Background Polling - CDR Pagination

**File:** `patrol_test/cdr_sync_pagination_e2e_test.dart`

**Verifies:** CDR sync is started by its app-owned polling registration, and a
pull-to-refresh routed through the retained task drains every incremental page
before updating local state.

**Steps:**
1. Seed one CDR in the local SIP adapter and log in through the local Core.
2. Wait for the app-owned polling registration to fetch and persist it.
3. Complete one task cycle to place the next periodic deadline outside setup.
4. Seed 120 incremental CDRs and pull the Recent Calls list.
5. Assert exactly three requests for pages 1, 2, and 3 with one stable anchor.
6. Verify all records from every page are stored in newest-first order and
   rendered by the Recent Calls screen, and that the refresh indicator closes.

---

## Call Transfers

**File:** `patrol_test/call_transfers_test.dart`

**Verifies:** Blind transfer and attended (consultative) transfer.

### Blind transfer

1. Log in if needed.
2. Two pjsua companions register with auto-answer (contact A and contact B).
3. Place an outgoing call to contact A — verify it connects.
4. Open the transfer menu and select "Blind transfer".
5. Enter contact B's number and confirm the transfer.
6. Verify the original call ends (`CallActiveScaffold` disappears).

### Attended transfer

1. Two new pjsua companions register with auto-answer.
2. Place an outgoing call to contact A — verify it connects.
3. Open the transfer menu and select "Attended transfer".
4. Enter contact B's number and place the consultative call.
5. Verify one call is on hold and one is active simultaneously.
6. Complete the attended transfer.
7. Verify the original call ends (`CallActiveScaffold` disappears).

---

## Smoke Test

**File:** `patrol_test/just_run_test.dart`

**Verifies:** The app launches and the root widget renders without crashing.

**Steps:**
1. Bootstrap the app.
2. Wait until `AppShell` is visible.

## System notifications - sync regressions

**Native entrypoint:** `patrol_test/system_notifications_sync_test.dart`.
**Shared host suite:** `test/features/system_notifications/system_notifications_integration_test.dart`.
**Harness:** `test/features/system_notifications/system_notifications_integration_harness.dart`.

Seven scenarios exercise the real API mapping, polling owner, file-backed SQLite
and notification push policy:

- Empty and populated successful initial loads stay silent. The next notification
  is persisted and requested as a local push only when `producePush` is enabled
  (four combinations). API paths, timestamp anchors and payloads are checked.
- A 503 during initialization leaves no success timestamp. Retried history stays
  silent; a later update is persisted and delivered.
- Disposal followed by database cleanup while history or a full updates page is
  in flight rejects the retired cycle. The late response cannot restore rows,
  emit a local push or fetch the next page. The polling owner remains stopped.

These are component integration tests, not full app or live backend tests. HTTP,
connectivity eligibility and native notification delivery are controlled. They do
not exercise the logout screen, FCM, Android permissions or notification drawer.
Manual owner runs make the race deterministic; timer/backoff behavior is covered
by the separate polling suites. Isolated database files are deleted on teardown.

Verified on 2026-09-11: Pixel 9 (Android 17), 7/7 Patrol scenarios passed.
The host system-notifications module also passed all 30 tests.
