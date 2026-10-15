# signaling_service_platform_interface

The contract of the plugin and the code every platform shares. No platform channels. The
mechanisms these classes implement - modes, the session buffer, the module factory - are
described in [ARCHITECTURE.md](../ARCHITECTURE.md); this page is the map of the classes.

## Layout (`lib/src/`)

| File | What |
|---|---|
| `signaling_service_platform.dart` | `SignalingServicePlatform`, the abstract platform; implementations must extend it (token verification) |
| `signaling_service_direct.dart` | `WebtritSignalingServiceDirect`: the socket in the calling isolate |
| `signaling_module_impl.dart` | `SignalingModuleImpl`, the module that owns a `WebtritSignalingClient`, and the default factory `createSignalingModule` |
| `signaling_request_queue.dart` | `SignalingRequestQueue`, `NotConnectedException` |
| `signaling_event_buffer.dart` | `SignalingEventBuffer`, the replay rules every boundary uses |
| `session_snapshot.dart` | `SessionSnapshot`, the handshake kept current by the session's events |
| `models/` | `SignalingModule`, `SignalingModuleEvent` (sealed), `SignalingModuleFactory`, `SignalingServiceConfig`, `SignalingServiceMode` |

The barrel `lib/signaling_service_platform_interface.dart` exports all eleven and does not
re-export `signaling`: a consumer that needs `Request`, `Event` or `StateHandshake` depends on
`signaling` itself.

## `WebtritSignalingServiceDirect`

The platform used as-is by iOS (`WebtritSignalingServiceIos`) and web
(`WebtritSignalingServiceWeb`), and as the `pushBound` delegate on Android
(`WebtritSignalingServiceAndroidDirect`). A change here affects iOS, web and Android
`pushBound` at once. Its `start()` defaults to `pushBound`, unlike the abstract platform's
`persistent`; the mode is otherwise ignored.

| Method | Behaviour |
|---|---|
| `events` | Broadcast. A new subscriber first gets the buffer's `snapshot` of the current session, then the live events |
| `sessionHandshake` | The buffer's current handshake, or `null` |
| `setModuleFactory(factory)` | Stores the factory in memory |
| `start(config, {mode})` | Throws `StateError` without a factory. Otherwise disposes the existing module, creates a new one with the factory even when the config is unchanged, pipes its events through the buffer to `events` and calls `connect()`. A `start()` overtaken by a newer `start()`, `stopService()` or `dispose()` gives up without creating a module. `onBeforeStart` / `onConnected` are the hooks for subclasses |
| `execute(request)` | Delegates to the module; throws `NotConnectedException` when there is no module or it is not connected |
| `updateMode(mode)`, `setCallEventHandler(cb)` | No-ops |
| `disconnect()` | Disconnects the module and keeps it; no-op without one |
| `stopService()` | Cancels the subscription and disposes the module; keeps the session buffer |
| `dispose()` | As `stopService()`, and clears the session buffer. Leaves the events stream open: the plugin is a singleton, and a closed stream would end existing subscriptions and break logout and re-login in one process |

## Requests: queue or throw

Two layers handle a request without a connection differently
([request_queue.md](../docs/request_queue.md)):

- a module - `SignalingModuleImpl.execute`, and `WebtritSignalingService.execute` in the facade -
  sends through `SignalingRequestQueue.executeNow` while connected and `enqueue`s otherwise; the
  queue flushes on `SignalingConnected` and fails a request with `NotConnectedException` after
  `requestTimeout` (30 s);
- a platform - `SignalingServicePlatform.execute`, as `WebtritSignalingServiceDirect` and the
  Android plugin implement it - throws `NotConnectedException` at once.

`cancelRequestsByCallId` / `clearTerminatingMark` on `SignalingModule` map to the queue's
`cancelByCallId` / `removeTerminatingMark`.

## Session buffer

`SignalingEventBuffer` holds the rules (lifecycle replayed as it came, the handshake replayed as
state, protocol events never); `SessionSnapshot` folds the protocol events into the handshake.
A change to what a late subscriber sees goes into `session_snapshot.dart` or
`signaling_event_buffer.dart`, never into one boundary, with tests in
`test/session_snapshot_test.dart` and `test/signaling_event_buffer_test.dart`. The contract:
[ARCHITECTURE.md, Session replay buffer](../ARCHITECTURE.md#session-replay-buffer).

## Commands

```bash
fvm flutter pub get
fvm flutter analyze
fvm flutter test      # not in the pre-push gate
```

## Code style

- Line width 120, single quotes, `flutter_lints/flutter.yaml`; no code generation.
