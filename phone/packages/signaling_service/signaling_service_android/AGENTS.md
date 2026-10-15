# signaling_service_android

Android implementation of `signaling_service`.
In `persistent` mode (the API default; the app passes it only when the user opts into socket
mode) it runs the WebSocket connection inside an Android foreground service so it survives
when the app is backgrounded or killed, and bridges it back to the main isolate
via `IsolateNameServer` (pure Dart ports - no extra WebSocket). In `pushBound` mode (what the
app passes otherwise) it delegates to `WebtritSignalingServiceAndroidDirect`, with the socket in
the calling isolate and no service.

The package depends on `signaling` directly (for `Request`, `Event`,
`StateHandshake`, and hub codec). The app provides a `SignalingModuleFactory`
via `setModuleFactory()` - the background isolate (or, in `pushBound`, the direct service) calls it to create a `SignalingModule`.

## Architecture

```
Main isolate                         Background (service) isolate
─────────────────────────────────    ──────────────────────────────────────
WebtritSignalingServiceAndroid        signalingServiceCallbackDispatcher()
  │                                     └─ PSignalingServiceFlutterApi.setUp
  │  Pigeon (MethodChannel)          onSignalingServiceSync(status)
  ├──► PSignalingServiceHostApi ──►    └─ SignalingForegroundIsolateManager
  │    startService / stopService          ├─ SignalingModule (via factory)
  │    saveCallEventHandler                ├─ SignalingHub     (IsolateNameServer)
  │    saveModuleFactory                   └─ _dispatchCallEvent()
  │                                               └─ app callback (IncomingCallEvent, HangupEvent)
  │  IsolateNameServer (SendPort)
  └──► HubConnectionManager ──► SignalingHubClient
         └─ SignalingHubModule
              └─ events (Stream<SignalingModuleEvent>)
```

## Key Classes

### `WebtritSignalingServiceAndroid` (plugin entry point)

Registered via `registerWith()` as `SignalingServicePlatform.instance`.

| Method | Behaviour |
|--------|-----------|
| `setModuleFactory(factory)` | Stores the factory in the direct service for `pushBound`, then resolves the raw handle via `PluginUtilities.getCallbackHandle(factory)`, persists it via `PSignalingServiceHostApi.saveModuleFactory` -> `StorageDelegate` -> `SharedPreferences`. The background isolate reads `PSignalingServiceStatus.moduleFactoryHandle` at each sync and resolves the factory via `PluginUtilities.getCallbackFromHandle`. |
| `start(config, {mode})` | `pushBound`: starts the direct service and forwards its events. `persistent`: obtains the dispatcher callback handle, calls `initializeServiceCallback`, `saveConnectionConfig`, `saveTrustedCertificates` and `startService()` via Pigeon, then `HubConnectionManager.begin()` polls until the hub port appears. The mode a reconnect uses is kept by `WebtritSignalingService` (`updateMode` switches its live instances), so reconnect calls never revert a user-selected `updateMode` change. |
| `execute(request)` | `pushBound`: delegates to the direct service. `persistent`: delegates to the hub module. Throws `NotConnectedException` when not connected. |
| `updateMode(mode)` | Saves new mode to `_currentMode`, clears the session buffer, tears down the transport of the old mode (to `pushBound`: the hub and the foreground service; to `persistent`: the direct service) and starts the new one, so one account never holds two sockets. |
| `setCallEventHandler(callback)` | Resolves the raw handle via `PluginUtilities.getCallbackHandle(callback)`, persists it via `PSignalingServiceHostApi.saveCallEventHandler` -> `StorageDelegate` -> `SharedPreferences`. Logs a warning if the handle cannot be resolved (function not top-level or missing `@pragma`). The background isolate reads the handle from `PSignalingServiceStatus.callEventHandlerHandle` at each sync. |
| `dispose()` | Tears down the hub manager, disposes the direct service, resets `_currentMode`. Does **not** close `_eventsController` - closing it would silently terminate active subscribers (e.g. `CallBloc`) via `onDone`; leaving it open preserves subscriptions across `dispose`/`start` cycles. Does **not** call `stopService()` - the Android service lifecycle is managed by Kotlin. |

Hub init (`HubConnectionManager._initLoop`) polls with a 100 ms retry delay until the hub port appears in `IsolateNameServer` or `tearDown()` cancels the loop. If no port appears for `noPortTimeout` (15 s), or a found port misses its 500 ms ack `stalePortThreshold` (3) times in a row (the port is then removed), it emits `SignalingConnectionFailed` and calls `onServiceDead`, which restarts the service in `persistent` mode.

### `SignalingHub`

Runs in the background isolate. Wraps `SignalingModule` (created by the app factory)
and forwards events to all subscriber `SendPort`s via `IsolateNameServer`.

