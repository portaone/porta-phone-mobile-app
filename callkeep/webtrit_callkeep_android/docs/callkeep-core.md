# CallkeepCore / InProcessCallkeepCore

**Files**:

- `kotlin/com/webtrit/callkeep/services/core/CallkeepCore.kt` (interface)
- `kotlin/com/webtrit/callkeep/services/core/InProcessCallkeepCore.kt` (implementation)
- `kotlin/com/webtrit/callkeep/services/core/CallServiceRouter.kt` (backend routing)

## Responsibility

`CallkeepCore` is the single facade used by the **main process** for all interactions with the
call backend. It combines four concerns:

1. **State queries and mutations** -- the shadow call state held in
   `MainProcessConnectionTracker` (see [connection-tracker.md](connection-tracker.md)).
2. **Command dispatch** -- commands routed through `CallServiceRouter` to either
   `PhoneConnectionService` (Telecom path, `:callkeep_core` process) or
   `StandaloneCallService` (no-Telecom path, main process). Call sites never know which backend
   is active.
3. **Event routing** -- receives `:callkeep_core` broadcasts via a single lazy internal receiver
   and fans them out to registered `ConnectionEventListener` subscribers; also supports direct
   in-process delivery (`notifyConnectionEvent`) for the standalone backend.
4. **Incoming registration** -- owns the complete operation from dispatch through backend
   confirmation, refusal or timeout, and tracks each waiting client. Entry points supply metadata and a client
   identity; they do not keep registration callbacks or interpret backend outcomes.

All main-process code that needs to know call state, trigger a call action, or subscribe to
connection events goes through `CallkeepCore.instance`.

## Access Pattern

```kotlin
val core = CallkeepCore.instance
core.startAnswerCall(metadata)
val meta = core.get(callId)
```

`InProcessCallkeepCore.instance` is a process-wide companion-object singleton, created eagerly on
first class access. The application context is read per call from `ContextHolder`, not at
construction time, so early singleton creation itself never throws. There is no `Application`
subclass: `ContextHolder.init` runs at each entry point (plugin attach, `WebtritCallkeep`,
service `onCreate`, receiver `onReceive`; the `:callkeep_core` services init their own copy), and
a CS command issued before any entry point has run throws `IllegalStateException` -- the
synchronous-throw case described under Incoming registration below. Swapping the `instance`
assignment is the single point to change IPC strategy without touching call sites.

Known consumers: `ForegroundService`, `ConnectionsApi`, `WebtritCallkeepPlugin` (lock-screen
flags on ON_START), `BackgroundPushNotificationIsolateBootstrapApi`, `ExternalEngineCallApi`,
`IncomingCallService` + its handlers/controller, `ActiveCallService`,
`IncomingCallSmsTriggerReceiver`, `StandaloneCallService` (event delivery), `CallDiagnostics`.

## State Query API

Backed by `MainProcessConnectionTracker`; exact semantics (derived termination, guard behavior,
invariants) are documented in [connection-tracker.md](connection-tracker.md).

| Method                       | Description                                                                                                             |
|------------------------------|-------------------------------------------------------------------------------------------------------------------------|
| `exists(callId)`             | Promoted, non-terminated connection record exists                                                                       |
| `isPending(callId)`          | Sent to Telecom, `PhoneConnection` not yet created                                                                      |
| `getPendingCallIds()`        | Non-destructive snapshot of pending ids                                                                                 |
| `isTerminated(callId)`       | Derived: seen before AND absent from all active sets                                                                    |
| `isAnswered(callId)`         | Answer guard was marked (not the same as STATE_ACTIVE)                                                                  |
| `checkIncomingDuplicate(id)` | null = free; `CALL_ID_ALREADY_EXISTS[_AND_ANSWERED]` otherwise                                                          |
| `routeAnswerCall(id)`        | `AnswerImmediately` / `DeferAnswer` / `NotFound` -- encodes the answer-path decision for `ForegroundService.answerCall` |
| `get(callId)` / `getAll()`   | `CallMetadata` snapshot(s) of active calls                                                                              |
| `getState(callId)`           | Last mirrored `PCallkeepConnectionState`                                                                                |
| `toPCallkeepConnection(id)`  | Pigeon connection object, null if not active                                                                            |

