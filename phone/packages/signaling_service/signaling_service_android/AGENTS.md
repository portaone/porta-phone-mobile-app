# signaling_service_android

The Android platform of `signaling_service`. In `pushBound` mode (what the app passes unless
the user opts into socket mode) it delegates to `WebtritSignalingServiceAndroidDirect`, the
socket in the calling isolate. In `persistent` mode (the API default) the socket runs in a
foreground service's background isolate and reaches other isolates through the `SignalingHub`
over `IsolateNameServer` ports. The modes, the hub protocol and how a subscriber attaches, the
session buffer, the module factory, the background call handler and a refused service start
are described in [ARCHITECTURE.md](../ARCHITECTURE.md); this page is the map of this package's
classes. Which isolate gets an incoming call in each case:
[incoming_call_scenarios.md](../../../docs/architecture/incoming_call_scenarios.md).

## Architecture

```
Main isolate                            Background (service) isolate
------------                            ----------------------------
WebtritSignalingServiceAndroid          signalingServiceCallbackDispatcher()
  |  Pigeon                               PSignalingServiceFlutterApi.setUp
  +-> PSignalingServiceHostApi  ------>  onSignalingServiceSync(status)
  |   startService / stopService           SignalingForegroundIsolateManager
  |   saveCallEventHandler                   SignalingModule (via factory)
  |   saveModuleFactory                      SignalingHub (IsolateNameServer)
  |                                          _dispatchCallEvent() -> app callback
  |  IsolateNameServer (SendPort)
  +-> HubConnectionManager -> SignalingHubClient
        SignalingHubModule -> events (Stream<SignalingModuleEvent>)
```

## Key classes (`lib/src/`)

### `WebtritSignalingServiceAndroid` (`plugin.dart`)

Registered by `registerWith()` as `SignalingServicePlatform.instance`. Keeps its own
`SignalingEventBuffer` in front of both transports.

| Method | Behaviour |
|---|---|
| `setModuleFactory(factory)` | Stores the factory in the direct service for `pushBound`, then persists its raw handle (`PluginUtilities.getCallbackHandle`) through `PSignalingServiceHostApi.saveModuleFactory` for the background isolate; logs a warning when there is no handle (not top-level, no `@pragma`) |
| `start(config, {mode})` | `pushBound`: starts the direct service, then forwards its events. `persistent`: gets the dispatcher handle, calls `initializeServiceCallback`, `saveConnectionConfig`, `saveTrustedCertificates`, then `startService()`, then `HubConnectionManager.begin()`. The mode a reconnect uses is kept by `WebtritSignalingService`, so a reconnect never reverts `updateMode` |
| `execute(request)` | `pushBound`: the direct service. `persistent`: the hub module while connected, otherwise throws `NotConnectedException` |
| `updateMode(mode)` | Stores the mode; without a config (before `start`) stops there. Otherwise clears the buffer, tears down the old transport (to `pushBound`: the hub manager and the service; to `persistent`: the direct service) and starts the new one |
| `setCallEventHandler(callback)` | Persists the raw handle through `saveCallEventHandler`; warns when there is no handle |
| `disconnect()` | The direct service in `pushBound`, the hub manager otherwise |
| `stopService()` | `pushBound`: stops the direct service. `persistent`: the Pigeon `stopService()`, which also clears the stored credentials |
| `restoreService()` / `simulateKill()` | The Pigeon `connect()` / `simulateKill()` |
| `dispose()` | Tears down the hub manager, disposes the direct service, resets the mode, clears the buffer. Leaves the events stream open and does not stop the Android service: Kotlin owns its lifecycle |

`onServiceDead` from the hub manager restarts the service when the mode is `persistent` and
the service was not stopped on purpose.

### `WebtritSignalingServiceAndroidDirect` (`direct/`)

A `WebtritSignalingServiceDirect` (platform interface) with the push-isolate handoff: with a
callback from `setHandoffCallback`, `onBeforeStart` registers a port under
`kPushHandoffPortName`; any other isolate that connects (`onConnected`) sends to that port, so
the push isolate can close early. Everything else is the base class.

### `HubConnectionManager` (`fgs/hub_connection_manager.dart`)

