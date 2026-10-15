# Integration Test Commands

Commands for host integration suites and native Patrol scenarios.
Last reviewed: 2026-09-11.

## Prerequisite: provision patrol

`patrol` is intentionally NOT a committed dependency. It weak-links `XCTest`, and
Flutter does not strip dev dependencies from iOS release builds
([flutter/flutter#163874](https://github.com/flutter/flutter/issues/163874)), so
shipping it makes the app reference `XCTest` and Apple rejects it (guideline 2.5.1).

Add it before running the commands below (the `tool/scripts/*` helpers do this
automatically):

```bash
flutter pub add 'dev:patrol:^4.6.1'
```

Do not commit the resulting `pubspec.yaml` / `pubspec.lock` change; restore them
when done (`git checkout pubspec.yaml pubspec.lock`).

## Run integration tests in dev mode

Run direct Patrol commands from the repository root:

```bash
patrol develop --dart-define-from-file=dart_define.json --dart-define-from-file=dart_define.integration_test.json
```

## Build integration tests

```bash
patrol build android/ios --dart-define-from-file=dart_define.json --dart-define-from-file=dart_define.integration_test.json
```

To specify a test file, use the `-t` option:

```bash
patrol build -t patrol_test/call_and_recent_test.dart ...
```

## Run the unreachable-core recovery scenario

```bash
tool/scripts/patrol_e2e_run_local_android.sh patrol_test/core_unreachable_recovery_test.dart
```

The scenario writes its own session and core URL into native storage, so no
credentials or live backend are needed - the core it points at is a closed port.
It is deliberately destructive: reaching login means the session ended and local
application data was cleared, so the device has to be signed in again afterwards.
Do not run it on a device holding a session you need.

## Run the user repository refresh guards

The host integration suite needs neither Patrol nor a device:

```bash
fvm flutter test --no-pub test/repository/user_repository_integration_test.dart
```

For native persistence coverage, provision Patrol as described above and run
from the `phone/` directory using FVM. Ensure `android/local.properties` also
points `flutter.sdk` to the pinned SDK, because Patrol invokes Gradle directly.

Before running on a device whose app data must be retained, temporarily set
`testInstrumentationRunnerArguments clearPackageData: "false"` in
`android/app/build.gradle` and restore it afterwards. The default is `"true"`:
`--no-uninstall` alone does not stop Android Test Orchestrator from clearing data.

```bash
fvm exec patrol test \
  -t patrol_test/user_repository_refresh_test.dart \
  --device DEVICE_ID \
  --no-uninstall \
  --no-tree-shake-icons \
  --dart-define-from-file=dart_define.json
```

These focused tests use controlled HTTP responses with the real API client and
native preferences. No credentials, local Core, call companion or integration
environment file are needed. The previous `user-info` preference is restored
after each scenario. With the runner setting above, `--no-uninstall` also keeps
the existing installation and its unrelated data.
See [coverage and boundaries](integration_test_coverage.md#background-polling---user-repository-refresh).

## Run the system-info refresh guard

The host integration suite runs without Patrol:

```bash
fvm flutter test --no-pub test/repository/system_info_repository_integration_test.dart
```

For the native scenario, use the same provisioning, pinned SDK and temporary
`clearPackageData: "false"` setting described in the
[User Repository instructions](#run-the-user-repository-refresh-guards):

```bash
fvm exec patrol test \
  -t patrol_test/system_info_repository_refresh_test.dart \
  --device DEVICE_ID \
  --no-uninstall \
  --no-tree-shake-icons \
  --dart-define-from-file=dart_define.json
```

HTTP and the failure before a preferences write are controlled. Successful
writes use the native preferences plugin; the original `system-info` key is
restored afterwards. See [coverage](integration_test_coverage.md#background-polling---system-info-persistence).

## Run the voicemail refresh guards

From `phone/`, the unit and host integration suites need no device or Patrol:

```bash
fvm flutter test --no-pub \
  test/repository/voicemail_refresh_contract_test.dart \
  test/repository/voicemail_repository_integration_test.dart
```

For the native scenarios, provision Patrol and apply the temporary
`clearPackageData: "false"` setting from the
[User Repository instructions](#run-the-user-repository-refresh-guards):

```bash
fvm exec patrol test \
  -t patrol_test/voicemail_repository_refresh_test.dart \
  --device DEVICE_ID \
  --no-uninstall \
  --no-tree-shake-icons \
  --dart-define-from-file=dart_define.json
```

The tests create and remove their own temporary SQLite database; they never
open the application's database or need an account, backend or call companion.
HTTP and cache-boundary faults are controlled. Restore the runner setting and
remove the temporary Patrol dependency afterwards without committing either.
See [coverage](integration_test_coverage.md#background-polling---voicemail-refresh).

## Run the favorites refresh guards

The host suites need no device or Patrol:

```bash
fvm flutter test --no-pub \
  test/repository/favorites_repository_test.dart \
  test/repository/favorites_repository_integration_test.dart
```

For the native scenarios, provision Patrol and temporarily set
`clearPackageData: "false"` as described in the
[User Repository instructions](#run-the-user-repository-refresh-guards):

```bash
fvm exec patrol test \
  -t patrol_test/favorites_repository_refresh_test.dart \
  --device DEVICE_ID \
  --no-uninstall \
  --no-tree-shake-icons \
  --dart-define-from-file=dart_define.json
```

The tests use their own temporary file-backed SQLite database and controlled
HTTP/connectivity. They do not log in, contact a live backend, open the app's
database, or alter OS connectivity. Restore the runner setting and temporary
Patrol dependency after the run. See
[coverage](integration_test_coverage.md#background-polling---favorites-refresh).

## Run the SIP subscriptions refresh guards

The host suites need no device or Patrol:

```bash
fvm flutter test --no-pub \
  test/repository/sip_subscriptions_repository_test.dart \
  test/repository/sip_subscriptions_repository_integration_test.dart
```

For the native scenarios, provision Patrol and temporarily set
`clearPackageData: "false"` following the
[User Repository instructions](#run-the-user-repository-refresh-guards):

```bash
fvm exec patrol test \
  -t patrol_test/sip_subscriptions_repository_refresh_test.dart \
  --device DEVICE_ID \
  --no-uninstall \
  --no-tree-shake-icons \
  --dart-define-from-file=dart_define.json
```

The scenarios use controlled HTTP/connectivity and a temporary SQLite file,
not the app's database. No login, backend credentials or network toggles are
needed. Restore the temporary Patrol dependency and runner setting after the
run. See [coverage](integration_test_coverage.md#background-polling---sip-subscriptions-refresh).

## Run the polling freshness guards on Android

Provision Patrol and temporarily use `clearPackageData: "false"` as described
in the [User Repository instructions](#run-the-user-repository-refresh-guards).
Use the USB device ID, since the suite disables Wi-Fi and cellular service.
From `phone/`:

```bash
fvm exec patrol test \
  -t patrol_test/polling_freshness_test.dart \
  --device DEVICE_ID \
  --no-uninstall \
  --no-tree-shake-icons \
  --dart-define-from-file=dart_define.json \
  --show-flutter-logs
```

No credentials, backend, call companion, or integration environment file are
needed. The suite uses the real API client, UserRepository and native
preferences with controlled HTTP responses. It restores the `user-info` key
and enables Wi-Fi/cellular in teardown. Start with both transports enabled.
Real Android transport and Home/resume scenarios complement the precise
6-second flap scenario, which controls connectivity events but uses real time.
`freshness_trace` lines report request and successful-completion timestamps in
milliseconds relative to the first request. Restore the temporary dependency
and runner changes afterwards. See
[coverage and boundaries](integration_test_coverage.md#background-polling---leading-refresh-freshness).

## Run the polling guards

From the repository root, run the connectivity ordering, connect lifecycle, and
Contacts request-path guards separately:

```bash
patrol test -t patrol_test/connectivity_probe_ordering_test.dart \
  --no-tree-shake-icons \
  --dart-define-from-file=dart_define.json \
  --dart-define-from-file=dart_define.integration_test.json

patrol test -t patrol_test/polling_connect_invariant_test.dart \
  --no-tree-shake-icons \
  --dart-define-from-file=dart_define.json \
  --dart-define-from-file=dart_define.integration_test.json

patrol test -t patrol_test/contacts_worker_sync_e2e_test.dart \
  --no-tree-shake-icons \
  --dart-define-from-file=dart_define.json \
  --dart-define-from-file=dart_define.integration_test.json
```

All three guards disable and restore Wi-Fi and cellular service. On Android,
use a USB-connected device for these scenarios: disabling Wi-Fi also
disconnects a wireless ADB session before Patrol can restore the network. The
connectivity-ordering guard needs no account credentials; it constructs the
connectivity and polling services directly and uses the real platform stream.

The CDR pagination guard additionally requires a local Core on port 4000 and a
SIP adapter on port 3000 that exposes the `/debug/history` seed endpoint. The
example local-stack account is `555001` / `test123`. Set
`WEBTRIT_CDR_TEST_HOST` to the development machine's LAN address reachable from
the device, then run:

```bash
WEBTRIT_CDR_TEST_HOST=192.168.0.3

patrol test -t patrol_test/cdr_sync_pagination_e2e_test.dart \
  --no-tree-shake-icons \
  --dart-define-from-file=dart_define.json \
  --dart-define-from-file=dart_define.integration_test.json \
  --dart-define=WEBTRIT_APP_TEST_CUSTOM_CORE_URL=http://$WEBTRIT_CDR_TEST_HOST:4000 \
  --dart-define=WEBTRIT_APP_DEMO_CORE_URL=http://$WEBTRIT_CDR_TEST_HOST:4000 \
  --dart-define=WEBTRIT_APP_TEST_PASSWORD_USER_CREDENTIAL=555001 \
  --dart-define=WEBTRIT_APP_TEST_PASSWORD_PASSWORD_CREDENTIAL=test123 \
  --dart-define=WEBTRIT_APP_CDRS_REPOSITORY_POLLING_INTERVAL_SECONDS=300
```

Pinning the CDR interval isolates the pull-driven request window from the next
automatic tick whatever the build default is. The scenario still uses the app-owned polling registration;
only its periodic test cadence changes.

## Deploy to Firebase Test Lab

Run from the `tool/scripts` directory:

```bash
./testlab_assemble_android.sh <testfile(optional)>
./testlab_assemble_ios.sh <testfile(optional)>
```

## Run Android integration tests locally with call companion

Starts the [pjsua Companion](../packages/pjsua_companion/README.md) server automatically and runs the tests:

```bash
./tool/scripts/patrol_e2e_run_local_android.sh <testfile(optional)>
```

## Run system notification sync regressions

The same seven scenarios run on the host and on a native device:

```bash
fvm flutter test --no-pub test/features/system_notifications/system_notifications_integration_test.dart

fvm exec patrol test \
  -t patrol_test/system_notifications_sync_test.dart \
  --device DEVICE_ID \
  --no-uninstall \
  --no-tree-shake-icons \
  --dart-define-from-file=dart_define.json
```

Provision Patrol and temporarily set `clearPackageData: "false"` as described
in [the user repository instructions](#run-the-user-repository-refresh-guards).
Restore the dependency files, runner configuration and any device settings
changed for testing afterwards.

Each scenario creates and deletes its own SQLite file in the device temporary
directory. It uses the real API client, notification repositories, polling owner
and push service. HTTP and the native push repository are controlled; no account,
live backend or notification permission is needed. Push assertions verify the
request to display, not an Android notification drawer entry. The logout race
invokes owner disposal and database cleanup directly rather than driving logout UI.
See [coverage](integration_test_coverage.md#system-notifications---sync-regressions).