## State Mutation API

Incoming registration transitions are applied in the core before listeners receive backend
events. `ForegroundService.onConnectionEvent` still handles the other call and UI transitions:

| Method                                                         | Typical trigger                                                                                                                | Effect                                                                                                                              |
|----------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| `addPending(callId)`                                           | incoming dispatch inside `registerIncomingCall`; outgoing `startCall` pre-registration                                         | Registers pending; resets the four per-call guards first (the sticky ghost guard excepted); true = caller owns the entry            |
| `removePending(callId)`                                        | registration failure / timeout / decline-before-confirmation / failed outgoing / tearDown and `onDestroy` rollback             | Drops the pending entry only                                                                                                        |
| `promote(callId, meta, state)`                                 | `IncomingConnectionReported`; `OngoingCall`; adoption paths                                                                    | Full registration; same guard reset as `addPending` (also clears an earlier `markAnswered`)                                         |
| `markAnswered(callId)`                                         | `AnswerCall` broadcast; adoption paths (after `promote`); `CallLifecycleHandler` fallback when the push isolate is unreachable | Answer guard only; no state stamp                                                                                                   |
| `updateState(callId, state)`                                   | `ConnectionStateChanged` broadcast                                                                                             | Mirrors authoritative state; unconditional; ignores DISCONNECTED                                                                    |
| `markTerminated(callId)`                                       | `reportCallEnded`; HungUp/Decline handling                                                                                     | Clears active sets; state becomes DISCONNECTED                                                                                      |
| `clearAndMarkEndCallDispatched(id)`                            | HungUp/Decline/`ConnectionNotFound` handler, tearDown, `onDestroy`, confirmation timeout                                       | `markTerminated` + drops the main-process `ConnectionManager` pending reservation + marks endCallDispatched (true = first dispatch) |
| `reserveAnswer` / `consumeAnswer`                              | deferred-answer path / `AnswerCall` handler                                                                                    | Deferred answer bookkeeping                                                                                                         |
| `drainUnconnectedPendingCallIds()`                             | `tearDown`                                                                                                                     | Snapshot + clear of pending                                                                                                         |
| `clear()`                                                      | end of `tearDown`; `cleanConnections`                                                                                          | Full per-session reset                                                                                                              |
| `markDirectNotified` / `consumeDirectNotified`                 | `tearDown` / HungUp handler                                                                                                    | Stale-broadcast suppression                                                                                                         |
| `markEndCallDispatched(id)`                                    | `endCall`; `reportCallEnded`; the incoming-call service on `IC_RELEASE_ENDED`                                                  | performEndCall dedup; true = first mark                                                                                             |
| `markEndedWithoutFlutterState` / `wasEndedWithoutFlutterState` | `reportCallEnded(MISSED_WHILE_CONNECTING)` / `reportNewIncomingCall`                                                           | Sticky ghost-re-presentation guard                                                                                                  |

`clearAndMarkEndCallDispatched` is the one sanctioned main-process touch of
`ConnectionManager.instance`: it drops the `pendingCallIds` reservation that
`checkAndReservePending` created in the MAIN-process heap, so a transfer-back with the same
callId is not rejected as a duplicate. The general "never call the registry from the
main process" rule concerns connection state, which exists only in the `:callkeep_core` heap --
see the note in [connection-tracker.md](connection-tracker.md).

(`updateMetadata` is a `ConnectionTracker` member, not part of this facade -- external callers
reach it via `startUpdateCall`.)

## Connection Event Listener API

