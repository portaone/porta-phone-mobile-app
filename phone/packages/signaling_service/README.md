# signaling_service

A Flutter plugin that owns the WebSocket signaling connection. In `persistent` mode (Android
only, the API default) it runs the connection in a dedicated Android foreground service so it
survives app backgrounding and process death; the main isolate receives a live event stream and
can send requests without opening a second WebSocket connection. In `pushBound` mode (what the
app passes unless the user opts into socket mode) the connection runs in the calling isolate.

All platforms expose the same Dart API. How it works inside - the Android hub and isolates,
the two modes compared, the session buffer, the background call handler - is in
[ARCHITECTURE.md](ARCHITECTURE.md).

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

## Integration tests

Located in
[`signaling_service_android/test/integration/`](signaling_service_android/test/integration).

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
