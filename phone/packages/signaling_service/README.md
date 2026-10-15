# signaling_service

A Flutter plugin that owns the WebSocket signaling connection. In `persistent` mode (Android
only, the API default) it runs the connection in a dedicated Android foreground service so it
survives app backgrounding and process death; the main isolate receives a live event stream and
can send requests without opening a second WebSocket connection. In `pushBound` mode (what the
app passes unless the user opts into socket mode) the connection runs in the calling isolate.

**Android** in `persistent` mode runs `WebtritSignalingClient` inside `SignalingForegroundService`. Events are
forwarded to the main isolate through `IsolateNameServer` (pure Dart ports — no extra socket).
After a kill the service is restarted by `START_STICKY` and `SignalingRestartWorker`; there is no
boot receiver. In `pushBound` mode it runs the client directly in the calling isolate, like iOS.

**iOS** and **web** run `WebtritSignalingClient` directly in the main isolate via `SignalingModule`.
There are no persistent background services on iOS.

All platforms expose the same Dart API: connect, subscribe to events, send requests,
and dispose — without writing platform-specific code in your app.

---

## Package structure

This is a federated plugin. Each package except `signaling_service_web` has its own README.

| Package | Description |
| --- | --- |
| [`signaling_service`](signaling_service/README.md) | Public API — aggregates the platform implementations |
| [`signaling_service_platform_interface`](signaling_service_platform_interface/README.md) | Shared Dart interface and models |
| [`signaling_service_android`](signaling_service_android/README.md) | Android implementation (direct socket for `pushBound`, foreground service + IsolateNameServer hub for `persistent`) |
| [`signaling_service_ios`](signaling_service_ios/README.md) | iOS implementation (direct main-isolate `SignalingModule`) |
| `signaling_service_web` | Web implementation (the same as iOS) |

---

## Platform support

| Platform | Minimum version |
| --- | --- |
| Android | API 24 (Android 7.0) |
| iOS | none declared (Dart only); the app targets iOS 15.0 |

---

## Installation

```yaml
dependencies:
  signaling_service:
    path: ./packages/signaling_service/signaling_service
```

---

## Architecture (Android)

In `persistent` mode the connection runs in the **service isolate** inside `SignalingForegroundService`.
The main isolate connects to the hub via `IsolateNameServer` - no second WebSocket is ever
opened. The plugin lets a push isolate attach the same way, but the app's push isolate does not:
on a `persistent` device it calls `restoreService()` and returns.

```
+-----------------------------------------------------------------------------+
|  Android OS process                                                         |
|                                                                             |
|  +------------------------------+     +----------------------------------+  |
|  |  Main isolate                |     |  Service isolate                 |  |
|  |  (Activity / Flutter UI)     |     |  (SignalingForegroundService)    |  |
|  |                              |     |                                  |  |
|  |  WebtritSignalingServiceAndroid     |  SignalingForegroundIsolateManager  |
|  |  +- SignalingHubModule       |     |  +- SignalingModule              |  |
|  |       +- events stream  <---------IsolateNameServer- WebtritSigClient |  |
|  |                              |     |                   WebSocket      |  |
|  |  connect()           ------->|---->|                     |            |  |
|  |  execute()           ------->|---->|                  server          |  |
|  +------------------------------+     +----------------------------------+  |
|                                                                             |
+-----------------------------------------------------------------------------+
```

---

## Service modes

Only `persistent` uses the foreground service and hub; `pushBound` runs the socket in the
calling isolate with no service.

### Mode comparison

```
                    +---------------------+------------------------------+
                    |   persistent        |   pushBound                  |
+-------------------+---------------------+------------------------------+
| Who starts        | app (main isolate)  | no service: each isolate     |
| service           | via connect()       | opens its own socket         |
+-------------------+---------------------+------------------------------+
| App close         | service keeps       | socket dies with the         |
| (swipe away)      | running             | isolate                      |
+-------------------+---------------------+------------------------------+
| After a kill      | START_STICKY and    | --                           |
|                   | SignalingRestartWkr |                              |
+-------------------+---------------------+------------------------------+
| Incoming call     | WebSocket always    | server sends FCM push when   |
| delivery          | open -> direct event| socket is gone               |
+-------------------+---------------------+------------------------------+
| onStartCommand    | START_STICKY        | --                           |
+-------------------+---------------------+------------------------------+
| Foreground        | always visible      | none                         |
| notification      |                     |                              |
+-------------------+---------------------+------------------------------+
```

---

### `persistent` mode — full lifecycle

