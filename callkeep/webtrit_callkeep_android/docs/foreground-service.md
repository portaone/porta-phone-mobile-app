# ForegroundService

**File**: `kotlin/com/webtrit/callkeep/services/services/foreground/ForegroundService.kt`

**Extends**: `Service`

**Implements**: `PHostApi` (Pigeon-generated), `CallEndListener` (a `ConnectionEventListener` that owns the end of a call)

**Annotation**: `@Keep` (must not be renamed or removed by ProGuard/R8)

## Responsibility

`ForegroundService` is the Flutter activity bridge in the **main process**. It:

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
- Calls `detachIncomingClient(this)` to finish its waiting host calls. A registration shared
  with a push client keeps waiting for the backend; confirmed calls also remain live.
- Tears down audio and notification managers.

## Pigeon Host API Implementation (`PHostApi`)

### Setup / Teardown

| Method                               | Behavior                                                                                                                                                                                          |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `setUp(handle, ringtonePath, ...)`   | Registers phone account via `TelephonyUtils`, initializes notification channels (with retry on failure), stores config in `StorageDelegate`                                                       |
| `tearDown()`                         | Ends all incoming registrations through `endIncomingRegistrations()`, notifies Dart for confirmed calls, sends `sendTearDownConnections()`, then awaits `TearDownComplete` before resetting state |

### Call Reporting

| Method                                       | Behavior                                                                                                                                                                                                                                                                                                                                   |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `reportNewIncomingCall(callId, meta)`        | Awaits `CallkeepCore.registerIncomingCall(meta, this)`; core owns dispatch, tracker transitions and outcome                                                                                                                                                                                                                                |
| `reportConnectingOutgoingCall(callId, meta)` | Mark call as pending in tracker                                                                                                                                                                                                                                                                                                            |
| `reportConnectedOutgoingCall(callId, meta)`  | Mark call as established                                                                                                                                                                                                                                                                                                                   |
| `reportEndCall(callId)`                      | Hand the end to `CallkeepCore.reportCallEnded` (terminate, ghost guard for a never-presented end, pending release, end in the backend). `ForegroundServiceProxy` hands it to the core itself while the service is still binding: the fact must not wait on the bind, or the replay the bind triggers presents a call the app knows is over |
| `reportUpdateCall(callId, meta)`             | Update call metadata                                                                                                                                                                                                                                                                                                                       |

### Call Control

| Method                             | Behavior                                                                                                                                                                                   |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `startCall(callId, meta)`          | `CallkeepCore.startOutgoingCall()`                                                                                                                                                         |
| `answerCall(callId)`               | Deferred if `PhoneConnection` not yet created (stored in `pendingAnswers`); otherwise `CallkeepCore.startAnswerCall()`                                                                     |
| `endCall(callId)`                  | `CallkeepCore.appEndingCall()` completes any waiting report, then `CallkeepCore.startHungUpCall()`                                                                                         |
| `setMuted(callId, muted)`          | `CallkeepCore.startMutingCall()`                                                                                                                                                           |
| `setHeld(callId, held)`            | `CallkeepCore.startHoldingCall()`; answers `callIsGrouped` without forwarding when `CallkeepCore.isGrouped()` says the call is in a group                                                  |
| `setSpeaker(callId, on)`           | `CallkeepCore.startSpeaker()`                                                                                                                                                              |
| `setAudioDevice(callId, device)`   | `CallkeepCore.setAudioDevice()`                                                                                                                                                            |
| `sendDTMF(callId, digit)`          | `CallkeepCore.startSendDtmf()`                                                                                                                                                             |
| `setCallGroup(groupId, callIds)`   | `CallkeepCore.startSetCallGroup()`; its `CallGroupOutcome` becomes the answer: `maximumCallGroupsReached` when another group is live, `callGroupingNotSupported` when no backend took it   |
| `unsetCallGroup(callIds)`          | `CallkeepCore.startUnsetCallGroup()`; the core releases the calls from the group on success                                                                                                |

## Call Groups

The rules themselves - one group at a time, a group needs two, an empty declaration is a
no-op - are the shared `CallGroup` model, applied here to the shadow records and in each
backend to its own: see [Shared call connection and group](call-connection.md).

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
single `globalReceiver` that receives `:callkeep_core` broadcasts, settles incoming registrations
and then notifies listeners. This processing does not depend on the bridge being attached.
A terminal event that rejects an unconfirmed registration is consumed by the core, so the
bridge does not send `performEndCall` in addition to the failed report result.
The registration deadline returns a final failure: Dart declines the server call without
adding an `ActiveCall`. Core therefore cancels the native registration and suppresses late
confirmation, answer and replay for that never-presented UUID.
`ForegroundService` does not register its own global `BroadcastReceiver` directly.

