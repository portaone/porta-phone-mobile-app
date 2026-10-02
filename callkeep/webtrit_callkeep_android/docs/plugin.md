# WebtritCallkeepPlugin

**File**: `kotlin/com/webtrit/callkeep/WebtritCallkeepPlugin.kt`

**Implements**: `FlutterPlugin`, `ActivityAware`, `ServiceAware`, `LifecycleEventObserver`

## Responsibility

`WebtritCallkeepPlugin` is the Flutter plugin entry point. It is instantiated by the Flutter
framework when the plugin is registered and serves as the wiring point between the Dart layer and
all Android-side components.

## Lifecycle

### `onAttachedToEngine(binding)`

Called once when the Flutter engine attaches:

- Stores `applicationContext` in `ContextHolder`.
- Initializes `AssetCacheManager` (copies ringtones from the Flutter asset bundle to device
  storage so services can access them without a Flutter engine).
- Registers bootstrap APIs for background isolates:
  - `BackgroundPushNotificationIsolateBootstrapApi` (push-triggered incoming call service)
  - `SmsReceptionConfigBootstrapApi` (optional SMS fallback)
- Registers `PHostDiagnosticsApi`, `PHostPermissionsApi`, `PHostActivityControlApi`,
  `PHostConnectionsApi`, `PHostSoundApi`.

### `onAttachedToActivity(binding)` / `onReattachedToActivityForConfigChanges(binding)`

Called when an `Activity` is available:

- Saves `ActivityHolder.activity`.
- Hands the intent that opened the Activity to `LockScreenPresence` (see Lock-Screen Flags) and
  registers a new-intent listener for the same check when the Activity is reopened.
- Binds `ForegroundService` (see below).

### `onDetachedFromActivity()` / `onDetachedFromActivityForConfigChanges()`

- Removes the new-intent listener.
- Unbinds (and optionally stops) `ForegroundService`.

The plugin observes no Activity lifecycle: it takes no `Lifecycle` from the binding (Flutter
reserves `HiddenLifecycleReference` for `flutter_plugin_android_lifecycle`).

## ForegroundService Binding

```text
bindForegroundService()
    └── context.bindService(ForegroundService, serviceConnection, BIND_AUTO_CREATE)

unbindAndStopForegroundService()
    └── context.unbindService(serviceConnection)
    └── ForegroundService.stopSelf() (if no longer needed)
```

`serviceConnection.onServiceConnected()` stores the `ForegroundService` binder and registers the
remaining Pigeon host API — `PHostApi` — which is implemented by `ForegroundService` itself.

## Lock-Screen Flags

The show-when-locked and turn-screen-on flags belong to the app: it sets them while its call
screen is shown and clears them when that screen goes (`ActivityControlApi.showOverLockscreen` /
`wakeScreenOnShow`). Only the call screen may be over the keyguard; a minimized call, the keypad
or the contacts must stay behind it.

Callkeep covers the one moment the app cannot, in `LockScreenPresence`:

| Event | Flags | Why |
| --- | --- | --- |
| The Activity is opened (attach or new intent) by the incoming-call alert's full-screen intent, the phone is locked and a call is registered or pending | set | Behind the keyguard a Flutter view draws no frames, so the app never builds the call screen that would let it in; without this the call does not appear on a locked phone |
| The last call ends (`ForegroundService`, `DeclineCall` / `HungUp` / `ConnectionNotFound`) | cleared | A call that ended before the app built its call screen leaves the flags to callkeep |

The alert's intent carries `LockScreenPresence.EXTRA_OPENED_BY_CALL_ALERT`
(`NotificationBuilder.buildCallAlertIntent`). An Activity opened any other way - from the
launcher during a call, say - is never let over the keyguard by callkeep: the Activity would show
whatever screen the app is on.

## Related Components

- [foreground-service.md](foreground-service.md) — bound service wired up here
- [background-services.md](background-services.md) — IncomingCallService and ActiveCallService; bootstrap API registered on engine attach
- [pigeon-apis.md](pigeon-apis.md) — all Pigeon APIs registered here
