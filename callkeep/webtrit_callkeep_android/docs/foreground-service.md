# ForegroundService

**File**: `kotlin/com/webtrit/callkeep/services/services/foreground/ForegroundService.kt`

**Extends**: `Service`

**Implements**: `PHostApi` (Pigeon-generated), `CallEndListener` (a `ConnectionEventListener` that owns the end of a call)

**Annotation**: `@Keep` (must not be renamed or removed by ProGuard/R8)

## Responsibility

`ForegroundService` is the central coordinator in the **main process**. It:

- Serves as a bound service that the Flutter activity binds to for its lifetime.
- Implements the `PHostApi` Pigeon interface — all call-control commands from Dart arrive here.
- Implements `ConnectionEventListener` — receives call lifecycle events from `CallkeepCore` and
  forwards them to the Flutter layer via `PDelegateFlutterApi`.
- Manages phone account registration and notification channels.
- Bridges Android Telecom (indirect, via `CallkeepCore`) with the Flutter/Dart world.

## Lifecycle

### `onCreate()`

- Calls `CallkeepCore.instance.addConnectionEventListener(this)` to subscribe to all
  `:callkeep_core` events routed through the core's single global receiver.
- Does NOT replay connection state: at `onCreate` the Flutter delegate is not yet attached, so a
  replay fired here would only race the attach. Replay is triggered from `onDelegateSet()`.

### `onBind(intent)`

- Returns the `IBinder` that `WebtritCallkeepPlugin` uses to obtain the service reference.

### `onDelegateSet()`

- Pigeon callback invoked from Dart (`setDelegate`) once the Flutter delegate is attached and ready
  to receive events — the deterministic "delegate ready" signal (fires on every attach, including a
  warm engine re-attach).
- Sends `ReplayConnectionStates` (ungated) so `:callkeep_core` replays the connection lifecycle to
  the now-attached delegate: re-fired lifecycle events both repopulate the main-process shadow
  tracker (`connectionStates`, e.g. for the `CALL_ID_ALREADY_EXISTS` dedup in
  `reportNewIncomingCall`) and reach Flutter. This is the single, delegate-ready replay point.
- Also sends `ReplayAudioState` to re-emit audio device/mute state for the Flutter UI. Not gated on
  the main-process tracker: the `:callkeep_core` handler iterates its live connections (a no-op when
  there are none), and the local tracker is transiently empty right after the replay above.

### `onDestroy()`

- Calls `CallkeepCore.instance.removeConnectionEventListener(this)` to unsubscribe.
- Tears down audio and notification managers.

## Pigeon Host API Implementation (`PHostApi`)

### Setup / Teardown

| Method                             | Behavior                                                                                                                                    |
|------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| `setUp(handle, ringtonePath, ...)` | Registers phone account via `TelephonyUtils`, initializes notification channels (with retry on failure), stores config in `StorageDelegate` |
| `tearDown()`                       | Calls `sendTearDownConnections()`, awaits `TearDownComplete` broadcast, then cleans up connections and notifies Dart                        |

### Call Reporting

| Method                                       | Behavior                                               |
|----------------------------------------------|--------------------------------------------------------|
| `reportNewIncomingCall(callId, meta)`        | `TelephonyUtils.addNewIncomingCall()` + update tracker |
| `reportConnectingOutgoingCall(callId, meta)` | Mark call as pending in tracker                        |
| `reportConnectedOutgoingCall(callId, meta)`  | Mark call as established                               |
| `reportEndCall(callId)`                      | Force-terminate call in tracker and notify Dart        |
| `reportUpdateCall(callId, meta)`             | Update call metadata                                   |

### Call Control

| Method                           | Behavior                                                                                                                                                                                 |
|----------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `startCall(callId, meta)`        | `CallkeepCore.startOutgoingCall()`                                                                                                                                                       |
| `answerCall(callId)`             | Deferred if `PhoneConnection` not yet created (stored in `pendingAnswers`); otherwise `CallkeepCore.startAnswerCall()`                                                                   |
| `endCall(callId)`                | `CallkeepCore.startHungUpCall()`                                                                                                                                                         |
| `setMuted(callId, muted)`        | `CallkeepCore.startMutingCall()`                                                                                                                                                         |
| `setHeld(callId, held)`          | `CallkeepCore.startHoldingCall()`; answers `callIsGrouped` without forwarding when `CallkeepCore.isGrouped()` says the call is in a group                                                |
| `setSpeaker(callId, on)`         | `CallkeepCore.startSpeaker()`                                                                                                                                                            |
| `setAudioDevice(callId, device)` | `CallkeepCore.setAudioDevice()`                                                                                                                                                          |
| `sendDTMF(callId, digit)`        | `CallkeepCore.startSendDtmf()`                                                                                                                                                           |
| `setCallGroup(groupId, callIds)` | `CallkeepCore.startSetCallGroup()`; its `CallGroupOutcome` becomes the answer: `maximumCallGroupsReached` when another group is live, `callGroupingNotSupported` when no backend took it |
| `unsetCallGroup(callIds)`        | `CallkeepCore.startUnsetCallGroup()`; the core releases the calls from the group on success                                                                                              |