`InProcessCallkeepCore` holds a single lazy `BroadcastReceiver` (`globalReceiver`) registered on
the first listener or call-state operation. It remains registered when the last listener is
removed: pending registrations and live calls outlast the activity bridge. Events are processed
on the main thread, and core registration transitions run before listener delivery.

| Method                                 | Description                                                                                                             |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `addConnectionEventListener(l)`        | Register a persistent global subscriber                                                                                 |
| `removeConnectionEventListener(l)`     | Remove the subscriber; keep the core receiver alive                                                                     |
| `registerConnectionEvents(...)`        | Register a temporary per-call dynamic receiver                                                                          |
| `unregisterConnectionEvents(...)`      | Unregister a temporary receiver                                                                                         |
| `notifyConnectionEvent(event, data)`   | Process a backend event, then deliver it to listeners and per-call receivers without ActivityManager broadcast dispatch |

**Global events** (received by the core receiver):
`IncomingConnectionReported`, `IncomingFailure`, `ReplayIncomingCall`, `ConnectionStateChanged`, `DeclineCall`,
`HungUp`, `ConnectionNotFound`, `AnswerCall`, `AudioDeviceSet`, `AudioDevicesUpdate`,
`AudioMuting`, `ConnectionHolding`, `SentDTMF`.

**Per-call dynamic receivers** (registered ad-hoc, not via listener):
`OngoingCall`, `OutgoingFailure` (both in `ForegroundService.startCall`), `TearDownComplete`
(tearDown ack).

`IncomingFailure` is dispatched by `PhoneConnectionService`
(`onCreateIncomingConnectionFailed`). The core rejects the matching registration directly,
regardless of whether a foreground service is attached. Terminal events for a registration still
waiting on Telecom are also consumed here: the suspended report learns the refusal, and the
foreground bridge must not additionally send `performEndCall` for that unconfirmed call.
`IncomingConnectionReported` promotes the call and completes the registration before listeners
run; the foreground listener only updates the screen wakelock for this event.

`notifyConnectionEvent` exists for `StandaloneCallService`, which runs in the main process: on
certain OEM devices the system suppresses app-originated `sendBroadcast` calls entirely, so the
standalone backend delivers its lifecycle events as synchronous in-process calls into the same
handlers. Both backends therefore feed the same event pipeline and the same tracker mutations.

## Command Dispatch API

Commands go through `CallServiceRouter`, which picks the backend once at construction via
`TelephonyUtils.isTelecomSupported`. That asks the release before it asks the device: below
API 26 the answer is no whatever the hardware, because this plugin registers a **self-managed**
`PhoneAccount` and self-managed does not exist there - Telecom would accept the call and lose
it. From API 26 up, Telecom is considered supported when the `android.software.telecom` feature
flag is present, OR -- fallback for OEM builds that omit the flag despite having full Telecom --
when `TelephonyManager.phoneType != PHONE_TYPE_NONE`.

So `StandaloneCallService` (main process) takes devices with no telephony at all (Wi-Fi-only
tablets, Android Go builds) **and** every release below API 26; everything else uses
`PhoneConnectionService` (startService intents into `:callkeep_core`).

### Call Setup

| Method                    | Description                          |
|---------------------------|--------------------------------------|
| `startOutgoingCall(meta)` | Trigger outgoing connection creation |

An incoming call has no dispatch-only entry: every caller goes through `registerIncomingCall`
below. Inside it, the core's private dispatch owns the `pendingCallIds` reservation: it calls
`addPending` before handing the call to the backend and, on any failure -- logical error or a
synchronous throw -- drains the reservation exactly once before the waiting callers learn it.

### Incoming registration

