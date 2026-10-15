---
name: callkeep-ios-change
description: Procedure and traps for changing the iOS side of the call plugin (callkeep/webtrit_callkeep_ios) - the Objective-C CallKit and PushKit code, its Pigeon definition, call groups, hold, mute, and the order in which the app asks CallKit for things with several calls or when a call is restored after a reconnect. Load it before editing that package, or when a request mentions CallKit, PushKit, VoIP push, CXProvider, CXTransaction, call group, conference on iOS, second call on iPhone, or restoring a call on iOS.
---

# Changing callkeep on iOS

When: any edit under `callkeep/webtrit_callkeep_ios/`, or a change in `phone/` to the order of
`answerCall`, `setHeld`, `setCallGroup`, `startCall` or `endCall` that iOS will see. Paths below
are relative to that package unless they start with `callkeep/` or `phone/`.

## Steps

1. Read [AGENTS.md](../../../callkeep/webtrit_callkeep_ios/AGENTS.md) and
   [README.md](../../../callkeep/webtrit_callkeep_ios/README.md) (Call groups, Mute after the
   audio session comes back), and the "Group hold" comment in
   [WebtritCallkeepPlugin.m](../../../callkeep/webtrit_callkeep_ios/ios/webtrit_callkeep_ios/Sources/webtrit_callkeep_ios/WebtritCallkeepPlugin.m).
   For rooms, also "The operating system" in
   [call_conference.md](../../../phone/docs/features/call_conference.md).
2. Put the rule where it can be tested: group bookkeeping and request ordering in Dart
   (`lib/src/common/call_group_coordinator.dart`, `call_group_assignment.dart`, tested in `test/`);
   only what CallKit itself needs in Objective-C, which has no native tests.
3. For each CallKit action you touch, list every source: the app's request
   (`requestTransaction`) and the system (call UI, headset, Siri, CarPlay), which reach the
   provider delegate in the same `perform...Action`. Both pass the same policy, and the action is
   fulfilled or failed only once that decision is made.
4. A Pigeon change: run `../tool/pigeon.sh` on the unchanged definition first and check
   `git status --porcelain -- lib/src/common ios/webtrit_callkeep_ios/Sources` is empty, then edit
   `pigeons/callkeep.messages.dart`, regenerate and check only the definition,
   `callkeep.pigeon.dart`, `Generated.h` and `Generated.m` changed. The Android definition is a
   separate file: change it in the same commit when the type is shared (callkeep-android-change).
5. Tests: `flutter test` here for the Dart side. A phone-side change gets a bloc test on
   `phone/test/features/call/bloc/call_bloc_harness.dart`, asserting the order of the requests
   `FakeCallkeep` recorded (`held`, `groups`, `ungroups`, `endCalls`) - not what CallKit would do
   (the call-tests skill).
6. Compile the native code: `cd callkeep/webtrit_callkeep/example && flutter build ios --debug --no-codesign`
   (`flutter precache --ios` first on a fresh SDK). Do not commit what the build rewrites under `example/ios`.
7. Check on a real iPhone - the simulator has no VoIP push and never activates the audio session.
   Run the scenarios the change can affect, in a debug build started with `flutter run`:
   - a second call answered while the first is active: the first is held, not ended;
   - a room (call group) and then a call outside it, answered and ended; the room keeps all legs;
   - two incoming calls ringing, Accept from the system UI;
   - hold, mute and end from the system UI and a headset, not only from the app;
   - a reconnect that restores a call while another call is live;
   - app killed, call by VoIP push (profile or release build, see Traps).
   The plugin's own probe runs there too:
   `cd callkeep/webtrit_callkeep/example && flutter test integration_test/a5_concurrent_calls_probe_test.dart -d <device>`.

## Limits of the Dart tests

`FakeCallkeep` accepts every hold and group, answers no call, and models no CallKit rule. CallKit
ending one of two active ungrouped calls, refusing a reused UUID, system-originated actions, the
audio session activation and the timing between a transaction and its `perform...Action` exist
only on a device. A green suite there proves the requests were made in order, nothing more.

## Before handing over

