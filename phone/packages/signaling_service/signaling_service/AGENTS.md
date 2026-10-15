# signaling_service

The package the app imports: `WebtritSignalingService` (`lib/src/signaling_service.dart`), a
facade that implements `SignalingModule` and delegates to `SignalingServicePlatform.instance`,
set by the platform package at registration. It also re-exports the types the app needs from
the platform interface (`SignalingModuleEvent` and its subclasses, `SignalingServiceConfig`,
`SignalingServiceMode`, `SignalingModuleFactory`, `createSignalingModule`,
`NotConnectedException`, ...). Modes, the module factory, the background call handler and the
session buffer: [ARCHITECTURE.md](../ARCHITECTURE.md).

## Entry point

```dart
import 'package:signaling_service/signaling_service.dart';

// Once per isolate, before the first instance (lib/bootstrap.dart; the push isolate again)
await WebtritSignalingService.setModuleFactory(createSignalingModule);
// Android only, see ARCHITECTURE.md "Background incoming call handler"
await WebtritSignalingService.setCallEventHandler(onSignalingBackgroundCallEvent);

final service = WebtritSignalingService(config: config, mode: SignalingServiceMode.pushBound)..connect();
service.events.listen(...);              // replays the current session first
await service.execute(request);          // queued while disconnected
await service.dispose();
```

In the app the instance comes from `SignalingServiceFactory.create(...)`
(`lib/utils/signaling_service_factory.dart`), and `MainShell` connects it.

## Public API

| Member | Description |
|---|---|
| `WebtritSignalingService({config, mode, startPendingTimeout})` | `mode` defaults to `persistent`; the app passes the mode of the user's incoming-call type. `startPendingTimeout` (30 s) resets a start that got no terminal event and calls `connect()` again |
| `events` / `sessionHandshake` | The platform's broadcast stream, safe to subscribe before `connect()`, and its current session handshake |
| `isConnected` | Set by `SignalingConnected`; cleared by `SignalingDisconnecting` (before the close handshake, which can hang), `SignalingDisconnected` and `SignalingConnectionFailed` |
| `connect()` | Starts the platform in the instance's mode. No-op when disposed, connected, or while a start is pending |
| `disconnect()` | Closes the connection through the platform |
| `execute(request)` | Connected: sends through the queue's `executeNow`; a `NotConnectedException` there marks the instance disconnected and reconnects. Disconnected: `enqueue`s it, flushed on `SignalingConnected`. What the future does and does not mean: [request_queue.md](../docs/request_queue.md) |
| `cancelRequestsByCallId(callId)` | Drops the queued requests of a call being torn down and refuses new ones for it ([request_queue.md](../docs/request_queue.md)) |
| `clearTerminatingMark(callId)` | Lifts that refusal once the teardown is complete ([request_queue.md](../docs/request_queue.md)) |
| `dispose()` | Fails queued requests, cancels the subscription, disposes the platform |
| `setModuleFactory(factory)` | Static. Required on every platform before `connect()` |
| `setCallEventHandler(callback)` | Static. Android background call events; no-op on iOS and web |
| `updateMode(mode)` | Static. Switches the platform and every live instance of this isolate, so a later reconnect does not bring the old mode back |
| `stopService()` | Static. Logout: stops the Android service and clears its stored credentials |
| `restoreService()` | Static. Brings the persistent service back after an OS kill (push isolate) |
| `simulateKill()` | Static. Stops the service without a graceful disconnect (dev tools) |
| `setHandoffCallback(cb)` | Static. Push-isolate handoff in Android `pushBound`; the app does not register it |

## Commands

```bash
fvm flutter pub get
fvm flutter analyze
fvm flutter test      # test/signaling_service_test.dart; not in the pre-push gate
```

## Code style

- Line width 120, single quotes, `flutter_lints/flutter.yaml`; no code generation.