The signaling and push Pigeon entry points and the SMS trigger receiver all call
`registerIncomingCall(metadata, client)`. The receiver keeps its broadcast alive with
`goAsync()` until the operation answers, which the registration deadline bounds. This suspend
operation waits for the backend's outcome or the registration deadline, rather than returning
dispatch acceptance. The core checks the never-presented-call guard, adopts an existing call
when appropriate, joins a registration already in progress or starts a new one. The first caller
dispatches once; callers joining the same call id wait for that operation and receive
`CALL_ID_ALREADY_EXISTS` when it succeeds. A refusal reaches every caller.

`IncomingRegistrations` stores the waiters and the deadline timer for each operation. Its
callbacks and settlement methods stay inside the core; callers cannot split dispatch from
waiting or settle a registration themselves. Backend broadcasts and direct standalone events
enter the same pipeline, independent of `CallEndListener` presence:

- `IncomingConnectionReported` promotes the call to ringing before returning success. A deferred
  `AnswerCall` can confirm registration directly as active; the same event still reaches the
  bridge for its Flutter answer notification. Confirmation cannot override a registration
  explicitly rejected or finalized by the core, or demote an answered call to ringing.
  The core remembers explicitly rejected registrations
  until a new attempt starts. This keeps a late ACTIVE state followed by `AnswerCall` from
  reviving a refused call, while still allowing cold replay of a live backend call whose
  metadata has not yet reached the main process.
- `IncomingFailure`, or `DeclineCall` / `HungUp` / `ConnectionNotFound` before confirmation,
  rejects it with `CALL_REJECTED_BY_SYSTEM`, removes pending state and marks it terminated.
  The core also suppresses a later terminal acknowledgement, so the bridge receives no
  additional end-call action for the rejected registration.
- The registration deadline is a final application cancellation. `CALL_REJECTED_BY_SYSTEM`
  makes `CallBloc` decline the server call and return without adding an `ActiveCall`, so the
  native side cannot later recover just its own half of that call. Before answering callers,
  the core marks the never-presented UUID ended and sends `cancelIncomingCall` to the backend.
  Both backends remember this cancellation, reject creation that arrives later, clear deferred
  answers and end an existing connection. A late confirmation, answer or replay is suppressed
  and retries cancellation; a late state event cannot repopulate the shadow. No timed-out
  metadata or waiters are retained. Re-reporting this UUID returns `CALL_ID_ALREADY_TERMINATED`.
  A different UUID starts a new operation normally. Unlike a call that was successfully
  presented, this already-declined UUID is not a transfer-back candidate.
- A synchronous dispatch exception cleans up the operation immediately and propagates the
  original exception to its waiting callers, with the same terminal-event suppression.
  A late dispatch callback is tied to its operation
  identity and cannot complete a newer attempt with the same call id.
- Coroutine cancellation removes that waiter only. The backend operation continues through
  confirmation or timeout, so cancellation does not hang up a call or strand another client.
- A backend duplicate whose mirrored state is already active is adopted as active and answered.
  The foreground entry point translates `CALL_ID_ALREADY_EXISTS_AND_ANSWERED` into its Flutter
  answer notification; it does not mutate the registration or tracker itself.

#### Registration deadline

The deadline is five seconds in a release build and ten in a debuggable one
(`ApplicationInfo.FLAG_DEBUGGABLE`, read when each registration starts). It is a safety net for a
backend that never answers; every measured registration ended with a real Telecom answer long
before it. What decides the time is not Telecom but the main thread: on a cold start the backend's
answer waits in the main looper behind Flutter starting up, and the deadline timer runs on that
same looper. A debug build starts Flutter several times slower, hence its longer deadline.

Measured on the local stand, debug build unless marked (time from dispatch to the backend's
answer, median / maximum; refusal = the second call Telecom refuses while the first rings):