Hub wire protocol (List messages with the tag at index 0, subscriber -> hub; `lib/src/fgs/hub/signaling_hub_command.dart`):

| Command | Fields | Description |
|---------|--------|-------------|
| `sub`   | `id`, `port` | Subscribe; hub replies with sub-ack, then the session's lifecycle events and a handshake rendered from its `SessionSnapshot` |
| `unsub` | `id` | Unsubscribe |
| `exec`  | `id`, `corr`, `req` | Execute request; hub replies with `encodeExecuteResult(corr, error)` |
| `connect` / `disconnect` | `id` | Ask the hub's module to connect / disconnect |
| `ping` | `id` | Liveness check; hub replies with a pong |

The hub keeps a `SignalingEventBuffer`: lifecycle events in order and a `SessionSnapshot` (`signaling_service_platform_interface`) - the handshake kept current by the registration and call events, guest line included - rendered again for a late subscriber; cleared on `SignalingConnecting`. Protocol events are never replayed across the boundary.

### `SignalingHubClient`

Runs in any isolate (main or push). Connects to the hub via `IsolateNameServer`.

```dart
// Correct subscription sequence:
//   1. awaitAck()  — registers the internal Completer BEFORE the ack can arrive
//   2. start()     — sends 'sub' to the hub, which triggers the sub-ack reply
//   3. await       — now wait; the ack arrives because start() was already called
final client = SignalingHubClient.tryConnect('my_consumer');
if (client != null) {
  final ackFuture = client.awaitAck(timeout: Duration(milliseconds: 500));
  client.start(); // sends 'sub' → hub replies with sub-ack
  if (await ackFuture) {
    // use client
  } else {
    await client.dispose(); // stale port — hub did not respond
  }
}
```

`awaitAck` must be called before `start()` — NOT awaited before `start()`. Getting the
future first ensures the `Completer` is in place before the hub's sub-ack can arrive.
Awaiting the future before calling `start()` would always time out because `start()` is
what sends the `sub` command that triggers the ack.

### `SignalingHubModule`

`SignalingModule` implementation backed by a `SignalingHubClient`.
Used by the main isolate when the hub is already running in the foreground service.

- `connect()` / `disconnect()` send the `connect` / `disconnect` command to the hub (`sendConnect()` / `sendDisconnect()`).
- Keeps no buffer: `HubConnectionManager` listens to `events` before awaiting the hub's ack, so the replay that follows the ack is not missed. A later listener sees only what follows.
- `isConnected` tracks `SignalingConnected` / `SignalingDisconnected` / `SignalingConnectionFailed`.

### Background isolate entry points

Both functions **must** be annotated `@pragma('vm:entry-point')` to survive tree-shaking:

| Function | Role |
|----------|------|
| `signalingServiceCallbackDispatcher` | Step 1 — initialises Flutter bindings, registers `PSignalingServiceFlutterApi` handler, then calls `PSignalingServiceHostApi().notifyIsolateReady()` so Kotlin knows the isolate is ready to receive `onSynchronize` calls |
| `onSignalingServiceSync(status)` | Step 2 — if `enabled=true` and credentials changed (re-login), disposes the existing manager and creates a fresh one; otherwise creates on first call; delegates to `handleStatus` on every sync |

### `SignalingForegroundIsolateManager`

Owns `SignalingModule` (created via `moduleFactory`) + `SignalingHub` inside the background isolate.
`handleStatus(enabled: true)` → `_start()` (idempotent).
`handleStatus(enabled: false)` → `_stop()` (disposes hub then module).

**Module creation in `_start()`:**

```dart
final factory = PluginUtilities.getCallbackFromHandle(
  CallbackHandle.fromRawHandle(moduleFactoryHandle),
) as SignalingModuleFactory;
_signalingModule = factory(config);
```

**Call event dispatch** (`_dispatchCallEvent`):

When a `SignalingProtocolEvent` carrying an `IncomingCallEvent` or a `HangupEvent` arrives and
`callEventHandlerHandle != 0`, the manager:

1. Resolves the registered Dart callback via `PluginUtilities.getCallbackFromHandle`.
2. Invokes it with `Function.apply(callback, [event])` — works for both sync and async callbacks.
3. Async errors are caught and logged; sync throws are caught and logged.

If `callEventHandlerHandle == 0` (no handler registered), a warning is logged and the
event is silently forwarded only to hub subscribers (main isolate, if connected).

## Pigeon API (`pigeons/signaling.messages.dart`)

Events never cross via Pigeon — only lifecycle control does.

