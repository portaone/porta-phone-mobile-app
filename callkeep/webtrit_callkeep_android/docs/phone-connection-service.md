# PhoneConnectionService

**File**: `kotlin/com/webtrit/callkeep/services/services/connection/PhoneConnectionService.kt`

**Extends**: Android `ConnectionService`

**Process**: `:callkeep_core` (declared in `AndroidManifest.xml`)

**Annotation**: `@Keep`

## Responsibility

`PhoneConnectionService` is the Android Telecom `ConnectionService` implementation. It runs in the
`:callkeep_core` OS process and is the only component that interacts with Android Telecom directly.

Its responsibilities:

- Creates and destroys `PhoneConnection` objects on behalf of the Telecom framework.
- Handles per-call lifecycle actions (answer, decline, hang up, establish, update, mute, hold,
  etc.).
- Dispatches call lifecycle and media events to the main process via local broadcasts.
- Receives commands from the main process via explicit `startService` intents.

## AndroidManifest Declaration

```xml

<service android:name=".services.connection.PhoneConnectionService" android:process=":callkeep_core"
    android:exported="false"
    android:permission="android.permission.BIND_TELECOM_CONNECTION_SERVICE">
    <intent-filter>
        <action android:name="android.telecom.ConnectionService" />
    </intent-filter>
</service>
```

## Lifecycle Callbacks (Telecom-driven)

### `onCreate()`

- Initializes `ConnectionManager`, `PhoneConnectionServiceDispatcher`, `TelephonyUtils`.
- Registers a broadcast receiver for `NotifyPending` intents (main process pre-registers calls
  before Telecom delivers `onCreateIncomingConnection`).
- Initializes `ActivityWakelockManager` and `ProximitySensorManager`.

### `onCreateIncomingConnection(phoneAccountHandle, request)`

- Creates a `PhoneConnection` for the incoming call.
- Looks up metadata from `ConnectionManager.getPendingMetadata(callId)`.
- If metadata is not yet available (race condition), falls back to extracting from the `request`
  Bundle.
- Calls `performEventHandle(IncomingConnectionReported, ...)` to notify the main process.
- If `ConnectionManager.consumeAnswer(callId)` returns true (deferred answer), calls
  `connection.onAnswer()` immediately.

### `onCreateOutgoingConnection(phoneAccountHandle, request)`

- Creates a `PhoneConnection` for the outgoing call (starts in STATE_DIALING).
- Calls `performEventHandle(OngoingCall, ...)`.

### `onCreateOutgoingConnectionFailed(phoneAccountHandle, request)`

- Calls `performEventHandle(OutgoingFailure, ...)` with the failure reason.

### `onDestroy()`

- Releases wake lock, unregisters broadcast receiver.

## Command Handling (`onStartCommand`)

Explicit `startService` intents arrive here. The intent action is a `ServiceAction` enum value
encoded as a string extra.

| `ServiceAction`          | Description                                                                          |
|--------------------------|--------------------------------------------------------------------------------------|
| `TearDownConnections`    | Call `hungUp()` on every `PhoneConnection`, then broadcast `TearDownComplete`        |
| `ReserveAnswer`          | Store deferred answer for `callId` (call `ConnectionManager.reserveAnswer()`)        |
| `CleanConnections`       | Clear all connections without hanging up                                             |
| `ReplayAudioState`       | Re-emit audio state for all active connections (hot-restart recovery)                |
| `ReplayConnectionStates` | Re-fire `AnswerCall` broadcast for all answered connections (hot-restart recovery)   |
| `AnswerCall`             | Call `PhoneConnection.onAnswer()` for the specified call                             |
| `DeclineCall`            | Call `PhoneConnection.onReject()`                                                    |
| `HungUpCall`             | Call `PhoneConnection.onDisconnect()`                                                |
| `EstablishCall`          | Set connection to STATE_ACTIVE                                                       |
| `UpdateCall`             | Update `PhoneConnection` metadata                                                    |
| `MuteCall`               | `PhoneConnection.changeMuteState()`                                                  |
| `HoldCall`               | `PhoneConnection.onHold()` / `onUnhold()`                                            |
| `SpeakerCall`            | Route audio to speaker                                                               |
| `SetAudioDevice`         | Select audio device                                                                  |
| `SendDtmf`               | Send DTMF tone                                                                       |
| `NotifyPending`          | Register callId as pending before `onCreateIncomingConnection` arrives               |
| `SetCallGroup`           | `handleCallGroup()`: declare the listed calls to be the one group                    |
| `UnsetCallGroup`         | `handleCallGroup()`: take the listed calls out of the group                          |

