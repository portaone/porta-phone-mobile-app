---
name: callkeep-android-change
description: Procedure and traps for changing the Android side of the call plugin (callkeep/webtrit_callkeep_android) - Kotlin under android/, the Pigeon definition, Telecom/ConnectionService, the :callkeep_core process, StandaloneCallService, foreground services and their types, call notifications, full-screen intent, screen wake. Load it before editing any of these, or when a request mentions Telecom, PhoneConnection, standalone, FGS, foregroundServiceType, call notification, Pigeon, Generated.kt or callkeep-android-test.
---

# Changing callkeep on Android

When: any edit under `callkeep/webtrit_callkeep_android/` - Kotlin, `pigeons/callkeep.messages.dart`,
the manifest, or its docs. Paths below are relative to that package unless they start with `callkeep/`, `phone/` or `docs/`.

## Steps

1. Read [AGENTS.md](../../../callkeep/webtrit_callkeep_android/AGENTS.md), then the doc of each
   component you touch from [docs/architecture.md](../../../callkeep/webtrit_callkeep_android/docs/architecture.md).
   Name the process the code runs in (main or `:callkeep_core`,
   [dual-process.md](../../../callkeep/webtrit_callkeep_android/docs/dual-process.md)) and the backend
   it serves: Telecom, standalone, or both
   ([standalone-call-service.md](../../../callkeep/webtrit_callkeep_android/docs/standalone-call-service.md)).
2. Make the JVM tests runnable, once per checkout: without the gitignored `android/local.properties`
   they skip themselves. Point it at the pinned SDK, which needs `flutter precache --android`:
   `echo "flutter.sdk=$(cd ../../phone && fvm flutter --version --machine | jq -r .flutterRoot)" > android/local.properties`
3. A Pigeon change:
   - First run `../tool/pigeon.sh` on the unchanged definition and check
     `git status --porcelain -- lib/src/common android/src/main/kotlin/com/webtrit/callkeep/Generated.kt`
     is empty. If it is not, the committed output had already drifted: regenerate in a commit of
     its own before your change.
   - Edit `pigeons/callkeep.messages.dart`, run `../tool/pigeon.sh` (never a bare `dart run pigeon`),
     and run the same `git status` again: exactly the definition, `lib/src/common/callkeep.pigeon.dart`
     and `Generated.kt` change, and the diff of the two generated files is only what the edit implies.
   - Add the converter in `lib/src/common/converters.dart`, the method in
     `callkeep/webtrit_callkeep_platform_interface/`, `callkeep/webtrit_callkeep/` and every
     platform package that has to answer it (iOS has its own definition, see the
     callkeep-ios-change skill), and the row in
     [pigeon-apis.md](../../../callkeep/webtrit_callkeep_android/docs/pigeon-apis.md).
   - A host method that must not wait for the app start gets `@TaskQueue` - see "Host calls
     wait for the main looper" there.
4. Write the JVM test next to the nearest existing one in `android/src/test/kotlin/com/webtrit/callkeep/`
   and prove it fails with the fix reverted. Iterate on one class:
   `(cd android && ./gradlew testDebugUnitTest --tests '*ClassName*')`.
5. Update the component docs (`docs/*.md`: the service, `call-flows.md`, `notifications.md`,
   `background-services.md`) in the same change as the code.
