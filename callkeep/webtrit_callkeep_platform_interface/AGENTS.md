# AGENTS.md - webtrit_callkeep_platform_interface

This package defines the **shared contract** between the aggregator and all platform implementations. It contains no platform-specific code.

---

## Role

- Declares the abstract `WebtritCallkeepPlatform` class that every platform package must implement.
- Provides all shared models, enums, and delegate interfaces used across platforms.
- Contains no Flutter plugin registration and imports nothing from Flutter in `lib/` - only pure Dart.

---

## Key source locations

| Path | Contents |
| --- | --- |
| `lib/src/webtrit_callkeep_platform_interface.dart` | Abstract platform class; every method's default throws `UnimplementedError` |
| `lib/src/delegate/callkeep_delegate.dart` | `CallkeepDelegate` - main callback interface |
| `lib/src/delegate/callkeep_android_service_delegate.dart` | `CallkeepBackgroundServiceDelegate` - background isolate callbacks |
| `lib/src/delegate/callkeep_push_registry_delegate.dart` | `PushRegistryDelegate` - iOS PushKit VoIP token updates |
| `lib/src/models/` | All shared data classes and enums |
| `lib/src/consts/` | `CallDataConst`, the keys of call data in a native `Bundle` |
| `lib/src/helpers/` | `PendingCall` (`android_pending_call_handler.dart`) |

---

## Delegate contracts

### `CallkeepDelegate`

The primary callback interface. The app implements this and passes it via `Callkeep().setDelegate(...)`.

`perform*` methods return `Future<bool>`: `true` accepts the operation, `false` refuses it. A
refusal never ends the call. On iOS `false` fails the CallKit action and the system UI goes back
to the state it was in; on Android the answer is discarded, so the operation stands.

Do not add new methods here without updating all platform implementations and the aggregator.

### `CallkeepBackgroundServiceDelegate`

Used inside background isolates (Android only). Methods are `void`, not `Future<bool>` - fire-and-forget from the native side.

### `PushRegistryDelegate`

iOS-only. It has one method, `didUpdatePushTokenForPushTypeVoIP(String? token)` (`null` when
iOS invalidates the token); an incoming VoIP push is reported to CallKit by the iOS plugin itself
and reaches the app as `CallkeepDelegate.didPresentIncomingCall`. Register it via
`Callkeep().setPushRegistryDelegate(...)`.

---

## Models

Value models extend `Equatable` (`CallkeepHandle` also overrides `==`); `CallkeepAudioDevice` and
`CallkeepIncomingCallMetadata` do not, so they compare by identity.

Key models:

| Class | Purpose |
| --- | --- |
| `CallkeepHandle` | Represents a phone number, email or generic handle; use the named constructors (`.number(...)`, `.email(...)`, `.generic(...)`) |
| `CallkeepOptions` | Top-level config; contains `CallkeepIOSOptions` and `CallkeepAndroidOptions` |
| `CallkeepIncomingCallMetadata` | Metadata passed to background isolate callbacks |
| `CallkeepIncomingCallWhileRinging` | Android: a second incoming call while one rings waits in callkeep's queue (`queue`, default) or is refused and declined (`reject`); set in `CallkeepAndroidOptions` |
| `CallkeepServiceStatus` | Wraps a `CallkeepLifecycleEvent` |
| `CallkeepConnection` | Snapshot of a tracked connection's state |
| `CallkeepEndCallReason` | Enum for why a call ended (remoteEnded, failed, unanswered, etc.) |
| `CallkeepAudioDevice` | Represents an audio output device with type, id, name |

---

## Adding a new method

Follow the checklist in "Rules for every change" of [../AGENTS.md](../AGENTS.md): this package
gets the method with its `UnimplementedError` default, then the aggregator, both platform
packages, web, and `pigeon-apis.md`.

## Adding a new model or enum

1. Create the file in `lib/src/models/`.
2. Export it from `lib/src/models/models.dart`.
3. If it crosses Pigeon, add its Pigeon type to both definitions
   (`webtrit_callkeep_android/pigeons/callkeep.messages.dart`,
   `webtrit_callkeep_ios/pigeons/callkeep.messages.dart`) and a converter in each platform
   package's `lib/src/common/converters.dart`; this package has no converters.

## Consts

`lib/src/consts/` carries `@MultiplatformConstFile` / `@MultiplatformConstField` annotations, but
nothing generates from them: `build.yaml` names `tool/generator/builder.dart`, which does not
exist. The Kotlin side is a hand-written mirror,
`webtrit_callkeep_android/android/src/main/kotlin/com/webtrit/callkeep/common/Consts.kt`; a
changed or added key changes there too.

---

## Out of scope

- Platform-specific logic (use the platform package).
- Pigeon-generated code (lives in platform packages).
- Any `dart:io` / `dart:html` imports (this must remain pure Dart).
