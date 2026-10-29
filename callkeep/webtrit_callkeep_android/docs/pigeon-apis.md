# Pigeon APIs

**Generated file**: `kotlin/com/webtrit/callkeep/Generated.kt` (DO NOT EDIT)

**Source**: `pigeons/callkeep.messages.dart`

**Regeneration**:

```dart
../tool/pigeon.sh   # runs pigeon and strips the trailing whitespace its Kotlin and Objective-C generators leave
```

Pigeon generates type-safe Kotlin/Dart bindings. There are two categories:

- **Host APIs** — Kotlin code that Dart calls into.
- **Flutter APIs** — Dart code that Kotlin calls into.

---

## Host APIs (Kotlin implements, Dart calls)

### `PHostApi`

Implemented by: `ForegroundService`

The primary call-control API. All call lifecycle operations from Dart arrive here.

| Method                                                                               | Description                                                                                                                                                                                                                          |
|--------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `isSetUp()`                                                                          | Whether the plugin has been set up                                                                                                                                                                                                   |
| `setUp(options)`                                                                     | Register phone account, init notification channels                                                                                                                                                                                   |
| `tearDown()`                                                                         | Hang up all calls, clean up                                                                                                                                                                                                          |
| `reportNewIncomingCall(callId, handle, displayName, hasVideo, offeredAtMs)`          | Register with Telecom through the core and await the outcome: null when confirmed, an error on refusal, duplicate or the registration deadline. A call the app ended unseen is refused unless offered (`offeredAtMs`) after that end |
| `reportConnectingOutgoingCall(callId)`                                               | Mark outgoing call as connecting                                                                                                                                                                                                     |
| `reportConnectedOutgoingCall(callId)`                                                | Mark outgoing call as connected                                                                                                                                                                                                      |
| `reportUpdateCall(callId, handle, displayName, hasVideo, proximityEnabled)`          | Update call metadata; unset fields are left alone                                                                                                                                                                                    |
| `reportEndCall(callId, displayName, reason)`                                         | Force-end call from Dart side                                                                                                                                                                                                        |
| `startCall(callId, handle, displayNameOrContactIdentifier, video, proximityEnabled)` | Initiate an outgoing call                                                                                                                                                                                                            |
| `answerCall(callId)`                                                                 | Answer incoming call                                                                                                                                                                                                                 |
| `endCall(callId, endedBy)`                                                           | End a call; `endedBy` (user or app: who asks) comes back in the `performEndCall` that follows                                                                                                                                        |
| `setHeld(callId, onHold)`                                                            | Toggle hold                                                                                                                                                                                                                          |
| `setMuted(callId, muted)`                                                            | Toggle mute                                                                                                                                                                                                                          |
| `setSpeaker(callId, enabled)`                                                        | Toggle speaker                                                                                                                                                                                                                       |
| `setAudioDevice(callId, device)`                                                     | Select audio device                                                                                                                                                                                                                  |
| `sendDTMF(callId, key)`                                                              | Send DTMF tone                                                                                                                                                                                                                       |
| `setCallGroup(groupId, callIds)`                                                     | Present these calls to the OS as one group                                                                                                                                                                                           |
| `unsetCallGroup(callIds)`                                                            | Take these calls out of their group                                                                                                                                                                                                  |
| `onDelegateSet()`                                                                    | Dart signals it is ready to receive events                                                                                                                                                                                           |
| `onDelegateCleared()`                                                                | Dart removed its delegate (`setDelegate(null)`): a push call goes to a push session                                                                                                                                                  |

`setCallGroup` names the group and takes its whole membership rather than a
change to it. Both backends implement them by keeping the membership themselves; neither
declares it to the platform. `callGroupingNotSupported` is
still the answer of a backend that cannot group. `setHeld` on a declared member of a group
answers `callIsGrouped` instead of holding it; `ForegroundService` keeps the declared
membership for that, because the Telecom backend lives in another process.

---

### `PHostActivityControlApi`

Implemented by: `ActivityControlApi`

