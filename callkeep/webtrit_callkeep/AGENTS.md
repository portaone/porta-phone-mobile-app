# AGENTS.md - webtrit_callkeep (aggregator)

This package is the **public API surface** for app developers and the only callkeep package the
app imports. Most of it is thin wrappers that delegate to `WebtritCallkeepPlatform.instance`, but
not all: `Callkeep` keeps state of its own (below), and that logic is tested in `test/`.

Its `pubspec.yaml` `version:` is the version of the whole plugin; it changes only at an app
release ([../docs/release_process.md](../docs/release_process.md)).

---

## Package structure

```text
lib/src/
|-- callkeep.dart                      # Callkeep singleton - core call operations + status stream
|-- callkeep_connections.dart          # CallkeepConnections singleton - connection state (Android, web)
|-- webtrit_callkeep_permissions.dart  # Permission helpers
|-- webtrit_callkeep_sound.dart        # Sound playback helpers
`-- android/
    |-- services/
    |   |-- android_calkeep_services.dart  # AndroidCallkeepServices - static service registry
    |   |-- background_push_notification_bootstrap_service.dart
    |   `-- background_push_notification_service.dart
    `-- utils/
        |-- android_callkeep_utils.dart    # AndroidCallkeepUtils - diagnostics, SMS, activity
        |-- activity_control.dart
        |-- callkeep_diagnostics.dart
        `-- sms_bootstrap_reception_config.dart
example/integration_test/              # the public API on a real device
```

---

## Key classes

### `Callkeep` (singleton)

- `setUp(CallkeepOptions)` / `tearDown()` - initialize/shutdown native integration
- `reportNewIncomingCall` / `startCall` / `answerCall` / `endCall` - call lifecycle; `reportNewIncomingCall`
  takes `offeredAt`, when the server offered the call (null for a handshake replay), which tells a new
  attempt of an id from a ghost of its ended one
- `setHeld` / `setMuted` / `sendDTMF` / `setAudioDevice` - in-call controls
- `setCallGroup(groupId, callIds)` / `unsetCallGroup` - present several calls to the OS as one named group; the list is
  the whole membership, an empty one does nothing
- `statusStream` / `currentStatus` - `CallkeepStatus` enum stream (uninitialized, configuring, active, terminating)
- `setDelegate(CallkeepDelegate?)` / `setPushRegistryDelegate(PushRegistryDelegate?)` - event callbacks
- `reportEndCall` with `missedWhileConnecting` remembers the end of a call the app never held
  (with `declinedByUser`, a decline on this device, the same for now);
  `wasEndedBeforePresented(callId)` answers it, and the delegate wrapper drops a later
  `didPresentIncomingCall` of that call (`test/ends_reported_unseen_test.dart`)

### `AndroidCallkeepServices` (static, Android only)

Entry point for Android background modes. Always use these static singletons:

- `backgroundPushNotificationBootstrapService` - configure + trigger push-notification-based calls
- `backgroundPushNotificationService` - end calls from push notification isolate
- `smsReceptionConfig` - **deprecated**, use `AndroidCallkeepUtils.smsReceptionConfig` instead

### `AndroidCallkeepUtils` (static, Android only)

- `activityControl` - lock screen overlay, wake screen, send to background
- `diagnostics` - get diagnostic report map
- `smsReceptionConfig` - initialize SMS-triggered call reception

### `CallkeepConnections` (singleton, Android and web)

- `getConnection(callId)` / `getConnections()` / `cleanConnections()`
- All methods are no-ops on platforms other than Android and web (return `null` / empty list)

---

## Integration tests

`example/integration_test/` exercises the public API against the real platform code, so it needs
a device (or Chrome for web). From `example/`:

```bash
flutter test integration_test/<file>.dart -d <device>   # one file
./run_integration_tests.sh [-d <device-id>]              # every file in isolation, Android
./run_integration_tests.sh --web                          # all_tests.dart in Chrome
```

What each file covers: [../webtrit_callkeep_android/README.md](../webtrit_callkeep_android/README.md#integration-tests).
No gate or Jenkins job runs them.

---

## Rules

- **Do not** add platform-specific imports. A platform guard uses `kIsWeb` and
  `defaultTargetPlatform` from `package:flutter/foundation.dart`, as `CallkeepConnections` does.
  `dart:io` `Platform` throws on web, where this package also runs: the guards that still use it
  check `kIsWeb` first (`sms_bootstrap_reception_config.dart`), except `activity_control.dart`.
- **Do not** expose Pigeon types - all public API uses types from `webtrit_callkeep_platform_interface`.
- `setSpeaker` is `@Deprecated` - use `setAudioDevice` with a `CallkeepAudioDevice` instead.
- Background service callbacks **must** be top-level functions annotated `@pragma('vm:entry-point')`.
