# webtrit_callkeep

A Flutter plugin that integrates the device's native call infrastructure into VoIP and WebRTC
applications. Instead of building a custom call UI from scratch, the app delegates call
presentation and control to the OS — the same experience users get with regular phone calls.

**iOS** uses CallKit and PushKit. The system lock-screen incoming-call UI appears even when the
app is terminated. PushKit wakes the app on an incoming VoIP push before the user sees anything,
giving the app time to establish media before accepting.

**Android** uses the Telecom `ConnectionService` API running in a dedicated `:callkeep_core`
process. This process stays alive independently of the main app, so calls survive app
backgrounding and process death. Incoming calls are presented via Flutter UI backed by Android
foreground services, and outgoing calls integrate with the system dialer, Bluetooth headsets, and
audio routing.

Both platforms expose a unified Dart API: report calls, control audio, and receive delegate
callbacks — without writing platform-specific code in your app.

---

## Package structure

This is a federated plugin. Each package has its own README and `docs/` directory.

| Package | Description |
| --- | --- |
| [`webtrit_callkeep`](webtrit_callkeep/README.md) | Public API — aggregates the platform implementations |
| [`webtrit_callkeep_platform_interface`](webtrit_callkeep_platform_interface/README.md) | Shared Dart interface and models |
| [`webtrit_callkeep_android`](webtrit_callkeep_android/README.md) | Android implementation (Telecom + foreground services) |
| [`webtrit_callkeep_ios`](webtrit_callkeep_ios/README.md) | iOS implementation (CallKit + PushKit) |

---

## Platform support

| Platform | Minimum version |
| --- | --- |
| Android | API 26 (Android 8.0) |
| iOS | iOS 11 |

