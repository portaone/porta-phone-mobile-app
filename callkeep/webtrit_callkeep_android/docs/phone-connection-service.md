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
| `SetCallGroup`           | `handleCallGroup()`: build or restate the one `PhoneConference` for the listed calls |
| `UnsetCallGroup`         | `handleCallGroup()`: take the listed calls out of the conference                     |

## Call Groups (`PhoneConference`)

Telecom treats two self-managed connections of one application as rivals: it holds one whenever
the other becomes active, and destroys a connection that ignores its hold within about five
seconds. A group of calls is one thing to the user, so `handleCallGroup()` makes it one thing to
Telecom as well - an `android.telecom.Conference` (`PhoneConference`) with the calls as children.

There is one group at a time. `SetCallGroup` carries the whole membership: with no conference it
builds one, adds every listed call and makes every child active (every member of a group is
speaking); with a conference standing it restates it - children left off the list are removed,
listed calls not yet in it are added, and a group Telecom held while the application dialled or
answered another call is made active again. A membership of one takes the group apart for
everyone. `UnsetCallGroup` removes only the named calls. Whenever fewer than two calls remain,
the conference is ended (`dissolveIfLonely()`), also when a child disconnects on its own
(`PhoneConnection.onStateChanged`); an emptied conference would otherwise stay in Telecom as a
phantom managed call until the process dies.

A call that leaves a group held is made active on the way out: Telecom's sequencing then holds
whichever call it must, and that hold reaches the application like any other. While grouped, a
child answers Telecom's hold by complying without telling the application (see
[phone-connection.md](phone-connection.md)).

Once the conference is the foreground call, Telecom addresses the audio route, the endpoint list
and the microphone state to it rather than to its calls; `PhoneConference` hands those callbacks
to every child, so each still reports under its own call id. `PhoneConference.onDisconnect()` -
the system's own conference notification has a hang-up - ends every call in the group.

Telecom files the conference as a managed call regardless of `PROPERTY_SELF_MANAGED`, so the
system dialer shows a "Conference call" notification with hang-up, speaker and mute; that is
the platform's presentation of the group, not the plugin's.

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
| `PhoneConference`                  | The one Telecom `Conference` a call group is presented as (see above)           |

## Related Components

- [phone-connection.md](phone-connection.md) — individual call object created here
- [connection-manager.md](connection-manager.md) — call registry used here
- [ipc-broadcasting.md](ipc-broadcasting.md) — events dispatched from here
- [dual-process.md](dual-process.md) — explains why this runs in a separate process
