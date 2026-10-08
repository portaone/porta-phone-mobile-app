# signaling_service_ios

iOS implementation of `signaling_service`.

On iOS there is no equivalent of Android's foreground service — the OS suspends
background processes. The signaling connection therefore runs directly in the
main isolate (same as the original `WebtritSignalingClient` usage in `CallBloc`).

## Current State

Fully implemented, and almost empty: `WebtritSignalingServiceIos` is a subclass of
`WebtritSignalingServiceDirect` from `signaling_service_platform_interface` that adds
only the plugin registration. The module factory, the events stream, the session
buffer and the whole connection lifecycle live in the base class — change behaviour
there, not here. The same base class is the push-bound delegate on Android, so a
change to it reaches both platforms.

`lib/` does not import `signaling`: the app hands in a `SignalingModuleFactory`, and
`start()` calls it to create a `SignalingModule` in the main isolate. The package is
in `pubspec.yaml` for the tests, which build their fakes on its types.

## Public API

Registered via `WebtritSignalingServiceIos.registerWith()` as `SignalingServicePlatform.instance`.

Inherits the same interface as the Android package:

```dart
Stream<SignalingModuleEvent> get events;
StateHandshake? get sessionHandshake;
Future<void> setModuleFactory(SignalingModuleFactory factory);
Future<void> start(SignalingServiceConfig config, {SignalingServiceMode mode = SignalingServiceMode.pushBound});
Future<void> execute(Request request);
Future<void> updateMode(SignalingServiceMode mode);
Future<void> setCallEventHandler(Function callback);
Future<void> disconnect();
Future<void> stopService();
Future<void> dispose();
```

## Key Classes

### `WebtritSignalingServiceIos` (plugin entry point)

`lib/src/plugin.dart`. Holds the singleton, `registerWith()` and a `forTesting()`
constructor. Nothing below is implemented in it; the table is what it inherits.

### `WebtritSignalingServiceDirect` (inherited behaviour)

| Method | Behaviour |
|--------|-----------|
| `events` | A broadcast stream. A new subscriber first gets the buffered events of the current session, then the live ones. |
| `sessionHandshake` | The handshake of the current session from the buffer, or `null`. |
| `setModuleFactory(factory)` | Stores the factory. Must be called before `start()`. |
| `start(config, {mode})` | Throws `StateError` when no factory is registered. Otherwise disposes the existing module, creates a new one with the factory even when the config is unchanged, pipes its events to the events stream and calls `connect()`. A `start()` overtaken by a newer `start()`, `stopService()` or `dispose()` gives up without creating a module. `mode` is accepted for API compatibility — no behavioural difference on iOS. |
| `execute(request)` | Delegates to the module's `execute`; throws `NotConnectedException` when there is no module or it is not connected. |
| `updateMode(mode)` | No-op. Mode switching has no meaning on iOS. |
| `setCallEventHandler(callback)` | No-op. Background isolate callbacks are not used on iOS. |
| `disconnect()` | Disconnects the module and keeps it. No-op when there is none. |
| `stopService()` | Cancels the subscription and disposes the module. Keeps the session buffer. |
| `dispose()` | Cancels the subscription, disposes the module and clears the session buffer. Leaves the events stream open: the plugin is a singleton, and a closed stream would end existing subscriptions and break logout + re-login in the same process. |

## Commands

The package depends on the Flutter SDK, so the tests run under `flutter test`.

```bash
flutter pub get
flutter analyze
flutter test
```

## Code Style

- Line width: 120 characters; single quotes; `flutter_lints/flutter.yaml`.