**Global events** (received via `ConnectionEventListener`):

| Event                        | Handler                                  | Main Action                                                                                                                                                                                                                          |
| ---------------------------- | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `IncomingConnectionReported` | `syncScreenWakelock()`                   | Synchronize the screen wakelock; core already promoted the call and completed the registration. No delegate notification                                                                                                             |
| `ReplayIncomingCall`         | `handleCSReplayIncomingCall()`           | Deliver the incoming call to a freshly attached delegate via `didPresentIncomingCall` (sole foreground delivery); once the delegate took it, `confirmHandoff` tells the incoming-call service the push session is done with the call |
| `ConnectionStateChanged`     | `handleCSReportConnectionStateChanged()` | `updateState()` -- mirror the authoritative connection state into the tracker                                                                                                                                                        |
| `AnswerCall`                 | `handleCSReportAnswerCall()`             | Core already tracked the answer; call `performAnswerCall()` on Dart delegate                                                                                                                                                         |
| `DeclineCall`                | `handleCSReportDeclineCall()`            | For confirmed calls: `markTerminated()`, call `performEndCall()`; on the lock screen sends the app back only if no other call is live                                                                                                |
| `HungUp`                     | `handleCSReportDeclineCall()`            | Same as DeclineCall                                                                                                                                                                                                                  |
| `ConnectionNotFound`         | `handleCSConnectionNotFound()`           | Synthesize HungUp — `performEndCall()`                                                                                                                                                                                               |
| `AudioMuting`                | Inline                                   | Call `performMuteCall()` on Dart delegate                                                                                                                                                                                            |
| `AudioDeviceSet`             | Inline                                   | Call `performSetAudioDevice()`                                                                                                                                                                                                       |
| `AudioDevicesUpdate`         | Inline                                   | Call `performUpdateAudioDevices()`                                                                                                                                                                                                   |
| `ConnectionHolding`          | Inline                                   | Call `performHoldCall()`                                                                                                                                                                                                             |
| `SentDTMF`                   | Inline                                   | Call `performSendDTMF()`                                                                                                                                                                                                             |

`IncomingFailure` is handled entirely by the core. The bridge does not inspect registration
waiters or change call state for this event. Incoming duplicate adoption also belongs to the
core: the bridge only sends the Flutter answer notification when `registerIncomingCall` returns
`CALL_ID_ALREADY_EXISTS_AND_ANSWERED`.

**Per-call dynamic receivers** (registered ad-hoc via `CallkeepCore.registerConnectionEvents()`):

| Event              | Handler                           | Main Action                         |
|--------------------|-----------------------------------|-------------------------------------|
| `OngoingCall`      | `handleCSReportOngoingCall()`     | Promote outgoing call, notify Dart  |
| `OutgoingFailure`  | `handleCSReportOutgoingFailure()` | `markTerminated()`, notify Dart     |
| `TearDownComplete` | Inline lambda                     | Completes the `tearDown()` deferred |

### Sending the app back after a call on the lock screen

When a confirmed call ends (`DeclineCall` / `HungUp`) while the device is locked
(`Platform.isLockScreen`) and no other call is live or pending (`isLastCall`), the bridge calls
`ActivityHolder.finish()`, which moves the task to the back (`moveTaskToBack(true)`). After
unlocking, the user sees what was under the app, not the app.

The rule does not know how the app came to be on screen. A call brings the activity up over the
lock screen (`showWhenLocked`), and the same rule sends it back afterwards - but it also sends back
an app the user had open before locking the device, so after unlocking that app is gone as well.
The behaviour is the same on every device (seen on Pixel 9, Galaxy M32, Galaxy XCover 5 and
Huawei MAO-LX9N) and in every signaling mode.

## Duplicate-Notification Guards

To prevent sending the same event to Dart twice (e.g., from both the direct tearDown path and a
stale broadcast), `MainProcessConnectionTracker` maintains guard sets used by the core and
foreground bridge before dispatching:

- `directNotifiedCallIds` -- core suppresses a terminal acknowledgement after a registration
  was rejected or failed, and after teardown already notified Flutter for a confirmed call.
- `endCallDispatchedCallIds` — suppress second `performEndCall()` for the same call.

## Related Components

- [callkeep-core.md](callkeep-core.md) — all Telecom commands go through here
- [connection-tracker.md](connection-tracker.md) -- shadow state shared through the core
- [pigeon-apis.md](pigeon-apis.md) — `PHostApi` and `PDelegateFlutterApi` definitions
- [callkeep-core.md](callkeep-core.md) — `ConnectionEventListener` API and event routing
- [ipc-broadcasting.md](ipc-broadcasting.md) — cross-process broadcast transport