```
 App launch
    |
    v
 connect()                                +---------------------------------+
    |  Pigeon -> startService()           |  SignalingForegroundService     |
    +------------------------------------>|  SignalingModule.connect()       |
                                          |  WebSocket -----------> server  |
 App goes to background                   |                                 |
    |                                     |  service keeps running  <-------+
    v                                     |  (START_STICKY)
 service keeps running                    |
                                          |
 Service killed                           |
    |                                     |
    v                                     |
 START_STICKY / SignalingRestartWorker    |
    +- service restarts ----------------->|  service restarts, reconnects
                                          |
 Activity opens again                     |
    |                                     |
    v                                     |
 connect() - HubConnectionManager polls IsolateNameServer --+--> hub port found
    |                                     |        |
    +- SignalingHubModule subscribes <--------------+
         session buffer replayed to events stream
         UI immediately in sync                    |
                                                   |
 Activity closes (swipe away)                      |
    |                                              |
    +- service keeps running  <--------------------+
         incoming calls still dispatched to app callback

 dispose() called
    +- modules disposed, event controller left open
       (Kotlin manages service stop; stopService() on logout)
```

---

### `pushBound` mode — full lifecycle

No service is involved. When an FCM push arrives, the push isolate creates its own
`WebtritSignalingService(mode: pushBound)` and connects directly (`WebtritSignalingServiceAndroidDirect`);
when the user opens the app, the Activity isolate does the same. Each socket closes with its
isolate; the server then sees the disconnect and sends an FCM push for the next call.

---

## How Activity attaches to the service

In `persistent` mode `HubConnectionManager` is the mechanism by which an isolate connects to the
already-running hub (in the app, only the main isolate does). It does **not** open a new WebSocket.

```
 HubConnectionManager.begin()   (from WebtritSignalingServiceAndroid.start())
    |
    |  polls IsolateNameServer every 100 ms
    |  waiting for hub SendPort to appear
    |
    v  port found (hub is ready)
 SignalingHubClient.tryConnect(subscriberId)
    |
    +- step 1: ackFuture = client.awaitAck()   <- register Completer FIRST
    |                                             (before ack can arrive)
    +- step 2: SignalingHubModule wraps client <- its constructor calls
    |                                             client.start(): ['sub', ...]
    |                                             hub receives 'sub'
    |                                             hub sends: sub-ack
    |                                             hub sends: the session replay
    |          the manager listens to module.events right away
    +- step 3: await ackFuture                 <- now wait; ack arrives
                    |                             because start() already fired
                    v
             the hub's replay arrives on the listener already in place
                    |  (SignalingConnecting ... SignalingConnected ... HandshakeReceived,
                    |   the handshake rendered from the hub's session snapshot)
                    |
                    +- all future events forwarded from hub in real time
                       (the module keeps no buffer; a later listener sees only
                        what follows)

 Note: awaitAck() MUST be called before start().
       Awaiting the future before start() always times out --
       start() is what sends 'sub', which triggers the ack.
```

---

## Callkeep integration

The signaling service is callkeep-agnostic — it delivers raw `SignalingModuleEvent`s and does
not know about native call UI. The app bridges the two by registering a top-level Dart callback
via `setCallEventHandler(callback)`. The callback receives `IncomingCallEvent` or `HangupEvent` and is
responsible for triggering or releasing the system call notification via callkeep.

### persistent mode — incoming call while app is closed

```
  Server                Service isolate               App callback         Callkeep
  ------                ---------------               ------------         --------
  IncomingCallEvent
  (via WebSocket)
       |
       v
  SignalingModule
  onEvent callback
       |
       v
  SignalingForegroundIsolateManager
  _dispatchCallEvent()
       |
       +- PluginUtilities.getCallbackFromHandle(callEventHandlerHandle)
       |
       v
  onSignalingBackgroundCallEvent(event)             <- @pragma('vm:entry-point')
  [runs in service isolate]
       |
       v
  callkeep.reportNewIncomingCall(                   <- system call UI
    callId, handle, displayName)                         |
                                                         v
                                                    system notification
                                                    ringtone + lock screen
                                                    user taps Answer
                                                         |
                                                         v
                                                    Activity creates
                                                    main isolate: connect()
                                                    CallBloc receives events
```

### pushBound mode — incoming call via FCM push

The call-event handler is not involved: the push isolate opens its own WebSocket
(`WebtritSignalingService(mode: pushBound)`), and the app's push code reports the call to
callkeep from there (`lib/features/call/services/background_isolate_callbacks.dart`).

### Callback registration

