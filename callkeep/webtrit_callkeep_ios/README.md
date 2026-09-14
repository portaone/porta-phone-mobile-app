# webtrit_callkeep_ios

iOS implementation of [`webtrit_callkeep`](../webtrit_callkeep/README.md). Integrates CallKit and
PushKit to deliver native call UI and background VoIP push handling.

---

## How it works

| App state           | Incoming call UI                                              |
|---------------------|---------------------------------------------------------------|
| Foreground          | Flutter-based incoming call screen                            |
| Background / locked | System CallKit UI                                             |
| Terminated          | PushKit wakes the app; CallKit UI shown after app initializes |

PushKit delivers a VoIP push before the user interacts with anything, giving the app time to
establish signaling and media before CallKit presents the call.

There are no persistent background services on iOS — all background work goes through
CallKit / PushKit.

---

## iOS Simulator

CallKit and PushKit are only available on real devices — this plugin will not work on iOS
simulators. Test on a physical device.

- Incoming calls: the simulator never receives a PushKit VoIP token and cannot receive VoIP
  pushes ([`xcrun simctl push` supports application pushes only](https://www.avanderlee.com/workflow/testing-push-notifications-ios-simulator/)).
- Outgoing calls: depending on the simulator runtime, CallKit either never delivers
  `performStartCallAction` or tears the call down ~2 s after start
  ([Apple Developer Forums 749657](https://developer.apple.com/forums/thread/749657)).
- Audio: `didActivateAudioSession` does not fire on the simulator, so call audio never starts
  ([Apple Developer Forums 711956](https://developer.apple.com/forums/thread/711956)).

---

## Package structure

```text
webtrit_callkeep_ios/
├── lib/src/
│   ├── webtrit_callkeep_ios.dart     # WebtritCallkeepIOS — registers as platform instance
│   └── common/
│       ├── callkeep.pigeon.dart      # Pigeon-generated Dart bindings (DO NOT EDIT)
│       └── converters.dart           # Pigeon <-> platform_interface type conversions
├── pigeons/
│   └── callkeep.messages.dart        # Pigeon input — edit this, then regenerate
└── ios/webtrit_callkeep_ios/Sources/webtrit_callkeep_ios/
    ├── WebtritCallkeepPlugin.m        # CallKit + PushKit integration
    ├── Converters.m                   # CallKit <-> Pigeon types, provider configuration
    ├── CallWaitingTonePlayer.m        # synthesized call-waiting beep
    ├── NSUUID+v5.m                    # name-based UUID from a callId
    ├── Generated.m                    # Pigeon-generated (DO NOT EDIT)
    └── include/webtrit_callkeep_ios/  # public headers, incl. Generated.h (DO NOT EDIT)
```

---

## Delegates

| Delegate               | Registration                              | Purpose                                       |
|------------------------|-------------------------------------------|-----------------------------------------------|
| `CallkeepDelegate`     | `Callkeep().setDelegate(...)`             | Call lifecycle events                         |
| `PushRegistryDelegate` | `Callkeep().setPushRegistryDelegate(...)` | PushKit VoIP token and incoming push payloads |

`PushRegistryDelegate` must be set before the app enters the background if VoIP pushes are
expected. Failing to do so causes missed pushes.

---

## Call groups

`setCallGroup` / `unsetCallGroup` present several calls as one CallKit call group. CallKit keeps
no readable record of who is grouped with whom, so the package keeps it on the Dart side
(`CallGroupAssignment`, a record of membership and nothing else: one group at a time, under
the name the caller gave it; a second name while one is live answers
`maximumCallGroupsReached`) and only ever tells CallKit what to do. `CallGroupCoordinator`
owns that record and runs each request as a sequence of stages against it, one request at a
time in the order they were made, so a release or a second name made while a grouping is in
flight is planned against what that grouping left: members
that left are ungrouped first, then the group that remains is stated in full as one transaction
of `CXSetGroupCallAction`s grouping every member with the first. The record changes only once
CallKit takes a stage, so a refused request leaves the record describing what CallKit still
shows and a retry asks again.

CallKit hands every `CXSetGroupCallAction` back through the provider delegate, the package's own
included. The plugin fulfils the ones it requested itself (remembered by action UUID until the
delegate performs them); only grouping started in the system call UI reaches
`CallkeepDelegate.performSetCallGroup`. `supportsGrouping` / `supportsUngrouping` are raised on
the calls for the request only and lowered when CallKit answers it, so the system UI never offers
merge or split controls the application did not ask for.

A member of a group is never held on its own: `setHeld` answers `callIsGrouped`, and a hold
CallKit itself puts on a member is fulfilled by the plugin without reaching the delegate. The
record follows the calls, and the coordinator is where every end path reports: a call that ends
leaves its group and its lifetime ends (a call reported under the same id afterwards is a new
one, not the one a request in flight was asked for), a provider reset and `tearDown` end the
session and let the next session's requests run ahead of the old session's stranded ones. A
request is about the session and the calls it was made in: the coordinator takes the session
and the lifetime of every named call when the request is made, before it waits its turn, and
checks them when its turn comes and again after every awaited stage - a request of a session
that ended is over, a member that ended or was replaced is left out - so neither a request that
waited in the queue nor a late answer records anything but what is still live, asks an
invalidated provider for anything, or touches the next session's groups.

---

## iOS-only API

```dart
// Returns the current PushKit VoIP token, or null if not yet issued.
final token = await Callkeep().pushTokenForPushTypeVoIP();
```

---

## Required capabilities

In Xcode, enable:

- **Push Notifications**
- **Background Modes -> Voice over IP**

Without these, `reportNewIncomingCall` silently fails when the app is backgrounded.

---

## Code generation

```bash
# From this directory
../tool/pigeon.sh   # runs pigeon and strips the trailing whitespace its Kotlin and Objective-C generators leave
```

Never manually edit `lib/src/common/callkeep.pigeon.dart` or the Pigeon-generated
`Generated.h` and `Generated.m`. Commit the input file and all generated outputs together.

---

## Build & lint

```bash
flutter pub get
flutter analyze lib test
dart format --line-length 80 --set-exit-if-changed lib test
```

---

## Key invariants

- No persistent background services — all background handling goes through CallKit/PushKit.
- `PushRegistryDelegate` is separate from `CallkeepDelegate`.
- Never block the main thread in CallKit delegate callbacks.
- Minimum deployment target: iOS 13.0 (`webtrit_callkeep_ios.podspec`, `Package.swift`).

---

## Related packages

| Package                                                                                   | Description            |
|-------------------------------------------------------------------------------------------|------------------------|
| [`webtrit_callkeep`](../webtrit_callkeep/README.md)                                       | Public API aggregator  |
| [`webtrit_callkeep_platform_interface`](../webtrit_callkeep_platform_interface/README.md) | Shared interface       |
| [`webtrit_callkeep_android`](../webtrit_callkeep_android/README.md)                       | Android implementation |
