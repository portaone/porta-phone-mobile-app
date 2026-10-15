# AGENTS.md - webtrit_callkeep_ios

The iOS implementation: CallKit and PushKit in Objective-C, with the call-group bookkeeping in
Dart. How it behaves - call groups, their hold, mute after the audio session comes back, the
simulator - is in [README.md](README.md); the procedure and its traps are the
`callkeep-ios-change` skill; the commands are in [../AGENTS.md](../AGENTS.md).

## Where things are

- `lib/src/webtrit_callkeep_ios.dart` - the platform class; maps callId to the CallKit UUID.
- `lib/src/common/call_group_assignment.dart`, `lib/src/common/call_group_coordinator.dart` -
  the group record and the ordered requests against it, tested in `test/`.
- `lib/src/common/converters.dart` - Pigeon to platform interface types.
- `ios/webtrit_callkeep_ios/Sources/webtrit_callkeep_ios/WebtritCallkeepPlugin.m` - the
  `CXProvider` and `PKPushRegistry` delegates.
- Pigeon: definition `pigeons/callkeep.messages.dart` (separate from the Android one); output
  `lib/src/common/callkeep.pigeon.dart`,
  `ios/webtrit_callkeep_ios/Sources/webtrit_callkeep_ios/Generated.m` and
  `ios/webtrit_callkeep_ios/Sources/webtrit_callkeep_ios/include/webtrit_callkeep_ios/Generated.h`.
  Regenerate with `../tool/pigeon.sh`, never edit.

Group logic and request ordering belong in Dart, where they are tested; Objective-C gets only
what CallKit itself needs - it has no native tests.

## CallKit invariants

- Every incoming call is shown by CallKit, in the foreground as well; the plugin has no call
  screen of its own.
- A VoIP push is reported to CallKit natively, in `didReceiveIncomingPushWithPayloadForPushTypeVoIP`,
  from the payload keys `callId`, `handleType`, `handleValue`, `displayName`, `hasVideo`; Dart
  learns of it from `CallkeepDelegate.didPresentIncomingCall`. A malformed payload is still
  reported, and ended at once, or iOS stops delivering pushes. `PushRegistryDelegate` gets only
  the VoIP token (`didUpdatePushTokenForPushTypeVoIP`, `null` when it is invalidated).
- The CallKit UUID is a name-based v5 UUID of the callId, computed the same way in Dart and
  Objective-C, so a push and a signaling report of one call meet on one UUID.
- CallKit keeps one active and one held call; a call going active while another ungrouped one is
  active makes CallKit end that one. Hold the other call in the same transaction.
- A `perform...Action` is fulfilled or failed only once the delegate answered; `false` fails it
  and the system UI goes back. Never block the main thread in a provider delegate callback - call
  Dart asynchronously through Pigeon.

Minimum deployment target: iOS 13.0 (`ios/webtrit_callkeep_ios.podspec`,
`ios/webtrit_callkeep_ios/Package.swift`).