```
PSignalingServiceHostApi (Dart → Kotlin)
  initializeServiceCallback(callbackDispatcher, onSync)
  saveConnectionConfig(coreUrl, tenantId, token)
  saveTrustedCertificates(certificatesJson?)
  saveCallEventHandler(callbackHandle)      <- persists raw call-event handler handle
  saveModuleFactory(callbackHandle)         ← persists raw SignalingModuleFactory handle
  configureService(notificationTitle, notificationDescription)
  startService()
  stopService()
  notifyIsolateReady()                      ← called by background isolate after setUp; Kotlin responds with synchronizeIsolate()
  connect()                                 <- restoreService(): brings the persistent service back
  simulateKill()

PSignalingServiceFlutterApi (Kotlin → Dart)
  onSynchronize(PSignalingServiceStatus)

PSignalingServiceStatus
  enabled: bool
  coreUrl: String
  tenantId: String
  token: String
  trustedCertificatesJson: String?
  callEventHandlerHandle: int           <- 0 = no handler registered
  moduleFactoryHandle: int              ← 0 = factory not registered
```

`Messages.g.kt` / `messages.g.dart` are generated by Pigeon — **do not edit manually**.
Re-generate with:

```bash
dart run pigeon --input pigeons/signaling.messages.dart
```

## Android Native (`android/src/main/kotlin/`)

| File | Responsibility |
|------|---------------|
| `WebtritSignalingServicePlugin.kt` | `FlutterPlugin` entry point; hosts `PSignalingServiceHostApi`; starts/stops `SignalingForegroundService`; saves callback handles, credentials and certificates via `StorageDelegate` |
| `SignalingForegroundService.kt` | Android `Service`; starts/stops foreground notification (`phoneCall` type); creates `FlutterEngineHelper`; delivers `PSignalingServiceStatus` (including `moduleFactoryHandle` and `callEventHandlerHandle`) to the background isolate via `synchronizeIsolate()` which retries with linear backoff on failure; returns `START_STICKY`; on `onTaskRemoved` enqueues `SignalingRestartWorker`; `onFgsEngineReady` / `onFgsEngineDestroyed` hooks let the app register other plugins' APIs on the background engine |
| `FlutterEngineHelper.kt` | Spawns a background `FlutterEngine` (`automaticallyRegisterPlugins=false`), runs `signalingServiceCallbackDispatcher`, fires `onSynchronize` to the background isolate |
| `SignalingRestartWorker.kt` | WorkManager worker that restarts the service after it died or the task was removed |
| `StorageDelegate.kt` | Persists `callbackDispatcherHandle`, `onSyncHandler`, connection params, trusted certificates, `moduleFactoryHandle`, and call-event handler handle to `SharedPreferences` |

## AndroidManifest permissions

```
FOREGROUND_SERVICE
FOREGROUND_SERVICE_PHONE_CALL         <- required for phoneCall service type (Android 14+)
WAKE_LOCK
POST_NOTIFICATIONS
```

`foregroundServiceType="phoneCall"` - the service exists to deliver VoIP calls. A start from the
background is restricted for apps targeting API 31+ unless an exemption applies (a high-priority
FCM message, a notification interaction, ...), and for apps targeting API 35+ Android 15 forbids
starting it from `BOOT_COMPLETED`. A refused start (`ForegroundServiceStartNotAllowedException`) is handled where
it happens:

- in `startForeground()` inside `onCreate`: the service stops itself and `onDestroy` enqueues
  `SignalingRestartWorker` to retry in 15 s;
- in `startForegroundService()` inside `SignalingRestartWorker`: the worker returns
  `Result.retry()`, exponential backoff from 15 s;
- in the Pigeon `connect()` (`restoreService()`): `SignalingRestartWorker` is enqueued in 15 s;
- in the Pigeon `startService()`: not caught, so it reaches the Dart caller - `connect()` logs it
  and clears its pending start, `updateMode()` rethrows it, the restart after the hub dies logs it.

There is no boot receiver.

`minSdkVersion 24`, `compileSdkVersion 36` (`android/build.gradle`).

## Session buffer

For the buffer contract and which event types are buffered see
`signaling_service_platform_interface/AGENTS.md`. The hub renders a handshake from the shared
`SessionSnapshot` (calls on their lines with their events so far, current registration), so a late
subscriber restores calls the way it does after a reconnect instead of re-living the session's
events; the app's handshake plan carries the caller's last media state with a restored call.

Raw `SignalingHubClient.events` does **not** replay, and `SignalingHubModule` keeps no buffer
either: attach the listener before the hub's ack is awaited, as `HubConnectionManager` does.

## Commands

```bash
flutter pub get
flutter analyze
flutter test                                                                           # test/, including test/integration/ (runs on the host)
dart run pigeon --input pigeons/signaling.messages.dart     # regenerate Pigeon bindings
```

## Code Style

- Line width: 120 characters; single quotes; `flutter_lints/flutter.yaml`.
- No `freezed`; no `build_runner`.
- Kotlin: standard Android style, JVM target 17.
