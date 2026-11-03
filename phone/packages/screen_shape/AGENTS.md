# screen_shape

Flutter plugin that says whether the display is round - Android's
`Configuration.isScreenRound`. Android only - every other platform answers `null`. The app reads
it once at startup through `ScreenShape.query()` (`lib/widgets/adaptive/screen_shape.dart`) and
lays watch screens out for a round or a rectangular face
([adaptive_layout.md](../../docs/architecture/adaptive_layout.md)).

## Public API

- `static Future<bool?> DisplayShape.isRound()` - one query over the MethodChannel
  `screen_shape`; `null` on any other platform, on a `null` answer and on any error.

Why it exists: a round watch face and a square one are both a square window to Flutter, with the
same size and insets; only the platform knows which it is.

| Platform | Returns | Why |
|---|---|---|
| Android | `Configuration.isScreenRound` | the maker declares the shape there (API 23+) |
| iOS | `null` | no iPhone or iPad display is round, and Flutter does not run on watchOS |
| Others | `null` | web (the configurator's preview), desktop and tests |

Without an answer the app decides from the window: a square window of watch size counts as round.

## Key Rules

- `ScreenShapePlugin` (Kotlin) implements `FlutterPlugin` and `MethodChannel.MethodCallHandler`
  and reads the application context's configuration; it needs no activity.
- Do not add iOS native code - the Dart layer already answers there.

## Commands

```bash
fvm flutter test test/screen_shape_test.dart
```

- The pre-push gate does not run this package's tests; run them here. On a device it is checked
  through the app on a round Wear OS emulator.
