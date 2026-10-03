# Call Flows

End-to-end walkthroughs of the three main call scenarios.

---

## Incoming Call (Push Notification Path)

Triggered by an FCM message or a direct Dart call to `reportNewIncomingCall`.

```text
1.  FCM / Dart
        |
        v
2.  BackgroundPushNotificationIsolateBootstrapApi.reportNewIncomingCall(callId, meta)
        |   CallkeepCore.registerIncomingCall(meta, client)
        |   The signaling entry point uses the same core operation.
        v
3.  Core checks guards, adopts or joins an existing call, or starts registration
        |   One operation per call id, with a deadline (5 s release, 10 s debug)
        |   Dispatch acceptance does not finish the suspended host call
        v
4.  CallServiceRouter --> TelephonyUtils.addNewIncomingCall() --> Android Telecom
        |
        v
5.  Telecom --> PhoneConnectionService.onCreateIncomingConnection()
        |   PhoneConnection created (STATE_RINGING)
        |   broadcast: IncomingConnectionReported
        v
6.  CallkeepCore receives the event, with or without ForegroundService attached
        |   Promote the call to ringing, cancel the timer, complete all waiters
        |   ForegroundService, if attached, synchronizes its screen wakelock
        v
7.  Delegate notification (NOT from the event above):
        |   - call arrived while app running -> Flutter signaling __onCallSignalingEventIncoming
        |   - call only the push reported, app delegate ready ->
        |     IncomingCallHandler gives it to the app: ReplayIncomingCall (present-only) ->
        |     didPresentIncomingCall, no handoff release, the service keeps ringing
        |   - push->foreground handoff -> ReplayIncomingCall on delegate attach
        |     -> PDelegateFlutterApi.didPresentIncomingCall(callId, meta)
```

**Answer path (user taps answer in notification or UI):**

```text
8.  Dart calls PHostApi.answerCall(callId)
        |
        v
9.  ForegroundService.answerCall()
        |   If PhoneConnection exists: CallkeepCore.startAnswerCall(callId)
        |   If not yet: ConnectionManager.reserveAnswer(callId)  (deferred)
        v
10. PhoneConnectionService.onStartCommand(AnswerCall)
        |   PhoneConnection.onAnswer() -> setActive() -> STATE_ACTIVE
        |   broadcast: ConnectionStateChanged (connectionState = ACTIVE)
        |   broadcast: AnswerCall
        v
11. ForegroundService receives the broadcasts
        |   ConnectionStateChanged -> updateState(callId, ACTIVE)  (mirror)
        |   AnswerCall -> markAnswered(callId)  (guard)
        |   PDelegateFlutterApi.performAnswerCall(callId)
        v
12. Dart delegate receives performAnswerCall()
```

**Deferred answer (user answered before PhoneConnection was created):**

At step 9, `reserveAnswer` stores the intent. At step 5 (`onCreateIncomingConnection`),
`ConnectionManager.consumeAnswer(callId)` returns true and `PhoneConnection.onAnswer()` is posted
to the main handler, continuing from step 10 above. This path emits `AnswerCall` without an
`IncomingConnectionReported`; the core treats that answer as registration confirmation and
promotes the call as active before notifying the foreground bridge.

---

## Second Incoming Call While One Rings (waiting call)

