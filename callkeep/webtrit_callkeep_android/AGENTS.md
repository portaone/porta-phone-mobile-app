# AGENTS.md - webtrit_callkeep_android

The Android implementation: Dart in `lib/`, Kotlin in `android/src/main/kotlin/com/webtrit/callkeep/`,
the Pigeon definition in `pigeons/callkeep.messages.dart`. Every Kotlin component has a page in
[docs/](docs); start from [docs/architecture.md](docs/architecture.md) and read the page of each
component before you change it. The procedure and its traps are the `callkeep-android-change`
skill; the commands are in [../AGENTS.md](../AGENTS.md).

## Two processes

- `:callkeep_core` runs `PhoneConnectionService`, the Telecom `ConnectionService`, and the
  `PhoneConnection` objects it holds. No Flutter engine runs there.
- The main process runs the Flutter engines and the services around them: `ForegroundService`
  (bound by the activity, host of `PHostApi`, forwards call events to Dart), `IncomingCallService`
  (a ringing call on the Telecom path and the push isolate), `ActiveCallService` (the foreground
  service and ongoing notification of every answered Telecom call, typed
  `phoneCall|microphone|camera`) and `StandaloneCallService` (the call backend where Telecom
  cannot host calls).
- The processes talk through app-scoped broadcasts (`:callkeep_core` to main) and explicit
  `startService` intents (main to the backend). The contract and the event catalogue:
  [dual-process.md](docs/dual-process.md), [ipc-broadcasting.md](docs/ipc-broadcasting.md).

Main-process code reaches calls only through `CallkeepCore.instance`: its reads come from
`MainProcessConnectionTracker`, its commands go out as intents. `ConnectionManager` in the main
heap is not the one `PhoneConnectionService` fills, so reading or changing it there is a silent
no-op. The one entry it does hold is the pending reservation `checkAndReservePending` makes
during `startIncomingCall`; `InProcessCallkeepCore.clearAndMarkEndCallDispatched` removes it, or
a call reported again under the same id is refused as a duplicate
([callkeep-core.md](docs/callkeep-core.md)).

## Push isolate

`AndroidCallkeepServices.backgroundPushNotificationBootstrapService.initializeCallback(cb)`
registers the entry point; `cb` is a top-level `Future<void> Function(CallkeepIncomingCallMetadata?)`
(`CallKeepPushNotificationSyncStatusHandle`) annotated `@pragma('vm:entry-point')`.
`reportNewIncomingCall` on the same service hands the call to `CallkeepCore.registerIncomingCall`;
once Telecom shows it, `IncomingCallService` starts and runs the callback in a new isolate. Inside it `CallkeepBackgroundServiceDelegate` receives `performAnswerCall`,
`performEndCall` and `performHandoff`; the callback's future completing is what stops the service.
Details: [background-services.md](docs/background-services.md).

## SMS trigger

The app turns it on: it declares `RECEIVE_SMS` and the `IncomingCallSmsTriggerReceiver` receiver
(guarded by `android:permission="android.permission.BROADCAST_SMS"`) in its own manifest - both
are only comments in this package's manifest - and calls
`AndroidCallkeepUtils.smsReceptionConfig.configureReceivedSms(prefix:, regexPattern:)`. The
prefix is the app's configuration, stored with the regex in `StorageDelegate`; the receiver
takes a message whose body contains it and that the regex matches. A matched message goes
through `CallkeepCore.registerIncomingCall`, as push and signaling do. The regex:
[sms_trigger_regex_requirements.md](../docs/sms_trigger_regex_requirements.md).

## Key invariants

- `CallMetadata` must not be `Parcelable` or `@Parcelize`: it reaches `system_server` inside a
  Telecom `Bundle`, whose class loader does not know the class, and unmarshalling throws
  `BadParcelableException`. Pass it as `toBundle()` / `fromBundle()` (the warning in
  `models/CallMetaData.kt`).
- Pigeon host calls run on the main looper and must not block it. The exception is
  `PHostBackgroundPushNotificationIsolateApi.reportEndCall`, declared
  `@TaskQueue(type: TaskQueueType.serialBackgroundThread)` so a hangup during a cold start does
  not wait for it; its path posts to the main looper whatever lives there
  (`IncomingRegistrations` throws off it). See "Host calls wait for the main looper" in
  [pigeon-apis.md](docs/pigeon-apis.md).
- `@Keep` (`androidx.annotation.Keep`) is on `ForegroundService`, `IncomingCallService` and
  `StandaloneCallService`; R8 keeps them by that annotation. `consumer-rules.pro` holds one rule,
  `-keepnames` for `PhoneConnectionService`, whose name is addressed by `ComponentName` across
  the process boundary. Do not rename or remove any of the four.
- The Pigeon output (`lib/src/common/callkeep.pigeon.dart`, `Generated.kt`) is regenerated with
  `../tool/pigeon.sh`, never edited; converters between Pigeon and platform interface types are
  in `lib/src/common/converters.dart`. The iOS definition is a separate file.

## Tests

- Dart: `test/`. JVM (Robolectric): `android/src/test/kotlin/com/webtrit/callkeep/`, run with
  `./gradlew testDebugUnitTest` from `android/` once `android/local.properties` exists.
- On a device: the example's integration tests, listed in [README.md](README.md#integration-tests).