```dart
// top-level function, annotated to survive tree-shaking
@pragma('vm:entry-point')
Future<void> onSignalingBackgroundCallEvent(Event event) async {
  switch (event) {
    case IncomingCallEvent():
      await callkeep.reportNewIncomingCall(
        event.callId,
        CallkeepHandle.number(event.caller),
        displayName: event.callerDisplayName,
      );
    case HangupEvent():
      // release the call
    default:
  }
}

// register once per isolate, before the first instance
if (Platform.isAndroid) {
  await WebtritSignalingService.setCallEventHandler(onSignalingBackgroundCallEvent);
}
```

Key constraints:

- Must be a **top-level** function with `@pragma('vm:entry-point')` — class methods will not work.
- The plugin resolves the raw handle internally via `PluginUtilities.getCallbackHandle` and persists it to `SharedPreferences`; the background isolate reads it at each sync.
- On iOS and web `setCallEventHandler` is a no-op; on iOS callkeep integration uses PushKit directly.

---

## Quick start

### Persistent mode (default)

```dart
// Register the module factory (every platform) and the call-event handler
// (Android only) before the first instance.
await WebtritSignalingService.setModuleFactory(createSignalingModule);
if (Platform.isAndroid) {
  await WebtritSignalingService.setCallEventHandler(onSignalingBackgroundCallEvent);
}

final service = WebtritSignalingService(
  config: SignalingServiceConfig(
    coreUrl: 'wss://demo.webtrit.com',
    tenantId: 'default',
    token: '<auth-token>',
  ),
);

// Subscribe before connect() -- session buffer replays to late subscribers.
service.events.listen((event) {
  switch (event) {
    case SignalingConnected():
      print('connected');
    case SignalingHandshakeReceived(:final handshake):
      print('registered: ${handshake.registration.status}');
    case SignalingProtocolEvent(:final event):
      print('protocol event: ${event.runtimeType}');
    case SignalingDisconnected(:final code, :final knownCode):
      print('disconnected code=$code known=$knownCode');
    default:
      break;
  }
});

service.connect();
```

### Push-initiated mode

```dart
// In the push isolate and in the main Activity alike - each opens its own socket:
final service = WebtritSignalingService(config: config, mode: SignalingServiceMode.pushBound);
service.connect();
```

### Switch mode at runtime

```dart
// Promote from pushBound to persistent after the user explicitly opens the app:
await WebtritSignalingService.updateMode(SignalingServiceMode.persistent);
// Every live instance connects in the new mode from now on; the one the
// instance was created with is not brought back by a later reconnect.
```

### Send a request

```dart
await service.execute(HangupRequest(
  transaction: 'tx-1',
  line: 1,
  callId: 'call-abc',
));
```

### Stop the service

```dart
await service.disconnect();
await service.dispose();
await WebtritSignalingService.stopService(); // on logout: stops the Android service, clears its credentials
```

---

## API reference

### `WebtritSignalingService`

| Method / property | Description |
| --- | --- |
| `WebtritSignalingService({config, mode, startPendingTimeout})` | `mode` defaults to `SignalingServiceMode.persistent`; `startPendingTimeout` (30 s) retries `connect()` when no terminal event follows a start |
| `events` | Broadcast `Stream<SignalingModuleEvent>` |
| `connect()` / `disconnect()` | Starts the platform in the instance's mode (idempotent) / closes the connection |
| `execute(request)` | Sends a `Request` while connected; queues it while disconnected and flushes the queue on `SignalingConnected` |
| `cancelRequestsByCallId(callId)` | Drop the queued requests of a call that is being torn down, and refuse new ones for it |
| `clearTerminatingMark(callId)` | Lift that refusal, so requests for the call id are queued again |
| `setModuleFactory(factory)` | Static. Registers the `SignalingModuleFactory`; required on every platform before `connect()` |
| `updateMode(mode)` | Static. Switches the lifecycle mode of the platform and of every live instance, so a later `connect()` keeps the new mode |
| `setCallEventHandler(callback)` | Static. Registers the app-side background call-event callback (Android only; no-op on iOS and web) |
| `stopService()` / `restoreService()` / `simulateKill()` | Static. Stop the Android service and clear its credentials / bring the persistent service back after an OS kill / stop it without a graceful disconnect (dev tools) |
| `setHandoffCallback(callback)` | Static. Push-isolate handoff for `pushBound`; the app does not register it |
| `dispose()` | Cancels the events subscription, fails queued requests and releases platform resources |

### `SignalingServiceMode`

| Value | Behaviour |
| --- | --- |
| `persistent` | Android only: the socket lives in a foreground service; survives app close; restarted after a kill (default) |
| `pushBound` | The socket lives in the calling isolate, no service; what the app passes unless the user opts into socket mode |

### `SignalingServiceConfig`