6. A behaviour only a device shows (ringing, full-screen intent, Telecom arbitration, audio):
   run the example's integration tests on a phone, `cd callkeep/webtrit_callkeep/example &&
   flutter test integration_test/<file>.dart` (list in
   [README.md](../../../callkeep/webtrit_callkeep_android/README.md), Integration tests), on an
   API 24-25 device or emulator too when the change touches the standalone path.

## Before handing over

- `(cd android && ./gradlew testDebugUnitTest)` ends with `BUILD SUCCESSFUL`, not `skipped:`.
- `(cd android && ./gradlew lintDebug)` - no new `NewApi` (minSdk is 24) and no
  `PhoneConnectionServiceDetector` error.
- `(cd android && ./gradlew ktlintCheck)` or `ktlint` on the changed `.kt` files, never on `Generated.kt`.
- `flutter analyze` and `flutter test` in this package; `dart format --line-length 120 --set-exit-if-changed $(git ls-files 'lib/*.dart' 'test/*.dart' ':!:*.pigeon.dart')`.
- `npx markdownlint-cli2 <changed .md>` from `callkeep/`; tables stay aligned by hand.
- A `callkeep/` change also runs the phone suite in Jenkins: `cd phone && flutter test`.

## Traps

- `callkeep-android-test` in lefthook prints `skipped:` and exits 0 without `local.properties` - read its output, see [gerrit_push.md](../../../docs/gerrit_push.md).
- Main-process code reading `ConnectionManager` sees an empty registry, silently - go through `CallkeepCore.instance` ([dual-process.md](../../../callkeep/webtrit_callkeep_android/docs/dual-process.md), Critical Rules).
- Robolectric reports Telecom as supported, so a `ForegroundService` test exercises only the Telecom path - drive `StandaloneCallService` with its own intents ([standalone-call-service.md](../../../callkeep/webtrit_callkeep_android/docs/standalone-call-service.md), Tests).
- In a Robolectric test `runBlocking { async { hostCall() } }` hangs on the paused main looper - use `async(Dispatchers.Unconfined)` and `shadowOf(mainLooper).idle()` ([example](../../../callkeep/webtrit_callkeep_android/android/src/test/kotlin/com/webtrit/callkeep/ForegroundServiceIncomingFailureTest.kt)).
- Committed Pigeon output once differed from its own definition for months and nothing noticed - always do the unchanged-tree regeneration check ([pigeon.sh](../../../callkeep/tool/pigeon.sh)).
- ktlint once reformatted all of `Generated.kt` because an exclude did not match - keep `**/Generated.kt` excluded ([lefthook.yml](../../../lefthook.yml)).
- Every Pigeon host call waits for the main looper twice, seconds on a cold start; a `@TaskQueue` handler must not touch `IncomingRegistrations` - post that part, never raise timeouts ([pigeon-apis.md](../../../callkeep/webtrit_callkeep_android/docs/pigeon-apis.md)).
- A notification posted under an id already shown is an update and sends no full-screen intent ([notifications.md](../../../callkeep/webtrit_callkeep_android/docs/notifications.md), Standalone builders).
- Waking the screen before the notification makes the system show a heads-up instead of opening the app ([notifications.md](../../../callkeep/webtrit_callkeep_android/docs/notifications.md), Call alert and screen wake).
- On Android 17 an activity start from `:callkeep_core` is blocked as a background launch - do not rely on it ([notifications.md](../../../callkeep/webtrit_callkeep_android/docs/notifications.md)).
- The `microphone` foreground type is refused from the background with `SecurityException`, and without it the far side hears silence ([background-services.md](../../../callkeep/webtrit_callkeep_android/docs/background-services.md), ActiveCallService).
- Telecom lets one self-managed call ring at a time and refuses the next; the core holds it in `IncomingCallQueue` - change second-call handling there ([callkeep-core.md](../../../callkeep/webtrit_callkeep_android/docs/callkeep-core.md), Waiting calls).
- Without `CAPABILITY_HOLD` the legacy Telecom path disconnects a held call instead of swapping; a Pixel takes the other path, so "fine on a Pixel" proves nothing ([phone-connection.md](../../../callkeep/webtrit_callkeep_android/docs/phone-connection.md)).
- An extension like `112` in the placeCall Uri is diverted to the dialer as an emergency number - keep the masked Uri ([call-flows.md](../../../callkeep/webtrit_callkeep_android/docs/call-flows.md), Outgoing Call).
- An API newer than 24 called unguarded is a `NoSuchMethodError`, which `catch (e: Exception)` does not catch, and lint does not see it inside dependencies ([NotificationChannelManager.kt](../../../callkeep/webtrit_callkeep_android/android/src/main/kotlin/com/webtrit/callkeep/managers/NotificationChannelManager.kt)).
- `Ringtone.setLooping` is public only from API 28 - use `setLoopingCompat` ([Extensions.kt](../../../callkeep/webtrit_callkeep_android/android/src/main/kotlin/com/webtrit/callkeep/common/Extensions.kt)).
- `CallMetadata` as a `Parcelable` crashes `system_server` - pass it as a Bundle ([AGENTS.md](../../../callkeep/webtrit_callkeep_android/AGENTS.md), Key invariants).
- The Jenkins Android job runs only when `webtrit_callkeep_android/android/` changes - a Dart-only change there gets no JVM run ([.jenkins/README.md](../../../.jenkins/README.md)).