Telecom lets one self-managed incoming call ring at a time. The core holds the second one back
(`incomingCallWhileRinging: queue`, the default; with `reject` the flow is the next section's).

```text
1.  B is reported (signaling, push or SMS) while A rings or is being registered
        |   CallkeepCore.registerIncomingCall(B) -> no error, but no dispatch
        |   IncomingCallQueue keeps B; QueuedCallNotifications posts its silent notification
        |   The app holds B as an ordinary incoming call; the caller of B hears ringback
        v
2a. A ends (DeclineCall / HungUp / ConnectionNotFound)
        |   after the listeners: nothing rings -> the oldest waiting call is registered
        |   B rings like any incoming call; a B the app reported is the app's already, a B only
        |   a push reported is presented (didPresentIncomingCall) or handled by a push session
2b. A is answered (AnswerCall)
        |   B is registered at once beside the active A: call waiting, waiting tone
2c. The user answers B (notification action or the app's answer of B)
        |   answerQueuedCall(B): A is declined, B goes through first and is answered once it rings
2d. B's caller hangs up while B waits
        |   reportCallEnded(B) -> B leaves the queue; nothing reaches Telecom, A is untouched
2e. The app ends B while it waits (endCall)
        |   B leaves the queue; performEndCall(B) at once, so the app declines it on the server
```

`callRejectedBySystem` below still happens when the core does not see the ringing call - another
app's call, say - and when a vendor refuses B beside an active A (B then waits for the end of
every call, see [callkeep-core.md](callkeep-core.md)).

## Incoming Call Rejected by Telecom (`callRejectedBySystem`)

Android does not allow two self-managed calls to be simultaneously in RINGING state. When a
second incoming call arrives while the first is still ringing, Telecom calls
`onCreateIncomingConnectionFailed` — **without** calling `onCreateIncomingConnection` first.

```text
1.  Dart / Push isolate calls reportNewIncomingCall(id2, meta)
        |  (call id1 is already in RINGING state)
        v
2.  CallkeepCore.registerIncomingCall() dispatches through TelephonyUtils --> Android Telecom
        |
        v
3.  Telecom --> PhoneConnectionService.onCreateIncomingConnectionFailed(callId=id2)
        |   broadcast: IncomingFailure(id2)  — the refusal, and nothing decided about it:
        |   whether anything is waiting on this call is main-process state, and this
        |   service runs in :callkeep_core with its own ConnectionManager instance
        v
4.  CallkeepCore processes IncomingFailure, whether or not the bridge is attached
        |   Remove the registration and its timer, drain pending state, mark it ended
        |   Resume all waiting push/signaling reports with callRejectedBySystem
        |   ForegroundService does not decide or mutate the registration outcome
        |   (performEndCall is not fired for the unconfirmed call)
        v
5.  Dart receives reportNewIncomingCall() result = callRejectedBySystem
```

> Until 2026-09-23 step 3 read `isPending(id2) == true (was registered in step 2)`,
> and step 2 registers it in the *reporting* process. The read always answered false,
> no event was sent that anyone received, and the call was resolved by the five-second
> confirmation timeout instead — measured on the stand at 4.98 s late.

**Key consequences**:

- `performEndCall` does **not** fire for `id2` — the call never existed in Telecom.
- The app must send the appropriate signaling (e.g. SIP BYE) to the server itself,
  without waiting for `performEndCall`.

**Scope**: this is standard AOSP behavior on Android 11+ (confirmed on stock Pixel 5).
Some vendors (Huawei, certain MediaTek OEMs) apply the same restriction even when the
first call is ACTIVE rather than RINGING.

---

## Outgoing Call

Triggered when the user initiates a call from the app UI.

> The address passed to Telecom (step 3) is a decoy `sip:` Uri built by
> `OutgoingCallUri` - digits are masked to letters so that OEM Telecom forks which
> run an emergency-number check on the placeCall Uri find no number to match and do
> not divert emergency-colliding extensions (e.g. "112") to the system dialer. The
> real dialled number travels in the call metadata, never in this Uri.

