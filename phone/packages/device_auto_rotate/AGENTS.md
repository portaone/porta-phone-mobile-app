# device_auto_rotate

Flutter plugin that reads and watches the Android system auto-rotate setting. Android only -
every other platform answers `true`. The app reads it through
`lib/features/orientations/utils/device_rotation_util.dart` before it forces an orientation
([adaptive_layout.md](../../docs/architecture/adaptive_layout.md)).

## Public API

- `static Future<bool> get DeviceAutoRotate.isEnabled` - one query over a MethodChannel;
  `true` on any error or a `null` answer.
- `static Stream<bool> get DeviceAutoRotate.stream` - an EventChannel backed by a
  ContentObserver. It emits the current value as soon as it is listened to, then on every
  change of the setting.
- Errors on the stream are swallowed without a value: `handleError((_) => true)` drops the
  error and emits nothing, so a listener keeps the last value it had (current behaviour, not a
  `true` fallback).

Why only Android: there `SystemChrome.setPreferredOrientations` can override the system rotation
lock, so the app checks the setting before forcing landscape.

| Platform | Returns | Why |
|---|---|---|
| Android | `Settings.System.ACCELEROMETER_ROTATION == 1` (`false` if locked or unset, `true` if unreadable) | the app's orientation request would bypass the lock |
| iOS | always `true` | iOS enforces the orientation lock itself and ignores a landscape request while it is on |
| Others | always `true` (`stream` is a single `true`) | fallback for web, desktop and tests |

## Architecture

```
DeviceAutoRotate (lib/device_auto_rotate.dart)
  +-- MethodChannel "device_auto_rotate"          one query
  +-- EventChannel  "device_auto_rotate_stream"   stream
        |
DeviceAutoRotatePlugin.kt (android/)
  +-- onMethodCall()  reads Settings.System.ACCELEROMETER_ROTATION
  +-- onListen()      registers the ContentObserver and sends the current value
  +-- onCancel()      unregisters it
```

## Key Rules

- `DeviceAutoRotatePlugin` (Kotlin) implements `FlutterPlugin`, `MethodChannel.MethodCallHandler`
  and `EventChannel.StreamHandler`.
- The ContentObserver is registered in `onListen()` and unregistered in `onCancel()` - keep
  that lifecycle.
- Do not add iOS native code - the Dart layer already answers there.

## Commands

```bash
fvm flutter test test/device_auto_rotate_test.dart
cd example && fvm flutter test integration_test/plugin_integration_test.dart   # on a device
cd example && fvm flutter run
```

- The pre-push gate does not run this package's tests; run them here.
- `example/` is not a member of the phone workspace: it resolves on its own (`fvm flutter pub get`
  inside it) and keeps its own `pubspec.lock`.
