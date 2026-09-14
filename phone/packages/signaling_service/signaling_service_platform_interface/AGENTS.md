# signaling_service_platform_interface

Shared contract package for the `signaling_service` plugin.
Defines the abstract platform interface, event model, and config DTO.
No Flutter platform channels here — platform-specific packages implement the abstract class.

## Public API

### `SignalingServicePlatform` (abstract)

```dart
abstract class SignalingServicePlatform extends PlatformInterface {
  static SignalingServicePlatform get instance { ... }
  static set instance(SignalingServicePlatform instance) { ... }

  Stream<SignalingModuleEvent> get events;
  Future<void> setModuleFactory(SignalingModuleFactory factory);
  Future<void> start(SignalingServiceConfig config, {SignalingServiceMode mode = SignalingServiceMode.persistent});
  Future<void> attach();
  Future<void> execute(Request request);
  Future<void> updateMode(SignalingServiceMode mode);
  Future<void> setIncomingCallHandler(Function callback);
  Future<void> dispose();
}
```

Platform implementations must **extend** this class (not implement it) — `PlatformInterface` token verification enforces this at runtime.

### `SignalingServiceMode`

| Value | Behaviour |
|-------|-----------|
| `persistent` | Service runs indefinitely; survives app close; restarted on boot (default) |
| `pushBound` | Service stops when the Activity is removed (`onTaskRemoved`); suited for push-initiated calls |

### `SignalingServiceConfig`

```dart
class SignalingServiceConfig {
  const SignalingServiceConfig({
    required String coreUrl,        // e.g. 'wss://demo.webtrit.com'
    required String tenantId,
    required String token,
    TrustedCertificates trustedCertificates = TrustedCertificates.empty,
  });
}
```

### `SignalingModuleEvent` (sealed)

Defined in `lib/src/models/signaling_module_event.dart` and exported by this package.
All events are typed and exhaustively matchable:

| Event | Meaning |
|-------|---------|
| `SignalingConnecting` | WebSocket dial started |
| `SignalingConnected` | TCP + WebSocket handshake complete |
| `SignalingConnectionFailed` | Connect attempt failed; carries `error`, `isRepeated`, `recommendedReconnectDelay` |
| `SignalingDisconnecting` | Graceful disconnect initiated (local) |
| `SignalingDisconnected` | Socket closed; carries `code`, `reason`, `knownCode`, `recommendedReconnectDelay?` |
| `SignalingHandshakeReceived` | Server sent `StateHandshake`; carries `handshake` |
| `SignalingProtocolEvent` | Any other protocol `Event` (register, call, ICE, …) |

### Session buffer contract

Every replay boundary - the module that owns the socket, the Android foreground-service hub,
the module that proxies it in the app isolate and the plugin that fronts them - uses
`SignalingEventBuffer` (defined in this package), so no two of them can disagree about the
session a late subscriber sees.

**Replayed as they came (lifecycle):** `SignalingConnecting` (starts a new session: everything
before it is dropped), `SignalingConnected`, `SignalingConnectionFailed`,
`SignalingDisconnecting`, `SignalingDisconnected`.

**Replayed as state:** the handshake. It is kept as a `SessionSnapshot` - the `StateHandshake`
the session opened with, folded with every protocol event that changes session state: the
registration events, and each call's events on its line (numbered or guest), newest first as the
server orders a log; a new call opens its line, a hangup or missed call frees it at its position.
A late subscriber receives a handshake rendered from it, the one the server would send now, and
takes the same path it takes after a reconnect. A second handshake in one session replaces the
state and is replayed once.

**Never replayed:** `SignalingProtocolEvent` itself. What it changed is in the snapshot; the
rest (ICE candidates, DTMF, a media state a live call already applied) is not actionable later.
The snapshot does not keep presence, dialog or conference blocks current; they stay as the
handshake reported them.

### `SignalingEventBuffer`

Encapsulates the rules so platform implementations do not duplicate them:

```dart
class SignalingEventBuffer {
  void onEvent(SignalingModuleEvent event); // folds the event in per the contract above
  List<SignalingModuleEvent> get snapshot;  // lifecycle + the current handshake, for a new subscriber
  bool get hasActiveCalls;                  // a call is up on any line, guest line included
  void clear();                             // explicit session reset
}
```

### `SignalingModuleFactory` (typedef)

```dart
typedef SignalingModuleFactory = SignalingModule Function(SignalingServiceConfig config);
```

A factory function the app provides via `setModuleFactory()`. The plugin calls it to create a
`SignalingModule` instance when needed — on iOS directly in `start()`, on Android in
the background isolate via a serialized callback handle.

The function must be **top-level** and annotated `@pragma('vm:entry-point')` (Android requirement
so that `PluginUtilities.getCallbackHandle` can serialize it across isolate boundaries).

### `SignalingModule` (abstract)

Internal contract shared by `SignalingModuleImpl` and the plugin's `SignalingHubModule`:

```dart
abstract interface class SignalingModule {
  Stream<SignalingModuleEvent> get events;
  bool get isConnected;
  void connect();
  Future<void> disconnect();
  Future<void>? execute(Request request);
  Future<void> dispose();
}
```

## Method Notes

### `setModuleFactory(SignalingModuleFactory factory)`

Registers the app-provided factory used to create a `SignalingModule` instance.
Must be called once before `start()`.

- On Android: resolves the raw handle via `PluginUtilities.getCallbackHandle(factory)` and
  persists it via Pigeon → Kotlin → `SharedPreferences`. The background isolate resolves it
  back via `PluginUtilities.getCallbackFromHandle` on each sync.
- On iOS: stores the factory in memory; called directly in `start()`.

### `updateMode(SignalingServiceMode mode)`

Switches the service lifecycle mode at runtime without tearing down the current WebSocket
connection when not necessary.

- On Android: updates the mode flag via Pigeon (`startService(mode)`), which changes whether `onTaskRemoved` stops the service. The hub/foreground service keeps running — only the lifecycle behaviour changes.
- On iOS this is a no-op.

### `setIncomingCallHandler(Function callback)`

Registers the app-side incoming call callback for background handling.

`callback` must be a top-level function annotated with `@pragma('vm:entry-point')`. It receives
an `IncomingCallEvent` and is responsible for triggering callkeep. The Android implementation
resolves the raw handle internally via `PluginUtilities.getCallbackHandle` and persists it to
`SharedPreferences`; the background isolate reads it at each sync.

On iOS this is a no-op.

## Barrel Export

`lib/signaling_service_platform_interface.dart` — re-exports the 6 local source files (including `signaling_module_factory.dart`). Does **not** re-export `signaling` directly; consumers that need `Request`, `Event`, or `StateHandshake` must add `signaling` as a direct dependency.

## Dependencies

- `plugin_platform_interface` — `PlatformInterface` token verification
- `signaling` — `Request`, `Event`, sealed event hierarchy, `StateHandshake`
- `ssl_certificates` — `TrustedCertificates`

## Commands

```bash
dart pub get
dart analyze
dart test
```

## Code Style

- No code generation; all classes hand-written.
- Line width: 120 characters; single quotes; `lints/recommended.yaml`.
