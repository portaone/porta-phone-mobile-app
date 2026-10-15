# signaling_service

Public umbrella package for the standalone signaling service plugin.
Provides a single `WebtritSignalingService` façade; delegates everything to
`SignalingServicePlatform.instance` which is set by the platform package at startup.

## Entry Point

```dart
import 'package:signaling_service/signaling_service.dart';

// 0. Register the module factory - REQUIRED on all platforms, before connect().
//    The function must be top-level and annotated @pragma('vm:entry-point').
await WebtritSignalingService.setModuleFactory(createSignalingModule);

// 0b. (Android only) Register the background call-event handler BEFORE connect().
if (Platform.isAndroid) {
  await WebtritSignalingService.setCallEventHandler(onSignalingBackgroundCallEvent);
}

final service = WebtritSignalingService(
  config: SignalingServiceConfig(
    coreUrl: 'wss://demo.webtrit.com',
    tenantId: 'default',
    token: '<auth-token>',
  ),
  mode: SignalingServiceMode.pushBound, // defaults to persistent; the app passes pushBound unless socket mode
);

// 1. Subscribe before connecting
service.events.listen((event) {
  switch (event) {
    case SignalingConnected():      /* update UI */ break;
    case SignalingHandshakeReceived(:final handshake): /* ... */ break;
    case SignalingProtocolEvent(:final event): /* ... */ break;
    default: break;
  }
});

// 2. Connect (idempotent; no-op while a start is pending or connected)
service.connect();

// 3. Send a request (queued while disconnected, flushed on SignalingConnected)
await service.execute(HangupRequest(transaction: 'tx-1', line: 1, callId: 'call-1'));

// 4. Switch mode at runtime (static: the platform and every live instance)
await WebtritSignalingService.updateMode(SignalingServiceMode.pushBound);

// 5. Stop
await service.disconnect();
await service.dispose();
```

## Public API

### `WebtritSignalingService`

| Member | Description |
|--------|-------------|
| `WebtritSignalingService({config, mode, startPendingTimeout})` | `mode` defaults to `SignalingServiceMode.persistent`; `startPendingTimeout` (30 s) retries `connect()` when no terminal event follows a start |
| `events` | Broadcast `Stream<SignalingModuleEvent>` - safe to subscribe before `connect()` |
| `setModuleFactory(factory)` | Static. Registers the `SignalingModuleFactory`; must be called before `connect()` on all platforms |
| `connect()` / `disconnect()` | Starts the platform in the instance's mode / closes the connection; `connect()` is idempotent |
| `execute(request)` | Sends a `Request` while connected; queues it while disconnected and flushes the queue on `SignalingConnected` |
| `cancelRequestsByCallId(callId)` | Drop the queued requests of a call that is being torn down, and refuse new ones for it |
| `clearTerminatingMark(callId)` | Lift that refusal, so requests for the call id are queued again |
| `updateMode(mode)` | Static. Switches the lifecycle mode of the platform and of every live instance, so a later `connect()` starts in the new mode |
| `setCallEventHandler(callback)` | Static. Registers the app-side call-event callback (`IncomingCallEvent`, `HangupEvent`) for background handling (Android); no-op on iOS and web |
| `stopService()` / `restoreService()` / `simulateKill()` / `setHandoffCallback(cb)` | Static. Stop the Android service and clear its credentials (logout) / bring the persistent service back after an OS kill / stop it without a graceful disconnect (dev tools) / push-isolate handoff, not registered by the app |
| `dispose()` | Cancels the events subscription, fails queued requests and releases platform resources |

### `SignalingServiceMode`

`pushBound` runs the WebSocket in the calling isolate (`WebtritSignalingServiceDirect`), with no
service; `persistent` (Android only) runs it inside the foreground service (background isolate + hub):

| Value | Lifecycle | How incoming calls arrive |
|-------|-----------|--------------------------|
| `persistent` | Service survives app close; after a kill it is restarted by `START_STICKY` and `SignalingRestartWorker`. Server always has an active connection - no FCM push needed. `IncomingCallEvent` and `HangupEvent` arrive directly via the running WebSocket and are dispatched to the app callback (`onSignalingBackgroundCallEvent`). | WebSocket -> `SignalingForegroundIsolateManager` -> app callback -> callkeep |
| `pushBound` | No service. The WebSocket lives in the isolate that connects and dies with it; the server sees the client disconnected and sends an FCM push for the next call. The push-notification isolate creates its own `WebtritSignalingService(mode: pushBound)` and connects directly; the Activity isolate does the same when it opens. | FCM push -> push isolate -> own WebSocket; Activity -> own WebSocket |