| Method                     | Description                                            |
|----------------------------|--------------------------------------------------------|
| `showOverLockscreen(show)` | Toggle lock-screen overlay flag on the activity window |
| `wakeScreenOnShow(wake)`   | Toggle screen-wake flag                                |
| `sendToBackground()`       | Move activity to background                            |
| `isDeviceLocked()`         | Returns whether device is currently locked             |

---

### `PHostPermissionsApi`

Implemented by: `PermissionsApi`

| Method                                  | Description                                     |
|-----------------------------------------|-------------------------------------------------|
| `requestPermissions(permissions)`       | Request runtime permissions via the activity    |
| `checkPermissionsStatus(permissions)`   | Check which permissions are granted             |
| `getFullScreenIntentPermissionStatus()` | Check `USE_FULL_SCREEN_INTENT` status (API 34+) |
| `openFullScreenIntentSettings()`        | Navigate to FSI settings screen                 |
| `getBatteryMode()`                      | Return current battery optimization mode        |

---

### `PHostConnectionsApi`

Implemented by: `ConnectionsApi`

| Method                  | Description                                                  |
|-------------------------|--------------------------------------------------------------|
| `getConnection(callId)` | Return `CallMetadata` for a specific call                    |
| `getConnections()`      | Return all active `CallMetadata` records                     |
| `cleanConnections()`    | Clear all connections without hanging up (for tearDown race) |

---

### `PHostDiagnosticsApi`

Implemented by: `DiagnosticsApi`

| Method                  | Description                                           |
|-------------------------|-------------------------------------------------------|
| `getDiagnosticReport()` | Return a structured diagnostic snapshot for debugging |

---

### `PHostSoundApi`

Implemented by: `SoundApi`

| Method                      | Description                           |
|-----------------------------|---------------------------------------|
| `playRingbackSound(callId)` | Start ringback tone for outgoing call |
| `stopRingbackSound(callId)` | Stop ringback tone                    |

---

### `PHostBackgroundPushNotificationIsolateBootstrapApi`

Implemented by: `BackgroundPushNotificationIsolateBootstrapApi`

| Method                                             | Description                                                                                                                                                                                  |
|----------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `initializePushNotificationCallback(handle)`       | Store Dart isolate entry-point                                                                                                                                                               |
| `reportNewIncomingCall(callId, meta, offeredAtMs)` | Register a push-triggered call through the same core operation as the signaling report; `IncomingCallService` starts from the Telecom connection. `offeredAtMs` is the push's FCM `sentTime` |

---

### `SmsReceptionConfigBootstrapApi`

Configures the optional SMS-based incoming call trigger (`IncomingCallSmsTriggerReceiver`).

---

## Flutter APIs (Dart implements, Kotlin calls)

### `PDelegateFlutterApi`

Kotlin calls these methods on the Dart delegate to notify of call events.

Every `perform*` is declared to return `bool` and the `did*` methods return nothing. Note
that Android **ignores the boolean**: every call site launches the call through
`ForegroundService.notifyFlutter` and discards the result, so a delegate returning `false`
changes nothing here. It is iOS that acts on it, by failing the CallKit action.

Pigeon generates these, and every `@async` host method, as Kotlin `suspend` functions. A
host call runs in a coroutine pigeon launches on `Dispatchers.Main`; the reply goes back
when the function returns, and a thrown exception becomes a `PlatformException` in Dart. A
delegate call from Kotlin has to run inside a coroutine: the service and the push-isolate
communicator keep a `SupervisorJob` scope on `Dispatchers.Main.immediate` for that.