## Call Groups

Telecom treats two self-managed connections of one application as rivals: it holds one whenever
the other becomes active, and destroys a connection that ignores its hold within about five
seconds. A group of calls is one thing to the user, and `handleCallGroup()` keeps that membership
here - Telecom is never told about it.

An `android.telecom.Conference` would be the sanctioned way to tell it, and it cannot be used
from a self-managed application. `Call.setConnectionProperties` in Telecom masks
`PROPERTY_SELF_MANAGED` off any call whose own `mIsSelfManaged` flag is not set ("ensure the
ConnectionService can't change the state of the self-managed property"), and that flag is set
only for connections - `CallsManager.createConferenceCall` never sets it. A conference therefore
arrives as an ordinary managed call (`prop=[]`, `voip=false`), the default dialer's
`InCallService` is bound to it, and the platform draws the group in its own in-call screen -
with a hang-up button that ends every call in the room. It also shows zero participants there,
because the children are self-managed and invisible to that service.

Nothing about the calls needs the conference. Telecom holds one of them either way; what
membership changes is that the hold is answered and travels no further, which is
`PhoneConnection.isGrouped` (see [phone-connection.md](phone-connection.md)). A room's audio is
mixed away from the device, so a leg carries the room whatever Telecom thinks of its state.

There is one group at a time, and it is read off the connections that carry it, so a membership
naming none of its members still ends it. `SetCallGroup` carries the whole membership: the listed
calls become the group and every other call leaves it. An empty list names no group and changes
nothing. `UnsetCallGroup` takes only the named calls out. One call is not a group, so any
membership that would leave a single call in it leaves nobody in it - the same rule the
standalone backend applies - and that covers both a membership of one and the last member
disconnecting on its own (`PhoneConnection.onStateChanged` -> `releaseFromCallGroup`).

Membership is all that changes. A call crossing the boundary in either direction is left in the
state Telecom put it in, held or active, because taking a held self-managed call off hold while
another is active does not swap them - it ends the call. `holdActiveCallForNewCall` asks whether
the active call can be held, a connection of ours advertises `CAPABILITY_SUPPORT_HOLD` without
`CAPABILITY_HOLD` so it cannot, and the same-source branch then disconnects the held call of this
account outright ("Disconnect held call %s before holding active call %s"). Measured both ways on
a device: a leg of a room gone 20 ms after joining it, and a survivor gone 12 ms after the room
ended - the other call's connection had reached DISCONNECTED while its Telecom call was still
ACTIVE, so no synchronous check can tell the two apart.

The disagreement that leaves behind is bookkeeping: Telecom holds a call the application believes
is speaking. Resolving it belongs to the application, which does so once the other call is really
gone.

The pre-dial hang-up of an active connection in `startOutgoingCall()` never takes a group
member: the group is what Telecom holds for the new call.

## Event Dispatch

All events sent to the main process go through `performEventHandle()`, which calls
`ConnectionServicePerformBroadcaster.handle.dispatch(event, extras)`.

See [ipc-broadcasting.md](ipc-broadcasting.md) for the full event catalogue.

## Key Collaborators

| Class                              | Role                                                                            |
|------------------------------------|---------------------------------------------------------------------------------|
| `ConnectionManager`                | Stores `PhoneConnection` instances and pending/terminated state                 |
| `PhoneConnectionServiceDispatcher` | Routes lifecycle actions to the correct `PhoneConnection`                       |
| `ActivityWakelockManager`          | Acquires/releases wake lock for incoming calls                                  |
| `ProximitySensorManager`           | Manages proximity sensor for in-ear audio routing                               |
| `PhoneConnection`                  | Individual Telecom call object (see [phone-connection.md](phone-connection.md)) |

## Related Components

- [phone-connection.md](phone-connection.md) — individual call object created here
- [connection-manager.md](connection-manager.md) — call registry used here
- [ipc-broadcasting.md](ipc-broadcasting.md) — events dispatched from here
- [dual-process.md](dual-process.md) — explains why this runs in a separate process
