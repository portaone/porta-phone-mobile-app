# signaling_service

The public-facing package of the `signaling_service` federated plugin. Add this package
to your app - it aggregates the iOS, Android and web implementations automatically.

For the full plugin overview, setup guide, and API reference see the
[root README](../README.md).

---

## Package structure

```text
signaling_service/
├── lib/src/
│   └── signaling_service.dart          # WebtritSignalingService — connect, events, execute, dispose
└── lib/
    └── signaling_service.dart  # Barrel export
```

---

## Installation

```yaml
dependencies:
  signaling_service:
    path: ./packages/signaling_service/signaling_service
```

No additional configuration is needed — the correct platform implementation is selected
automatically via federated plugin endorsement.

---

## API (`WebtritSignalingService`)

### Lifecycle

```dart
// Once per isolate, before the first instance.
await WebtritSignalingService.setModuleFactory(createSignalingModule);

// Persistent mode (default) - Android foreground service, runs until stopped.
final service = WebtritSignalingService(config: config);

// Push-bound mode - the socket lives in this isolate, no service.
final service = WebtritSignalingService(config: config, mode: SignalingServiceMode.pushBound);

service.connect(); // idempotent
await service.disconnect();
await service.dispose();
```

### Events

```dart
service.events.listen((event) {
  switch (event) {
    case SignalingConnected():                               break;
    case SignalingHandshakeReceived(:final handshake):      break;
    case SignalingConnectionFailed(:final recommendedReconnectDelay): break;
    case SignalingDisconnected(:final knownCode):           break;
    case SignalingProtocolEvent(:final event):              break;
    default:                                               break;
  }
});
```

Subscribe before calling `connect()` - the platform implementation replays the
current session buffer to each new subscriber, so late subscribers still receive the full
current state.

### Sending requests

```dart
await service.execute(HangupRequest(
  transaction: 'tx-1',
  line: 1,
  callId: 'call-abc',
));
```

`execute` queues the request while the service is not connected and sends it on `SignalingConnected`.

### `SignalingServiceMode`

| Value | Behaviour |
| --- | --- |
| `persistent` | Android only: the socket lives in a foreground service; survives app close; restarted after a kill by `START_STICKY` and `SignalingRestartWorker` (default) |
| `pushBound` | The socket lives in the calling isolate, no service; what the app passes unless the user opts into socket mode |

---

## Related packages

| Package | Description |
| --- | --- |
| [`signaling_service_platform_interface`](../signaling_service_platform_interface/README.md) | Shared interface and models |
| [`signaling_service_android`](../signaling_service_android/README.md) | Android implementation |
| [`signaling_service_ios`](../signaling_service_ios/README.md) | iOS implementation |
| `signaling_service_web` | Web implementation |
