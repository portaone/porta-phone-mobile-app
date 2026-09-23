# ConnectionManager

**File**: `kotlin/com/webtrit/callkeep/services/services/connection/ConnectionManager.kt`

**Process**: `:callkeep_core`

## Responsibility

`ConnectionManager` is the **call registry** inside the `:callkeep_core` process. It holds all
live `PhoneConnection` objects and tracks ancillary state — pending calls, deferred answers, and
force-terminated calls.

It is the authoritative source of call state for the `:callkeep_core` process. The main process
has a corresponding shadow registry, `MainProcessConnectionTracker`.

## State

| Field                     | Description                                                                                                 |
|---------------------------|-------------------------------------------------------------------------------------------------------------|
| `connections`             | `ConcurrentHashMap<String, PhoneConnection>` — all `PhoneConnection` objects by callId                      |
| `pendingCallIds`          | Calls for which `addPendingForIncomingCall()` was called but `onCreateIncomingConnection` has not yet fired |
| `pendingAnswers`          | Calls where `answerCall` arrived before `onCreateIncomingConnection`                                        |
| `terminatedCallIds`       | Calls marked terminated by `markTerminated()`                                                               |
| `forcedTerminatedCallIds` | Pending callIds snapshotted by `cleanConnections()`; stale Telecom callbacks for these are suppressed       |

No metadata is held here. The manager stores callIds and connections; `CallMetadata`
travels with the intents and the connection itself.

## Key Methods

### Pending Call Registration

```kotlin
fun addPendingForIncomingCall(callId: String): Boolean
fun removePending(callId: String)
```

Both run inside `:callkeep_core`, where `PhoneConnectionService.onCreateIncomingConnection`
is the only thing that registers a slot: the call is reported straight to Telecom from the
other process, so nothing arrives here ahead of Telecom's own callback.
`addPendingForIncomingCall` returns `false` when `cleanConnections()` has already captured
this callId as force-terminated, i.e. the call is a zombie and must not be re-registered -
which is what the caller refuses the connection on.

```kotlin
fun checkAndReservePending(callId: String): PIncomingCallErrorEnum?
```

Atomic check and claim: `null` means the slot was taken and the call may proceed; a
non-null value is the reason it may not. Used where Telecom and the main process race over
the same callId.

### Connection Lifecycle

```kotlin
internal fun addConnection(callId: String, connection: PhoneConnection)
fun getConnection(callId: String): PhoneConnection?
fun getConnections(): List<PhoneConnection>
fun isConnectionAlreadyExists(callId: String): Boolean
fun isConnectionDisconnected(callId: String): Boolean
fun isConnectionAnswered(id: String): Boolean
fun hasVideoConnections(): Boolean
```

There is no `removeConnection`. An entry leaves the map in two ways: `cleanConnections()`
clears the whole set, and `checkAndReservePending` drops a single stale
`STATE_DISCONNECTED` entry so the same callId can be reused, as a transfer-back does. An
ordinary call that just ended therefore stays in the map as `STATE_DISCONNECTED`.
`markTerminated` is narrower than its name suggests: it is called only when a command
arrives for a connection that no longer exists, so `terminatedCallIds` records
connection-not-found cases rather than every finished call.

### State Queries

```kotlin
fun isPending(callId: String): Boolean
fun isForcedTerminated(callId: String): Boolean
fun drainUnconnectedPendingCallIds(): Set<String>
fun getActiveConnection(): PhoneConnection?
fun isExistsIncomingConnection(): Boolean
fun hasActiveOrHoldingConnection(): Boolean
```

`getActiveConnection()` returns the first connection in `STATE_ACTIVE`, and
`hasActiveOrHoldingConnection()` is a plain boolean: both assume one call is live at a
time, which is what the incoming-call ringtone choice and the outgoing-call path rely on.

`drainUnconnectedPendingCallIds()` returns pending callIds that have no corresponding
`PhoneConnection` yet. Used during `TearDownConnections` to generate synthetic `HungUp` events
for calls Telecom never confirmed.

### Deferred Answer

```kotlin
fun reserveAnswer(callId: String)
fun consumeAnswer(callId: String): Boolean
fun addConnectionAndConsumeAnswer(callId: String, connection: PhoneConnection): Boolean
fun reserveOrGetConnectionToAnswer(callId: String): PhoneConnection?
```

`reserveAnswer` is called when the main process sends `ReserveAnswer` (user pressed answer before
the `PhoneConnection` existed). `consumeAnswer` is checked in `onCreateIncomingConnection` — if
true, the newly created connection is answered immediately.

### TearDown

```kotlin
fun markTerminated(callId: String)
fun cleanConnections()
```

`markTerminated` records a callId in `terminatedCallIds`. `cleanConnections` destroys every
connection and clears the registry, snapshotting the still-pending callIds into
`forcedTerminatedCallIds` first — Telecom may still deliver `onCreateIncomingConnection` for
those afterwards, and `isForcedTerminated()` is what rejects them as zombies.

## Synchronization

`checkAndReservePending()` uses `synchronized(connectionResourceLock)` to ensure atomicity when
multiple Telecom callbacks or IPC commands arrive concurrently for the same callId.

## Related Components

- [phone-connection-service.md](phone-connection-service.md) — creates this and calls its methods
- [phone-connection.md](phone-connection.md) — objects stored here
- [connection-tracker.md](connection-tracker.md) — the main-process mirror of this registry