**Shared hub architecture (`persistent` mode):**

```
Main isolate            ──HubConnectionManager──►  SignalingHub (background isolate, foreground service)
                                                        │
                                          └─ SignalingModule (created by app factory)
```

In `persistent` mode the WebSocket lives in the foreground-service background isolate.
The main isolate only connects to the hub and never opens its own WebSocket. The plugin would let
a push isolate attach the same way, but the app's push isolate does not: on a `persistent` device it
calls `restoreService()` and returns.

### `SignalingServiceConfig`

| Field | Type | Description |
|-------|------|-------------|
| `coreUrl` | `String` | Base URL, e.g. `wss://demo.webtrit.com` (scheme auto-converted) |
| `tenantId` | `String` | WebTrit tenant identifier |
| `token` | `String` | Auth token |
| `trustedCertificates` | `TrustedCertificates` | Custom CA certs; defaults to empty (system trust) |

### `SignalingModuleEvent` (sealed, from platform_interface)

```
SignalingConnecting
SignalingConnected
SignalingConnectionFailed  — error, isRepeated, recommendedReconnectDelay
SignalingDisconnecting
SignalingDisconnected      — code?, reason?, knownCode, recommendedReconnectDelay?
SignalingHandshakeReceived — handshake (StateHandshake)
SignalingProtocolEvent     — event (Event)
```

## Module Factory

The default module and its factory live in `signaling_service_platform_interface`; the app
registers that factory:

```dart
// signaling_service_platform_interface/lib/src/signaling_module_impl.dart
@pragma('vm:entry-point')
SignalingModule createSignalingModule(SignalingServiceConfig config) {
  return SignalingModuleImpl(
    coreUrl: config.coreUrl,
    tenantId: config.tenantId,
    token: config.token,
    trustedCertificates: config.trustedCertificates,
  );
}
```

Key constraints:
- The function must be **top-level** and annotated `@pragma('vm:entry-point')`.
- On Android: handle is serialized via `PluginUtilities.getCallbackHandle` and persisted to
  `SharedPreferences`; the background isolate resolves it at each sync via
  `PluginUtilities.getCallbackFromHandle`.
- On iOS and web, and in `pushBound` mode on Android: stored in memory, called directly in `start()`.

## Background Incoming Call Handler (Android)

When the app is closed and the service runs in `persistent` mode, call events arrive
in the background foreground-service isolate. The plugin dispatches them to a registered
app-side Dart callback so the app can trigger callkeep independently.

### App-side callback

```dart
// lib/features/call/services/background_isolate_callbacks.dart (abridged)
@pragma('vm:entry-point')
Future<void> onSignalingBackgroundCallEvent(Event event) async {
  switch (event) {
    case IncomingCallEvent():
      await AndroidCallkeepServices.backgroundPushNotificationBootstrapService.reportNewIncomingCall(
        event.callId,
        CallkeepHandle.number(event.caller),
        displayName: event.callerDisplayName,
      );
    case HangupEvent():
      // release the call so Telecom removes it
    default:
  }
}
```

### Registration (`lib/bootstrap.dart`, before the first instance)

```dart
await WebtritSignalingService.setModuleFactory(createSignalingModule);
if (kIsWeb || !Platform.isAndroid) return;
await WebtritSignalingService.setCallEventHandler(onSignalingBackgroundCallEvent);
```

The push isolate (`background_isolate_callbacks.dart`) calls only `setModuleFactory`.

Key constraints:
- Both functions must be **top-level** and annotated `@pragma('vm:entry-point')`.
- On iOS and web `setCallEventHandler` is a no-op.

## Platform Packages

| Platform | Package | Notes |
|----------|---------|-------|
| Android | `signaling_service_android` | `persistent`: foreground service + IsolateNameServer hub; factory resolved in background isolate |
| Android | `signaling_service_android` | `pushBound`: direct socket in the calling isolate (`WebtritSignalingServiceAndroidDirect`) |
| iOS | `signaling_service_ios` | Main-isolate; factory called directly in `start()` |
| Web | `signaling_service_web` | Same as iOS |

## Dependencies

- `signaling` — `Request` hierarchy, `Event`, `StateHandshake`
- `signaling_service_platform_interface` — `SignalingServicePlatform`, `SignalingModuleEvent`, `SignalingServiceConfig`, `SignalingModuleFactory`
- `signaling_service_android` / `signaling_service_ios` / `signaling_service_web` - platform implementations (resolved at build time)

## Commands

```bash
flutter pub get
flutter analyze
flutter test
```

## Code Style

- Line width: 120 characters; single quotes; `flutter_lints/flutter.yaml`.
- No code generation.