- `flutter analyze`, `flutter test` and
  `dart format --line-length 120 --set-exit-if-changed $(git ls-files 'lib/*.dart' 'test/*.dart' ':!:*.pigeon.dart')`
  in this package - lefthook `callkeep-test` runs only the Android package's tests.
- The example builds for iOS; `cd phone && flutter test` passes (Jenkins runs it on `callkeep/` changes).
- The device scenarios that were run, and those that were not, are written in the change description.
- README.md / AGENTS.md updated in the same change when a CallKit rule changed.

## Traps

- CallKit keeps one active and one held call: a call going active while another ungrouped one is active makes CallKit end that one, and a whole conference once failed this way with every test green ([README.md](../../../callkeep/webtrit_callkeep_ios/README.md), Call groups).
- `answerCall` holds only group members; with another ungrouped call live and unheld, CallKit ends it - hold it in the same transaction, also on restore ([WebtritCallkeepPlugin.m](../../../callkeep/webtrit_callkeep_ios/ios/webtrit_callkeep_ios/Sources/webtrit_callkeep_ios/WebtritCallkeepPlugin.m), [call_bloc.dart](../../../phone/lib/features/call/bloc/call_bloc.dart) `__onMutationRestoreCall`).
- A group member is never held on its own (`callIsGrouped`): declare the group before any hold ([call_conference.md](../../../phone/docs/features/call_conference.md), The operating system).
- `requestTransaction` completing means CallKit accepted the request, not that it was performed; record state only once CallKit took it ([README.md](../../../callkeep/webtrit_callkeep_ios/README.md), Call groups).
- A hold, mute or end from the system UI or a headset bypasses the app's request path - the delegate must apply the same rules ([WebtritCallkeepPlugin.m](../../../callkeep/webtrit_callkeep_ios/ios/webtrit_callkeep_ios/Sources/webtrit_callkeep_ios/WebtritCallkeepPlugin.m), CXProviderDelegate).
- With two calls ringing, Accept in the system UI ends the other one with no reason given - expect its `performEndCall` ([WebtritCallkeepPlugin.m](../../../callkeep/webtrit_callkeep_ios/ios/webtrit_callkeep_ios/Sources/webtrit_callkeep_ios/WebtritCallkeepPlugin.m)).
- The UUID is a v5 hash of the callId, and CallKit refuses a UUID it was told ended - the same callId cannot be reported as a new call ([webtrit_callkeep_ios.dart](../../../callkeep/webtrit_callkeep_ios/lib/src/webtrit_callkeep_ios.dart), `_UUIDToCallIdMapping`).
- After the audio session comes back CallKit sends an unmute nobody asked for - the plugin refuses it for a second ([README.md](../../../callkeep/webtrit_callkeep_ios/README.md), Mute after the audio session comes back).
- Every VoIP push must report a call to CallKit, a malformed one included, or iOS stops delivering pushes ([WebtritCallkeepPlugin.m](../../../callkeep/webtrit_callkeep_ios/ios/webtrit_callkeep_ios/Sources/webtrit_callkeep_ios/WebtritCallkeepPlugin.m), `didReceiveIncomingPushWithPayloadForPushTypeVoIP`).
- Never block the main thread in a CallKit delegate callback - call Dart asynchronously ([AGENTS.md](../../../callkeep/webtrit_callkeep_ios/AGENTS.md)).
- The plugin's `NSLog` exists only under `DEBUG`, and a debug build on iOS 14+ starts only from `flutter run` or Xcode - a killed-app push needs a profile or release build and the Dart logs; in a device log `idevicesyslog -m` filters by text, `-p` by process ([WebtritCallkeepPlugin.m](../../../callkeep/webtrit_callkeep_ios/ios/webtrit_callkeep_ios/Sources/webtrit_callkeep_ios/WebtritCallkeepPlugin.m)).
- The simulator never gets a VoIP token or an audio session - test on a device ([README.md](../../../callkeep/webtrit_callkeep_ios/README.md), iOS Simulator).
- `Generated.h`, `Generated.m` and `callkeep.pigeon.dart` are never edited by hand - regenerate with [pigeon.sh](../../../callkeep/tool/pigeon.sh).