| Device                                   | App state               | Confirmed       | Refused         |
|------------------------------------------|-------------------------|-----------------|-----------------|
| Pixel 9, Android 17                      | foreground / background | 91 / 141 ms     | 24 / 217 ms     |
| Pixel 9, Android 17                      | cold start (push)       | 692 / 727 ms    | 1409 / 1743 ms  |
| Galaxy M32, Android 13                   | foreground / background | 91 / 100 ms     | 84 / 188 ms     |
| Galaxy M32, Android 13                   | cold start (push)       | 954 / 2442 ms   | 1509 / 3046 ms  |
| Huawei MAO-LX9N, Android 12              | foreground / background | 77 / 152 ms     | 83 / 140 ms     |
| Galaxy XCover 5, Android 14              | foreground / background | 375 / 434 ms    | 258 / 1004 ms   |
| Galaxy XCover 5, Android 14              | cold start (push)       | 1416 / 14829 ms | 4999 / 12748 ms |
| Galaxy XCover 5, Android 14, **release** | cold start (push)       | 384 / 445 ms    | 634 / 929 ms    |

The XCover's 14.8 s debug confirmation is the main thread blocked for about ten seconds on a cold
start; the timer was blocked with it, so the answer still came first. In release the slowest
device answers within a second, leaving more than four seconds of the five.

The public lifecycle methods describe why an operation ends:

| Method | Effect |
| -------- | -------- |
| `registerIncomingCall(metadata, client)` | Own dispatch and await its result; join or adopt an existing call when appropriate |
| `appEndingCall(callId)` | Complete a waiting registration successfully before the app's explicit hang-up |
| `detachIncomingClient(client)` | Reject that client's waiting host calls; preserve shared registrations for other clients, reject registrations with no clients left |
| `endIncomingRegistrations()` | Finalize pending registrations for session teardown, including independent push operations |

`onDestroy` detaches the activity bridge. A push operation remains alive if the push is its
remaining client, even when the foreground report started the operation. `tearDown` ends the
session instead: all registrations finish and all timers are cancelled before the tracker is
reset. Ordinary refusal releases its pending reservation, so a later valid report can retry
rather than being mistaken for a ringing call. A timeout is different: the app has declined
that unpresented UUID, and backend cancellation remains final even across session cleanup.

Cancellation is a native service command, not an acknowledgement that Telecom has already
disconnected. If Android refuses that command, the failure is logged and a later lifecycle
event retries it. Tests cover both command ordering and backend cancellation; device scenarios
that never force a deadline do not establish cancellation delivery under OS restrictions.

### In-Call Control

`startAnswerCall`, `startDeclineCall`, `startHungUpCall`, `startEstablishCall`,
`startUpdateCall` (also merges metadata into the tracker), `startSendDtmfCall`,
`startMutingCall`, `startHoldingCall`, `startSpeaker`, `setAudioDevice` -- all take
`CallMetadata` and are routed to the active backend.

### Call Grouping

`startSetCallGroup(groupId, callIds)` and `startUnsetCallGroup(callIds)` are the exception to
the paragraph above, twice over. They take a list of call ids rather than `CallMetadata`,
because the membership of a group is not a property of any one call; and they answer with a
`CallGroupOutcome` rather than nothing: `ACCEPTED`, `NOT_SUPPORTED` when no backend took the
request, `LIMIT_REACHED` when another group is live under another name (every backend holds
one group at a time). `ForegroundService` turns that into the pigeon answer. The core is also
where the declared membership is kept: on `ACCEPTED` it records the group on each call in
`MainProcessConnectionTracker`, `startUnsetCallGroup` releases the calls, `markTerminated`
takes an ended call out and dissolves a group left with one member, and `clear()` empties it
with the session. `isGrouped(callId)` and `groupMembersWith(callId)` read it. The core keeps
its global receiver registered from the first call it learns about, not only while a listener
is attached. Incoming registration events are always handled by the core. For calls whose
registration has already finished, while no `CallEndListener` is attached it marks a call terminated itself on
`HungUp`, `DeclineCall` and `ConnectionNotFound`: a member that ends while the activity's bridge
is away still leaves its group, and the next bridge finds the record as the calls left it. The
foreground service is the one `CallEndListener`: while it is attached it handles the end of
confirmed calls with its full Flutter context. A listener that only observes - the
incoming-call service handles `AnswerCall` and nothing else - does not count, so its presence
while the bridge is away changes nothing. Both backends
take the request today, and both keep the membership themselves; the Telecom backend does not
declare it to Telecom (see [phone-connection-service.md](phone-connection-service.md)).
Grouping only changes how the OS presents calls that run either way, so a refusal is never a
reason to end one.