| Method                                                                    | Description                                                                                                   |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `didPresentIncomingCall(handle, displayName, video, callId, error)`       | A ringing connection this delegate has not been handed yet (replay on attach; `error` always null on Android) |
| `performStartCall(callId, handle, displayNameOrContactIdentifier, video)` | Place this outgoing call                                                                                      |
| `performAnswerCall(callId)`                                               | Answer this call                                                                                              |
| `performEndCall(callId, endedBy)`                                         | End this call; `endedBy`: the user, the app, or the system (also when unknown)                                |
| `performHandoff(callId)`                                                  | Push isolate only: the call is the app's now, or ended elsewhere; finish and return                           |
| `performSetHeld(callId, onHold)`                                          | Hold or resume this call                                                                                      |
| `performSetMuted(callId, muted)`                                          | Mute or unmute this call                                                                                      |
| `performSendDTMF(callId, key)`                                            | Send this DTMF digit                                                                                          |
| `performAudioDeviceSet(callId, device)`                                   | The audio device changed                                                                                      |
| `performAudioDevicesUpdate(callId, devices)`                              | The available audio devices changed                                                                           |
| `performSetCallGroup(callId, groupWithCallId)`                            | The OS grouped this call with another, or ungrouped it when the second is null                                |
| `didActivateAudioSession()`                                               | The call audio session became active                                                                          |
| `didDeactivateAudioSession()`                                             | The call audio session was released                                                                           |

`continueStartCallIntent` and `didReset` exist on the shared `CallkeepDelegate` but are
iOS-only: Android has no source for either, so they are absent from this API.

---

## Host calls wait for the main looper

A Pigeon host call from Dart, from the main isolate or the push isolate, is posted to the main
looper twice before its handler body runs:

1. A channel set up without a `TaskQueue` has its messages delivered on the platform thread,
   which the embedding does by posting to the main looper.
2. For an `@async` host method Pigeon 29 generates `CoroutineScope(Dispatchers.Main).launch`
   in `Generated.kt`, a second post.

On a cold start the main thread is busy with the app's own start for seconds (the app logs it
as `startup_complete total_ms=...`), and every host call queues behind it. The Dart code of an
isolate runs on the same thread too (Flutter merges the UI and platform threads on Android), so
a message into the session waits for it as well. Neither can be switched off.

The trap: a push session reports `reportEndCall` for a call the caller already hung up, the
report reaches the core only after the start is over, and Telecom keeps ringing all that time.

What callkeep does about it:

- `PHostBackgroundPushNotificationIsolateApi.reportEndCall` is declared with
  `@TaskQueue(type: TaskQueueType.serialBackgroundThread)` in `pigeons/callkeep.messages.dart`.
  Pigeon then sets the channel up on `binaryMessenger.makeBackgroundTaskQueue()` and launches
  the handler on `Dispatchers.Unconfined`, so it runs on a background thread.
- A handler on a background thread must not touch main-confined state:
  `IncomingRegistrations` checks `Looper.myLooper()` and throws off the platform thread.
  `InProcessCallkeepCore.reportCallEnded` therefore records the terminal facts on the calling
  thread (the tracker is a concurrent map) and posts to the main looper only what lives there:
  `markTerminated` rejects a waiting registration there, and `runOnMain` runs the
  pending-release check. See [callkeep-core.md](callkeep-core.md).

When you add a host method that must not wait for the start:

- Give it `@TaskQueue(type: TaskQueueType.serialBackgroundThread)`, regenerate, and keep the
  handler off main-confined state; post the part that needs the main looper.
- Do not wait for the main looper from the background handler with `runBlocking`: suspend
  instead (`CompletableDeferred`), or the Pigeon thread is held for the whole start.
- Do not raise timeouts such as `IncomingCallService.SESSION_FINISH_TIMEOUT_MS` or the
  registration deadline to cover the delay: they only hide the queue.

On the Dart side, do not `await` a platform call inside a sequential Bloc event handler: the
next event waits for the main looper together with it.

---

## Data Types (Pigeon-generated)

| Type                       | Description                                                         |
|----------------------------|---------------------------------------------------------------------|
| `PHandle`                  | Call handle: generic, phone number or email                         |
| `PAudioDevice`             | Audio device descriptor (earpiece, speaker, Bluetooth, etc.)        |
| `PCallkeepConnectionState` | Telecom state enum: RINGING, DIALING, ACTIVE, HOLDING, DISCONNECTED |
| `PEndedByEnum`             | Who ended a call: USER, APP, SYSTEM (SYSTEM also when not known)    |

---

## Related Components

- [foreground-service.md](foreground-service.md) — implements `PHostApi`
- [background-services.md](background-services.md) — bootstrap APIs wired to services
- [plugin.md](plugin.md) — registers all host APIs on `onAttachedToEngine`