```text
1.  Dart calls PHostApi.startCall(callId, meta)
        |
        v
2.  ForegroundService.startCall()
        |   CallkeepCore.startOutgoingCall(callId, meta)
        v
3.  startService intent --> PhoneConnectionService.onStartCommand()
        |   TelephonyUtils.addOutgoingCall()  -->  Android Telecom
        v
4.  Telecom --> PhoneConnectionService.onCreateOutgoingConnection()
        |   PhoneConnection created (STATE_DIALING)
        |   broadcast: OngoingCall
        v
5.  ForegroundService receives OngoingCall broadcast
        |   CallkeepCore.promote(callId, meta, STATE_DIALING)
        |   PDelegateFlutterApi.performConnecting(callId)
        v
6.  Dart delegate receives performConnecting()

--- Remote side answers ---

7.  App / signaling calls PHostApi.reportConnectedOutgoingCall(callId)
        |
        v
8.  ForegroundService.reportConnectedOutgoingCall()
        |   CallkeepCore.startEstablishCall(callId)
        v
9.  PhoneConnectionService: PhoneConnection.setActive() -> STATE_ACTIVE
        |   broadcast: ConnectionStateChanged (connectionState = ACTIVE)
        |   broadcast: AnswerCall
        v
10. ForegroundService receives the broadcasts
        |   ConnectionStateChanged -> updateState(callId, ACTIVE)  (mirror)
        |   AnswerCall -> markAnswered(callId)  (guard)
        |   PDelegateFlutterApi.performConnected(callId)
        v
11. Dart delegate receives performConnected()
```

---

## TearDown (All Calls Ended)

Triggered by Dart calling `tearDown()` — used on logout or app reset.

```text
1.  Dart calls PHostApi.tearDown()
        |
        v
2.  ForegroundService.tearDown()
        |   CallkeepCore.endIncomingRegistrations():
        |     Reject every waiting push/signaling report and cancel its timer
        |     Suppress later terminal events for those unconfirmed calls
        |   For each confirmed non-terminated call in MainProcessConnectionTracker:
        |     directNotifiedCallIds += callId
        |     PDelegateFlutterApi.performEndCall(callId, reason=LOCAL_HANGUP)
        |
        |   CallkeepCore.sendTearDownConnections()
        v
3.  startService intent (TearDownConnections) --> PhoneConnectionService
        |   For each PhoneConnection: hungUp()
        |     -> PhoneConnection.onDisconnect()
        |        broadcast: HungUp (but suppressed by directNotifiedCallIds)
        |
        |   For each pending callId with no PhoneConnection:
        |     broadcast: HungUp (synthesized)
        |
        |   broadcast: TearDownComplete
        v
4.  ForegroundService receives TearDownComplete
        |   Clean up tracker, stop services
        |   Complete Dart tearDown() response
        v
5.  Dart receives tearDown() success result
```

`onDestroy()` has a different scope: it calls `detachIncomingClient(this)`, so an in-flight
push registration survives the activity bridge being destroyed. Session teardown rejects all
clients before clearing state; the next session cannot join a registration or timer from the old one.

**Duplicate notification prevention**: `directNotifiedCallIds` ensures that when
`ForegroundService` receives the `HungUp` broadcast in step 3, it does not call
`performEndCall()` again for calls already notified in step 2.

---

## Hot-Restart Recovery

When Flutter hot-restarts (development only) the main process Flutter engine is re-attached, but
`:callkeep_core` retains live `PhoneConnection` objects.

```text
1.  Flutter hot-restart
        |
        v
2.  WebtritCallkeepPlugin.onAttachedToEngine()
        |
        v
3.  ForegroundService.replayConnectionStates()
        |   CallkeepCore.replayAudioState()    -> PhoneConnectionService re-emits audio state
        |   CallkeepCore.replayConnectionStates() -> PhoneConnectionService re-fires AnswerCall
        v
4.  ForegroundService broadcast handlers receive re-emitted events
        |   MainProcessConnectionTracker updated
        |   PDelegateFlutterApi notified with current state
        v
5.  Flutter UI reflects existing call state
```

---

## Related Components

- [foreground-service.md](foreground-service.md) — processes broadcast events in all flows
- [phone-connection-service.md](phone-connection-service.md) — Telecom integration in
  `:callkeep_core`
- [phone-connection.md](phone-connection.md) — per-call state transitions
- [callkeep-core.md](callkeep-core.md) — command dispatch from main process
- [ipc-broadcasting.md](ipc-broadcasting.md) — event transport between processes