### Service Lifecycle

| Method                      | Description                                                                                                                                                                                                                                                                                                                                                                                                                                            |
|-----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `tearDownService()`         | Reset backend service state for the next session without hanging up (Telecom: `ServiceAction.TearDown`; standalone: `CleanConnections`)                                                                                                                                                                                                                                                                                                                |
| `sendTearDownConnections()` | Hang up all connections + await `TearDownComplete` ack                                                                                                                                                                                                                                                                                                                                                                                                 |
| `sendReserveAnswer(callId)` | Deferred answer applied when the connection is created                                                                                                                                                                                                                                                                                                                                                                                                 |
| `sendCleanConnections()`    | Clear backend connections without individual hangups (`ServiceAction.CleanConnections` on both backends)                                                                                                                                                                                                                                                                                                                                               |
| `replayAudioState()`        | One-way pull: re-emit audio state (device + mute) to a fresh delegate                                                                                                                                                                                                                                                                                                                                                                                  |
| `replayConnectionStates()`  | One-way pull seeding a freshly attached delegate / restarted main process (cold-start race). For every live connection re-emits `ConnectionStateChanged` (live states only; restores e.g. STATE_ACTIVE for the already-answered adoption), then `AnswerCall` (callId-only metadata) for answered connections, or `ReplayIncomingCall` (full metadata) for still-ringing ones -- the ONLY path by which a fresh delegate learns of a still-ringing call |

### Reporting a call ended

`reportCallEnded(metadata, reason)` is the app telling the core that a call is over: the remote
party hung up, nobody answered, or the app never got to present it
(`MISSED_WHILE_CONNECTING`). It is one fact whoever reports it - the foreground bridge
(`PHostApi.reportEndCall`), the push session (`PHostBackgroundPushNotificationIsolateApi.reportEndCall`)
or a hosted engine (`ExternalEngineCallApi`) - and the core does the same four things at once:

1. marks the call terminated ahead of the backend's echo, which also rejects a registration
   still waiting on it;
2. for a never-presented end, arms the ghost guard, so a replay, a late confirmation or a late
   push of the same call is refused and the backend is asked to cancel it;
3. marks the end dispatched, so no engine is asked to end the call again: the incoming-call
   service, on the `IC_RELEASE_ENDED` that follows, hands the call off to its session
   (`performHandoff`) instead of asking it to end the call - the push session would otherwise
   send the server a decline for a call the server hung up;
4. leaves a pending release (`PendingBroadcastQueue`) when no incoming-call service is running,
   so one started for this call afterwards ends it without showing it; a running service takes
   the `IC_RELEASE_ENDED` through its receiver instead;
5. ends the call in the backend (`startDeclineCall`).

It ends the call, not the session that reported it: the incoming-call service keeps running for
whatever that session still has to do. A presented call keeps its id free for a
transfer-back.

## Related Components

- [connection-tracker.md](connection-tracker.md) -- state storage backend and its invariants
- [foreground-service.md](foreground-service.md) -- Flutter bridge and listener for confirmed-call events
- [background-services.md](background-services.md) -- `IncomingCallService` also implements `ConnectionEventListener` (AnswerCall only)
- [phone-connection-service.md](phone-connection-service.md) -- Telecom backend receiving commands
- [ipc-broadcasting.md](ipc-broadcasting.md) -- broadcast events routed through `globalReceiver`
- [dual-process.md](dual-process.md) -- process topology
