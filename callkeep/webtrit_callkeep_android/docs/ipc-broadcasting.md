# IPC Broadcasting

**File**: `kotlin/com/webtrit/callkeep/services/broadcaster/ConnectionServicePerformBroadcaster.kt`

## Overview

`ConnectionServicePerformBroadcaster` is the **cross-process event bus** between `:callkeep_core`
and the main process. It uses **app-scoped local broadcasts** (the intent's package is set to the
app package name) so no third-party app can receive or inject events.

The intent **action is the event name** — `ConnectionEvent.name`, e.g. `HungUp`,
`ConnectionStateChanged`. There is no shared action and no event-type extra: a receiver
subscribes by adding an action per event it cares about, so it is filtered by the system
rather than in application code.

That has a consequence worth knowing before adding an event: a receiver only gets the
actions its filter names. The main process builds its filter from
`InProcessCallkeepCore.GLOBAL_LISTENER_EVENTS`, and `globalReceiver` also matches the
incoming action against that same list, so a new `ConnectionEvent` missing from it crosses
the process boundary and is dropped with no error.

This applies to the Telecom backend only. The standalone backend never leaves the main
process: `InProcessCallkeepCore.notifyConnectionEvent` hands the event to every listener
directly, with no allowlist, and only the per-call dynamic receivers filter by action. The
same new event therefore arrives there and vanishes on Telecom devices - test both.

## Event Catalogue

### Call Lifecycle Events (`:callkeep_core` -> main)

| Event                        | Payload                                                     | Meaning                                                                                                                                                                                                |
|------------------------------|-------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `IncomingConnectionReported` | `callId`, `CallMetadata` bundle                             | Incoming `PhoneConnection` created -> register in the shadow state (register-only; the delegate is notified via signaling or `ReplayIncomingCall`)                                                     |
| `ReplayIncomingCall`         | `callId`, `CallMetadata` bundle                             | Re-deliver a still-ringing incoming call to a freshly attached delegate (sole foreground delivery; from the connection-state replay on delegate attach)                                                |
| `AnswerCall`                 | `callId`                                                    | Answer signal (guard); the ACTIVE state arrives separately via `ConnectionStateChanged`                                                                                                                |
| `ConnectionStateChanged`     | `callId`, `CallMetadata` bundle (carries `connectionState`) | Authoritative live connection state to mirror into the shadow state (RINGING/DIALING/ACTIVE/HOLDING). Terminal DISCONNECTED is NOT sent here -- it stays on the cause-carrying `HungUp`/`DeclineCall`. |
| `DeclineCall`                | `callId`                                                    | User rejected the call                                                                                                                                                                                 |
| `HungUp`                     | `callId`, disconnect cause                                  | Call disconnected from either side                                                                                                                                                                     |
| `OngoingCall`                | `callId`, `CallMetadata` bundle                             | Outgoing connection dialing                                                                                                                                                                            |
| `OutgoingFailure`            | `callId`, failure info                                      | Outgoing call could not be created                                                                                                                                                                     |
| `IncomingFailure`            | `callId`, failure info                                      | Telecom refused to register the incoming call. Carries the refusal only: whether anything is waiting on that call is main-process state, so `ForegroundService` decides what it means                  |
| `ConnectionNotFound`         | `callId`                                                    | `PhoneConnection` not found — synthesized HungUp                                                                                                                                                       |

### Call Media Events (`:callkeep_core` -> main)

| Event                | Payload                       | Meaning                             |
|----------------------|-------------------------------|-------------------------------------|
| `AudioMuting`        | `callId`, `muted: Boolean`    | Mute state changed                  |
| `AudioDeviceSet`     | `callId`, `AudioDevice`       | Active audio device changed         |
| `AudioDevicesUpdate` | `callId`, `List<AudioDevice>` | Available audio device list changed |
| `SentDTMF`           | `callId`, digit               | DTMF tone dispatched                |
| `ConnectionHolding`  | `callId`, `onHold: Boolean`   | Hold state changed                  |

### Service Command Ack Events (`:callkeep_core` -> main)

| Event              | Payload | Meaning                                        |
|--------------------|---------|------------------------------------------------|
| `TearDownComplete` | —       | All connections torn down; tearDown can finish |

## Broadcast Transport

Sender — `Context.sendInternalBroadcast` in `common/Extensions.kt`, called from
`ConnectionServicePerformBroadcaster` with the event name as the action:

```kotlin
Intent(action)
    .apply {
        setPackage(packageName)
        addFlags(Intent.FLAG_RECEIVER_FOREGROUND)
        extras?.let { putExtras(it) }
    }.also { sendBroadcast(it, permission) }
```

Receiver — one filter carrying every event the listener wants:

```kotlin
private fun createIntentFilter(events: List<ConnectionEvent>): IntentFilter =
    IntentFilter().apply { events.forEach { addAction(it.name) } }
```

`registerReceiverCompat` is a helper that calls `registerReceiver(receiver, filter,
RECEIVER_NOT_EXPORTED)` on API 33+ and the equivalent on older versions.

## Sender Locations

| Event                             | Sender                                                                     |
|-----------------------------------|----------------------------------------------------------------------------|
| All call lifecycle / media events | `PhoneConnection` (via `performEventHandle()` in `PhoneConnectionService`) |
| `TearDownComplete`                | `PhoneConnectionService.onStartCommand` after tear-down                    |
| `TearDownConnections` (command)   | `ForegroundService` via `CallkeepCore.sendTearDownConnections()`           |

## Receiver Locations

| Receiver                                              | Listens For                                                                            |
|-------------------------------------------------------|----------------------------------------------------------------------------------------|
| `InProcessCallkeepCore.globalReceiver`                | All global call lifecycle and media events; fans out to `ConnectionEventListener` subs |
| `ForegroundService` (via `ConnectionEventListener`)   | Global events routed by `CallkeepCore`                                                 |
| `IncomingCallService` (via `ConnectionEventListener`) | Global events routed by `CallkeepCore`                                                 |
| Per-call dynamic receivers in `ForegroundService`     | `OngoingCall` and `OutgoingFailure` while a call is being placed; `TearDownComplete`   |
| `PhoneConnectionService`                              | nothing - it registers no receiver; everything towards it arrives as an intent         |

`InProcessCallkeepCore` maintains a single `globalReceiver` registered via
`ConnectionServicePerformBroadcaster`. Individual services no longer register their own receivers
for `:callkeep_core` events — they subscribe through `CallkeepCore.addConnectionEventListener()`.

Two asymmetries the table cannot show. Traffic towards `:callkeep_core` is not broadcast at
all: every `ServiceAction` arrives as a `startService` intent handled in
`PhoneConnectionService.onStartCommand`, which is why that service registers no receiver.
`IncomingFailure` was in exactly that position until 2026-09-23: dispatched by
`PhoneConnectionService`, outside `GLOBAL_LISTENER_EVENTS`, and named by no dynamic receiver
either, so a refused incoming call was resolved by the main process timing out five seconds
later rather than by the event. It is a global listener event now.

## Related Components

- [phone-connection.md](phone-connection.md) — dispatches lifecycle/media events
- [phone-connection-service.md](phone-connection-service.md) — dispatches `TearDownComplete`
- [callkeep-core.md](callkeep-core.md) — routes events to `ConnectionEventListener` subscribers
- [foreground-service.md](foreground-service.md) — implements `ConnectionEventListener`
- [dual-process.md](dual-process.md) — overall IPC design