## Call Groups

The backend that presents a group runs in another process (Telecom) or in a service of its own
(standalone), so the main process cannot ask it synchronously whether a call is grouped. The
answer comes from the membership the application declared, and that membership lives where the
calls live: each call's record in `MainProcessConnectionTracker` carries the `groupId` it was
declared into, and `CallkeepCore` is the one place that changes it - `startSetCallGroup`
declares (one group at a time; a second name while another is live is `LIMIT_REACHED`),
`startUnsetCallGroup` releases, `markTerminated` takes a call out whichever way it ended (the
host calls `endCall` and `reportEndCall`, and the `HungUp`, `DeclineCall` and
`ConnectionNotFound` events the call service reports), a group left with one member is no group,
and `clear()` empties everything with the session on `tearDown`. This service does none of that
itself: it forwards the pigeon calls and reads `isGrouped` for `setHeld` and `groupMembersWith`
for the notification's hang-up. Because the state sits with the calls and not with this service,
it outlives the activity's bridge: the service is destroyed with the activity while the calls
and their group live on in the backend, and the next bridge finds them as the calls left them.

## Connection Event Listener: `onConnectionEvent()`

Events arrive from `CallkeepCore` via `onConnectionEvent(event, data)`. `CallkeepCore` holds a
single `globalReceiver` that receives all `:callkeep_core` broadcasts and fans them out to every
registered `ConnectionEventListener`. `ForegroundService` does not register its own
`BroadcastReceiver` directly.

**Global events** (received via `ConnectionEventListener`):

| Event                        | Handler                                  | Main Action                                                                                                                 |
|------------------------------|------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------|
| `IncomingConnectionReported` | `handleCSIncomingConnectionReported()`   | Register the call in the tracker (promote + wakelock + resolve pending callback). Register-only -- no delegate notification |
| `ReplayIncomingCall`         | `handleCSReplayIncomingCall()`           | Deliver the incoming call to a freshly attached delegate via `didPushIncomingCall` (sole foreground delivery)               |
| `ConnectionStateChanged`     | `handleCSReportConnectionStateChanged()` | `updateState()` -- mirror the authoritative connection state into the tracker                                               |
| `AnswerCall`                 | `handleCSReportAnswerCall()`             | `markAnswered()` guard in tracker, call `performAnswerCall()` on Dart delegate                                              |
| `DeclineCall`                | `handleCSReportDeclineCall()`            | `markTerminated()`, call `performEndCall()`                                                                                 |
| `HungUp`                     | `handleCSReportDeclineCall()`            | Same as DeclineCall                                                                                                         |
| `ConnectionNotFound`         | `handleCSConnectionNotFound()`           | Synthesize HungUp — `performEndCall()`                                                                                      |
| `AudioMuting`                | Inline                                   | Call `performMuteCall()` on Dart delegate                                                                                   |
| `AudioDeviceSet`             | Inline                                   | Call `performSetAudioDevice()`                                                                                              |
| `AudioDevicesUpdate`         | Inline                                   | Call `performUpdateAudioDevices()`                                                                                          |
| `ConnectionHolding`          | Inline                                   | Call `performHoldCall()`                                                                                                    |
| `SentDTMF`                   | Inline                                   | Call `performSendDTMF()`                                                                                                    |

**Per-call dynamic receivers** (registered ad-hoc via `CallkeepCore.registerConnectionEvents()`):

| Event              | Handler                           | Main Action                         |
|--------------------|-----------------------------------|-------------------------------------|
| `OngoingCall`      | `handleCSReportOngoingCall()`     | Promote outgoing call, notify Dart  |
| `OutgoingFailure`  | `handleCSReportOutgoingFailure()` | `markTerminated()`, notify Dart     |
| `IncomingFailure`  | `handleCSReportIncomingFailure()` | `markTerminated()`, notify Dart     |
| `TearDownComplete` | Inline lambda                     | Completes the `tearDown()` deferred |

## Duplicate-Notification Guards

To prevent sending the same event to Dart twice (e.g., from both the direct tearDown path and a
stale broadcast), `MainProcessConnectionTracker` maintains guard sets. `ForegroundService` checks
these before dispatching:

- `directNotifiedCallIds` — suppress `HungUp` broadcast if tearDown already notified this call.
- `endCallDispatchedCallIds` — suppress second `performEndCall()` for the same call.

## Related Components

- [callkeep-core.md](callkeep-core.md) — all Telecom commands go through here
- [connection-tracker.md](connection-tracker.md) — state mutated here on broadcast events
- [pigeon-apis.md](pigeon-apis.md) — `PHostApi` and `PDelegateFlutterApi` definitions
- [callkeep-core.md](callkeep-core.md) — `ConnectionEventListener` API and event routing
- [ipc-broadcasting.md](ipc-broadcasting.md) — cross-process broadcast transport