| Field | Type | Description |
| --- | --- | --- |
| `coreUrl` | `String` | Server base URL — `https://` and `http://` are accepted and converted to `wss://` / `ws://` |
| `tenantId` | `String` | WebTrit tenant identifier |
| `token` | `String` | Auth token |
| `trustedCertificates` | `TrustedCertificates` | Custom CA certificates; defaults to system trust |

### `SignalingModuleEvent` (sealed)

| Event | Key fields | When it fires |
| --- | --- | --- |
| `SignalingConnecting` | — | WebSocket dial started |
| `SignalingConnected` | — | TCP + WebSocket handshake complete |
| `SignalingConnectionFailed` | `error`, `isRepeated`, `recommendedReconnectDelay` | Connection attempt failed |
| `SignalingDisconnecting` | — | Graceful disconnect initiated |
| `SignalingDisconnected` | `code?`, `reason?`, `knownCode`, `recommendedReconnectDelay?` | Socket closed |
| `SignalingHandshakeReceived` | `handshake` (`StateHandshake`) | Server sent initial state |
| `SignalingProtocolEvent` | `event` (`Event`) | Any protocol event (register, call, ICE, ...) |

---

## Android background service

In `persistent` mode the Android implementation runs `WebtritSignalingClient` inside `SignalingForegroundService`
(`foregroundServiceType="phoneCall"`), which holds a `WAKE_LOCK` and survives app
backgrounding. Events are bridged to the main isolate via `IsolateNameServer` — no second
WebSocket is opened. After a kill the service is restarted by `START_STICKY` and
`SignalingRestartWorker`; there is no boot receiver. A start from the background is restricted for
apps targeting API 31+ unless an exemption applies, and Android 15 forbids starting a `phoneCall`
service from `BOOT_COMPLETED`. A refused start (`ForegroundServiceStartNotAllowedException`) is
handled where it happens: in `startForeground()` the service stops itself and `onDestroy` enqueues
`SignalingRestartWorker` in 15 s; in the worker's own start the worker returns `Result.retry()`
(exponential backoff from 15 s); in `restoreService()` the worker is enqueued in 15 s; in the start
of `connect()` the error reaches Dart, where `connect()` logs it and clears its pending start.

Required `AndroidManifest.xml` permissions (declared by the plugin, merged automatically):

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_PHONE_CALL" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

Your app manifest needs `INTERNET`. On API 34+ a `phoneCall` service also needs
`MANAGE_OWN_CALLS` (or the dialer role), which the plugin does not declare; the app gets it from
`webtrit_callkeep_android`.

---

## Session buffer and late subscribers

`SignalingModule` (service isolate) and the Android plugin (main isolate) maintain an internal
session buffer — the lifecycle events since the last `SignalingConnecting` and the current
handshake. Any new subscriber receives this buffer synchronously on `.listen()`, making it safe
to subscribe after `connect()` has already returned. The buffer is cleared on each
reconnect so stale events from a previous session are never replayed. `SignalingHubModule` has
none: `HubConnectionManager` listens to it before the hub's ack, and the hub's replay is
delivered once.

Across the isolate boundary the hub replays state rather than events: a `SessionSnapshot` keeps
the session's handshake current with the registration events and every call's events on its
line, and a subscriber that attaches late receives the lifecycle events with a handshake
rendered from it - a ringing call as a line whose log carries the offer, an answered call with
its accepted event, an ended call gone. Protocol events are never replayed to a late subscriber.

---

## Integration tests

Located in
[`signaling_service_android/test/integration/`](signaling_service_android/test/integration/).

| Test file | What it covers |
| --- | --- |
| `hub_client_integration_test.dart` | Hub registration, subscribe/ack, event broadcast, session buffer replay, execute routing |
| `bloc_flow_integration_test.dart` | Positive API flows, BLoC consumer patterns, `SignalingForegroundIsolateManager` lifecycle |
| `stress_integration_test.dart` | Event throughput (200 events, 5 clients), concurrent clients, rapid lifecycle cycles |
| `hub_connection_adoption_test.dart` | Events held until the hub's ack and forwarded once; teardown and a superseded attempt while waiting for it |
| `hub_connection_manager_integration_test.dart` | `HubConnectionManager`: connecting to a hub that runs or starts later, forwarding events, teardown, reconnect |
| `attach_pattern_integration_test.dart` | Hub attach pattern: session buffer replay, live events, execute routing, push+main coexistence, `pushBound`/`persistent` lifecycle cycles |

They run on the host with the rest of `test/`, no device needed:

```bash
cd signaling_service_android
flutter test test/integration/<test_file>.dart
```

---

## License

[MIT](../../LICENSE)