> **Note:** CallKit and PushKit are only available on real devices — this plugin will not work
> on iOS simulators. See [iOS Simulator](webtrit_callkeep_ios/README.md#ios-simulator).

---

## Installation

```yaml
dependencies:
  webtrit_callkeep: ^<version>
```

---

## Quick start

### 1. Initialize

Call `setUp` once after your app is ready (main isolate only).

```dart
await callkeep.setUp(
  CallkeepOptions(
    ios: CallkeepIOSOptions(
      localizedName: 'My App',
      ringtoneSound: 'assets/ringtones/incoming.caf',
      iconTemplateImageAssetName: 'assets/callkeep_icon.png',
      maximumCallGroups: 1,
      maximumCallsPerCallGroup: 1,
      supportedHandleTypes: {CallkeepHandleType.number},
    ),
    android: CallkeepAndroidOptions(
      ringtoneSound: 'assets/ringtones/incoming.mp3',
      ringbackSound: 'assets/ringtones/outgoing.mp3',
    ),
  ),
);
```

### 2. Set delegate

```dart
callkeep.setDelegate(MyCallkeepDelegate());

// iOS only — handle PushKit VoIP tokens and push payloads
callkeep.setPushRegistryDelegate(MyPushRegistryDelegate());
```

### 3. Report an incoming call

```dart
await callkeep.reportNewIncomingCall(
  callId,
  CallkeepHandle.number('+15551234567'),
  displayName: 'John Doe',
  hasVideo: false,
);
```

### 4. Start an outgoing call

```dart
await callkeep.startCall(
  callId,
  CallkeepHandle.number('+15559876543'),
  displayNameOrContactIdentifier: 'Jane Doe',
  hasVideo: false,
);
```

### 5. Tear down

```dart
await callkeep.tearDown();
```

---

## API reference

### Flutter -> Platform

Use these methods to notify the platform about call state changes.

| Method | Description |
| --- | --- |
| `setUp(options)` | Register phone account, initialize notification channels |
| `tearDown()` | Hang up all calls and release resources |
| `reportNewIncomingCall(callId, handle, ...)` | Register an incoming call with the platform |
| `reportConnectingOutgoingCall(callId, handle, ...)` | Mark outgoing call as connecting |
| `reportConnectedOutgoingCall(callId, handle, ...)` | Mark outgoing call as connected |
| `reportUpdateCall(callId, ...)` | Update call metadata (display name, video, etc.) |
| `reportEndCall(callId, reason)` | Notify platform the call ended |
| `startCall(callId, handle, ...)` | Initiate an outgoing call |
| `answerCall(callId)` | Answer a call programmatically |
| `endCall(callId)` | End a call |
| `setHeld(callId, onHold)` | Put call on hold or resume |
| `setMuted(callId, muted)` | Mute or unmute |
| `setSpeaker(callId, on)` | Toggle speaker |
| `sendDTMF(callId, digit)` | Send a DTMF tone |
| `setCallGroup(groupId, callIds)` | Present these calls to the OS as the group `groupId` |
| `unsetCallGroup(callIds)` | Take these calls out of their group |

### Platform -> Flutter (`CallkeepDelegate`)

Implement `CallkeepDelegate` and pass it to `setDelegate` to receive platform events.

| Method | When it fires |
| --- | --- |
| `didPushIncomingCall(handle, displayName, video, callId, error)` | Platform has registered the incoming call (or reports an error) |
| `performAnswerCall(callId)` | User answered from system UI |
| `performEndCall(callId)` | User ended from system UI or system terminated the call |
| `performStartCall(callId, handle, displayNameOrContactIdentifier, video)` | User initiated outgoing call from system UI (e.g. Siri) |
| `continueStartCallIntent(handle, displayName, video)` | System confirmed outgoing call intent (iOS only) |
| `performSetHeld(callId, onHold)` | User toggled hold from system UI |
| `performSetMuted(callId, muted)` | User toggled mute from system UI |
| `performSendDTMF(callId, digit)` | User sent DTMF from system dial pad |
| `performAudioDeviceSet(callId, device)` | Audio routing changed to a given device |
| `performAudioDevicesUpdate(callId, devices)` | The set of available audio devices changed |
| `performSetCallGroup(callId, groupWithCallId)` | The OS grouped this call with another, or ungrouped it when the second is null - from the system call UI, not from the application's own `setCallGroup`, which the plugin applies itself |
| `didActivateAudioSession()` | System activated the audio session |
| `didDeactivateAudioSession()` | System deactivated the audio session |
| `didReset()` | System reset all call state (iOS only) |

### Call grouping

`setCallGroup` names a group and states its whole membership rather than a change to it, so
adding a call means calling it again with every member, and the platform works out the
difference. A
caller that has lost track repairs the grouping by stating it again. Passing every member to
`unsetCallGroup` takes the group apart; an empty list does nothing, so a caller that computes
one cannot take a group apart by accident. A group needs two calls, so naming a single call in
`setCallGroup` also takes its group apart.

Grouping is presentation: it tells Telecom or CallKit that several calls belong together.
Nothing about the calls changes, so a backend that cannot group them answers
`callGroupingNotSupported` and the calls carry on. Both Android backends group calls today:
the standalone one keeps the membership itself, Telecom gets an `android.telecom.Conference`;
CallKit and web still answer `callGroupingNotSupported` (the desktop packages are not
supported platforms and keep the base stubs). The rules a backend follows are the same
everywhere:

- every backend holds one group at a time, and `setCallGroup` states its whole membership: a
  call left off the list leaves, whatever it was grouped with before; `unsetCallGroup` names
  the calls that leave. The group's name is the caller's: naming a second group while one is
  live answers `maximumCallGroupsReached` and changes nothing, and a group that fell apart
  frees its name, so more than one group can come without a change to the API;
- a member of a group is never held on its own: `setHeld` on one answers `callIsGrouped`;
  a hold the OS puts on a member while the group stands (Android Telecom does that when
  another call becomes active) is answered by the plugin and not reported to the delegate;
- a group needs two calls; a membership of one, or a member ending, takes the group apart,
  and an emptied group leaves nothing behind in the OS;
- a call that leaves a group held is made active again on the way out, so the OS holds
  whichever call it must and that hold reaches the delegate as any other;
- the membership the application declares is applied by the plugin itself;
  `performSetCallGroup` is reached only for grouping the OS starts.

`perform*` methods return `Future<bool>`. Returning `false` refuses the operation; it does not
end the call. On iOS the CallKit action fails and the system UI goes back to the state it was
in. On Android the answer is discarded - every delegate call there passes an empty result
handler - so a refusal changes nothing and the operation stands.

---

## Android background modes

Android requires a running service to handle calls when the app is backgrounded. The plugin
provides a **push notification isolate** — a short-lived Flutter isolate spawned when an FCM (or
other) push arrives. It exits after the call ends.

```dart
// Register the isolate entry-point once (main isolate, before background activity):
await AndroidCallkeepServices.backgroundPushNotificationBootstrapService
    .initializeCallback(onPushNotificationCallback);

// From your FCM background handler:
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await AndroidCallkeepServices.backgroundPushNotificationBootstrapService
      .reportNewIncomingCall(
    callId,
    CallkeepHandle.number(handle),
    displayName: displayName,
    hasVideo: hasVideo,
  );
}

// The isolate callback:
@pragma('vm:entry-point')
Future<void> onPushNotificationCallback(
  CallkeepPushNotificationSyncStatus status,
  CallkeepIncomingCallMetadata? metadata,
) async {
  await initializeDependencies();
  switch (status) {
    case CallkeepPushNotificationSyncStatus.synchronizeCallStatus:
      await backgroundCallManager.onStart();
    case CallkeepPushNotificationSyncStatus.releaseResources:
      await backgroundCallManager.close();
  }
}
```

Inside the isolate, use `CallkeepBackgroundServiceDelegate` to receive answer/end events and
`BackgroundPushNotificationService` to report call outcomes back to the platform.

Earlier versions also included a persistent signaling isolate — a long-lived foreground service
that kept a Flutter isolate running with an open WebSocket connection to the signaling server. It
was removed because Android increasingly restricts persistent background services (battery
optimization, Doze mode, vendor-specific kill policies), making reliable long-running isolates
impractical. Signaling is also application-level responsibility: the plugin is concerned with
presenting calls to the OS, not maintaining a connection. FCM high-priority push is the
recommended and sufficient mechanism to wake the device for an incoming call.

### Hosting on your own Flutter engine

If your app runs its own long-lived or headless Flutter engine (for example a foreground service
that keeps a connection open and needs to present incoming calls), set callkeep up on that engine
with `WebtritCallkeep.attachToEngine`. See
[`docs/external-flutter-engines.md`](docs/external-flutter-engines.md).

---

## Android: SMS-triggered incoming call

Android only. Allows triggering an incoming call from a specially formatted SMS — useful when push
delivery is unreliable.

**Required permissions**: `RECEIVE_SMS`, `BROADCAST_SMS`

The SMS must start with the prefix `<#> WEBTRIT:` (hard-coded security filter, do not change).
The rest of the message is parsed by a caller-supplied ICU-compatible regex that captures 4 groups
in order: `callId`, `handle`, `displayName`, `hasVideo`.

```dart
await callkeep.initializeSmsReception(
  messagePrefix: '<#> WEBTRIT:',
  regexPattern: r'your-regex-here',
);
```

Full regex specification: [`docs/sms_trigger_regex_requirements.md`](docs/sms_trigger_regex_requirements.md)

> SMS access is a sensitive Play Store permission. You must justify its use and ensure the regex
> only matches messages from your own backend.

---

## Required permissions

### Android (`AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.MANAGE_OWN_CALLS" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_PHONE_CALL" />
<!-- Optional: SMS fallback -->
<uses-permission android:name="android.permission.RECEIVE_SMS" />
<uses-permission android:name="android.permission.BROADCAST_SMS" />
```

### iOS (`Info.plist` / Xcode capabilities)

- Enable **Push Notifications** capability
- Enable **Background Modes -> Voice over IP**

---

## Integration tests

The public API is covered by integration tests in
[`webtrit_callkeep/example/integration_test/`](webtrit_callkeep/example/integration_test/).

Tests cover: lifecycle, incoming/outgoing call scenarios, state machine (hold, mute, DTMF),
foreground service timing, push notification background service path, connection queries,
delegate edge cases, and stress/concurrency scenarios.

```bash
cd webtrit_callkeep/example
flutter test integration_test/<test_file>.dart
```

---

## Example app

[`webtrit_phone`](https://github.com/WebTrit/webtrit_phone) is a reference Flutter VoIP app that
demonstrates real-world usage of this plugin including signaling, media, background call handling,
and full foreground/background workflows.

---

## Resources

- [CallKit documentation (Apple)](https://developer.apple.com/documentation/callkit)
- [ConnectionService API (Android)](https://developer.android.com/reference/android/telecom/ConnectionService)
- [Android architecture docs](webtrit_callkeep_android/docs/architecture.md)

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for branch naming, commit message format, and PR
conventions.

## License

[MIT](LICENSE)
