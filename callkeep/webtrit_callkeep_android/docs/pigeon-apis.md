# Pigeon APIs

**Generated file**: `kotlin/com/webtrit/callkeep/Generated.kt` (DO NOT EDIT)

**Source**: `pigeons/callkeep.messages.dart`

**Regeneration**:

```dart
flutter pub run pigeon --input pigeons/callkeep.messages.dart
```

Pigeon generates type-safe Kotlin/Dart bindings. There are two categories:

- **Host APIs** — Kotlin code that Dart calls into.
- **Flutter APIs** — Dart code that Kotlin calls into.

---

## Host APIs (Kotlin implements, Dart calls)

### `PHostApi`

Implemented by: `ForegroundService`

The primary call-control API. All call lifecycle operations from Dart arrive here.

| Method                                                                               | Description                                        |
|--------------------------------------------------------------------------------------|----------------------------------------------------|
| `isSetUp()`                                                                          | Whether the plugin has been set up                 |
| `setUp(options)`                                                                     | Register phone account, init notification channels |
| `tearDown()`                                                                         | Hang up all calls, clean up                        |
| `reportNewIncomingCall(callId, handle, displayName, hasVideo)`                       | Register incoming call with Telecom                |
| `reportConnectingOutgoingCall(callId)`                                               | Mark outgoing call as connecting                   |
| `reportConnectedOutgoingCall(callId)`                                                | Mark outgoing call as connected                    |
| `reportUpdateCall(callId, handle, displayName, hasVideo, proximityEnabled)`          | Update call metadata; unset fields are left alone  |
| `reportEndCall(callId, displayName, reason)`                                         | Force-end call from Dart side                      |
| `startCall(callId, handle, displayNameOrContactIdentifier, video, proximityEnabled)` | Initiate an outgoing call                          |
| `answerCall(callId)`                                                                 | Answer incoming call                               |
| `endCall(callId)`                                                                    | End a call                                         |
| `setHeld(callId, onHold)`                                                            | Toggle hold                                        |
| `setMuted(callId, muted)`                                                            | Toggle mute                                        |
| `setSpeaker(callId, enabled)`                                                        | Toggle speaker                                     |
| `setAudioDevice(callId, device)`                                                     | Select audio device                                |
| `sendDTMF(callId, key)`                                                              | Send DTMF tone                                     |
| `onDelegateSet()`                                                                    | Dart signals it is ready to receive events         |

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

| Method                                       | Description                                         |
|----------------------------------------------|-----------------------------------------------------|
| `initializePushNotificationCallback(handle)` | Store Dart isolate entry-point                      |
| `configureSignalingService(config)`          | Persist service config                              |
| `reportNewIncomingCall(callId, meta)`        | Start `IncomingCallService` for push-triggered call |

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

| Method                                                                    | Description                             |
|---------------------------------------------------------------------------|-----------------------------------------|
| `didPushIncomingCall(handle, displayName, video, callId, error)`          | An incoming call arrived through a push |
| `performStartCall(callId, handle, displayNameOrContactIdentifier, video)` | Place this outgoing call                |
| `performAnswerCall(callId)`                                               | Answer this call                        |
| `performEndCall(callId)`                                                  | End this call                           |
| `performSetHeld(callId, onHold)`                                          | Hold or resume this call                |
| `performSetMuted(callId, muted)`                                          | Mute or unmute this call                |
| `performSendDTMF(callId, key)`                                            | Send this DTMF digit                    |
| `performAudioDeviceSet(callId, device)`                                   | The audio device changed                |
| `performAudioDevicesUpdate(callId, devices)`                              | The available audio devices changed     |
| `didActivateAudioSession()`                                               | The call audio session became active    |
| `didDeactivateAudioSession()`                                             | The call audio session was released     |

`continueStartCallIntent` and `didReset` exist on the shared `CallkeepDelegate` but are
iOS-only: Android has no source for either, so they are absent from this API.

---

## Data Types (Pigeon-generated)

| Type                       | Description                                                         |
|----------------------------|---------------------------------------------------------------------|
| `PCallMetadata`            | Call details: display name, handle, video, audio device flags       |
| `PCallHandle`              | Phone number or SIP URI                                             |
| `PAudioDevice`             | Audio device descriptor (earpiece, speaker, Bluetooth, etc.)        |
| `PCallkeepConnectionState` | Telecom state enum: RINGING, DIALING, ACTIVE, HOLDING, DISCONNECTED |
| `PFailureMetaData`         | Structured failure info (reason, code)                              |

---

## Related Components

- [foreground-service.md](foreground-service.md) — implements `PHostApi`
- [background-services.md](background-services.md) — bootstrap APIs wired to services
- [plugin.md](plugin.md) — registers all host APIs on `onAttachedToEngine`