Finds the hub's port, subscribes a `SignalingHubClient` and wraps it in a `SignalingHubModule`;
discovery, the ack order and the give-up thresholds (100 ms polls, `noPortTimeout` 15 s,
`stalePortThreshold` 3 acks of 500 ms) are in
[ARCHITECTURE.md, Attaching to the hub](../ARCHITECTURE.md#attaching-to-the-hub-hubconnectionmanager).
It forwards events only for the current attempt (`_generation`), and starts discovery again
when an adopted module's stream closes.

### `SignalingHubClient` (`fgs/hub/signaling_hub_client.dart`)

One subscriber of the hub, in any isolate. `tryConnect(consumerId)` returns `null` when no hub
port is registered. `awaitAck()` must be called before `start()` (see ARCHITECTURE). `start()`
sends `sub` and schedules a liveness ping: every `pingInterval` (15 s) it sends `ping`, and with
no `pong` within `pongTimeout` (2 s) it closes `events`, which the hub module and the manager
read as a dead hub. Both values are `HubConnectionManager` constructor parameters. Raw `events`
do not replay anything.

### `SignalingHubModule` (`fgs/hub/signaling_hub_module.dart`)

The `SignalingModule` the main isolate uses in `persistent` mode, backed by a hub client.

- `connect()` / `disconnect()` send the `connect` / `disconnect` command to the hub.
- `execute` goes through the hub (`exec`); it has no queue, so `cancelRequestsByCallId` and
  `clearTerminatingMark` are no-ops (the facade's queue does that work).
- Keeps no buffer: a later listener sees only what follows.
- `isConnected` follows `SignalingConnected` / `SignalingDisconnected` /
  `SignalingConnectionFailed`; a closed client stream closes its `events`.

### `SignalingHub` (`fgs/hub/`)

Runs in the background isolate around the `SignalingModule` the factory created, answers the
commands of `signaling_hub_command.dart` (`sub`, `unsub`, `exec`, `connect`, `disconnect`,
`ping`) and sends every event, JSON-encoded by `signaling_hub_codec.dart`, to each subscriber.
It keeps a `SignalingEventBuffer` and replays its snapshot after `sub_ack`. Wire protocol:
[ARCHITECTURE.md, Hub wire protocol](../ARCHITECTURE.md#hub-wire-protocol-dart-ports-no-platform-channels).

### Background isolate (`fgs/isolate/`)

Both entry points are `@pragma('vm:entry-point')`:

| Function | Role |
|---|---|
| `signalingServiceCallbackDispatcher` (`entry_point.dart`) | Initialises bindings, sets up the `PSignalingServiceFlutterApi` handler (syncs run one after another), then calls `notifyIsolateReady()` so Kotlin sends `onSynchronize` |
| `onSignalingServiceSync(status)` (`signaling_sync_handler.dart`) | With `enabled`: creates the manager on the first sync; later updates the handles in place when only they changed, and recreates the manager when the connection config changed (re-login) - but never while a call is active. Then `handleStatus(enabled)` |

`SignalingForegroundIsolateManager` owns the module (created from `moduleFactoryHandle`) and the
hub. `handleStatus(enabled: true)` starts them (idempotent), `false` stops the hub, then the
module. On `IncomingCallEvent` / `HangupEvent` it calls `_dispatchCallEvent`, which invokes the
app's handler (see ARCHITECTURE, "Background incoming call handler"). After a failed connect or
a disconnect it reconnects by itself when the hub has no subscriber (the app is closed);
otherwise the main isolate decides, and the manager only arms a later safety reconnect in case
the main isolate's sync does not arrive.

## Pigeon (`pigeons/signaling.messages.dart`)

Only lifecycle control crosses Pigeon; events never do.

```
PSignalingServiceHostApi (Dart -> Kotlin)
  initializeServiceCallback(callbackDispatcher, onSync)
  saveConnectionConfig(coreUrl, tenantId, token)
  saveTrustedCertificates(certificatesJson?)
  saveCallEventHandler(callbackHandle)
  saveModuleFactory(callbackHandle)
  configureService(notificationTitle, notificationDescription)
  startService()
  stopService()            cancels the restart worker, clears the credentials, stops the service
  notifyIsolateReady()     from the background isolate; Kotlin answers with synchronizeIsolate()
  connect()                restoreService(): starts the service if credentials are stored
  simulateKill()

PSignalingServiceFlutterApi (Kotlin -> Dart)
  onSynchronize(PSignalingServiceStatus)

PSignalingServiceStatus
  enabled, coreUrl, tenantId, token, trustedCertificatesJson?,
  callEventHandlerHandle (0 = none), moduleFactoryHandle (0 = none)
```

`lib/src/messages.g.dart` and `Messages.g.kt` are generated: never edit them, regenerate (the
output paths are in `@ConfigurePigeon`).

## Kotlin (`android/src/main/kotlin/com/webtrit/signaling_service/`)

| File | Responsibility |
|---|---|
| `WebtritSignalingServicePlugin.kt` | `FlutterPlugin`; hosts `PSignalingServiceHostApi`; starts and stops the service; stores handles, credentials and certificates through `StorageDelegate` |
| `SignalingForegroundService.kt` | The `phoneCall` foreground service and its notification; holds a partial wake lock; creates the engine; delivers `PSignalingServiceStatus` with `synchronizeIsolate()` (up to 6 attempts, 500 ms x attempt apart); returns `START_STICKY`; `onDestroy` and `onTaskRemoved` enqueue `SignalingRestartWorker` while credentials are stored; `onFgsEngineReady` / `onFgsEngineDestroyed` let the app register other plugins on the background engine |
| `FlutterEngineHelper.kt` | Spawns the background `FlutterEngine` (`automaticallyRegisterPlugins=false`) and runs `signalingServiceCallbackDispatcher` |
| `SignalingRestartWorker.kt` | WorkManager worker that restarts the service; exponential backoff from 15 s |
| `StorageDelegate.kt` | `SharedPreferences`: dispatcher and sync handles, connection config, trusted certificates, module factory and call-event handler handles |

Manifest: `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_PHONE_CALL`, `WAKE_LOCK`,
`POST_NOTIFICATIONS`; the service is `foregroundServiceType="phoneCall"`, not exported; no boot
receiver. What happens when Android refuses to start it:
[ARCHITECTURE.md, The persistent service and a refused start](../ARCHITECTURE.md#the-persistent-service-and-a-refused-start).
`minSdkVersion 24`, `compileSdkVersion 36`, JVM 17 (`android/build.gradle`).

## Commands

```bash
fvm flutter pub get
fvm flutter analyze
fvm flutter test                                          # test/, not in the pre-push gate
fvm dart run pigeon --input pigeons/signaling.messages.dart   # regenerate the Pigeon bindings
```

`test/integration/` runs on the host under `flutter test`, like the rest of `test/`: it drives
the hub, the client and the manager over real isolate ports, with no device.

## Code style

- Line width 120, single quotes, `flutter_lints/flutter.yaml`; no `freezed`, no `build_runner`.
- Kotlin: standard Android style, JVM target 17.
