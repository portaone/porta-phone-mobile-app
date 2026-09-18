# PhoneConnection

**File**: `kotlin/com/webtrit/callkeep/services/services/connection/PhoneConnection.kt`

**Extends**: Android `Connection`

**Process**: `:callkeep_core`

## Responsibility

`PhoneConnection` represents a **single active call** inside Android Telecom. One instance exists
per call and is owned by `ConnectionManager`. It handles all Telecom-driven callbacks for that
call and dispatches corresponding events to the main process.

### Capabilities and properties

Declared once in `init`: `PROPERTY_SELF_MANAGED`, `audioModeIsVoip`, and the capabilities
`CAPABILITY_MUTE`, `CAPABILITY_SUPPORT_HOLD` and `CAPABILITY_HOLD`.

The last two answer different questions and both are needed. `CAPABILITY_SUPPORT_HOLD` says the
call supports being held at all; `CAPABILITY_HOLD` says it can be held **right now**, which is true
here - `onHold` is implemented and answers with `setOnHold` at any point of the call.

Telecom arbitrates a new call against the active one along two paths, and they read the flags
differently:

- **legacy** (`CallsManager.holdActiveCallForNewCall`, still taken by OEM builds such as a Xiaomi
  on Android 15) asks `CallsManager.canHold`, which a `ConnectionService` call passes only on
  `CAPABILITY_HOLD` - a transactional call gets by on `CAPABILITY_SUPPORT_HOLD`, and these
  connections are not transactional. On false the same-source branch runs, and it does not swap the
  two calls: it **disconnects** the first held call of this application;
- **sequencing** (`CallSequencingController.holdActiveCallForNewCallWithSequencing`, Android 15 and
  newer) never consults `canHold`. It requests the hold and disconnects the call only if the hold
  does not arrive - which for these connections it always does.

So the capability is not what keeps a call alive in the ordinary case: an incoming cellular call
answered over an active one holds that call either way. What it does is keep the statement true and
the legacy path's lethal branch out of reach, which matters as soon as anything makes a held
connection active while another one is active - the way a call group used to.

## State

| Field            | Type           | Description                                       |
|------------------|----------------|---------------------------------------------------|
| `callId`         | `String`       | Unique call identifier (matches across processes) |
| `metadata`       | `CallMetadata` | Call details (display name, handle, flags)        |
| `hasAnswered`    | `Boolean`      | Whether the user has accepted the call            |
| `isMute`         | `Boolean`      | Current mute state                                |
| `hasVideo`       | `Boolean`      | Whether video is enabled                          |
| Internal `state` | `Int`          | Telecom connection state constant                 |

## Telecom Callback Methods

### `onShowIncomingCallUi()`

Telecom asks the app to display its incoming call UI.

- Acquires wake lock.
- Starts ringtone.
- Shows incoming call notification (via `NotificationManager`).

### `onAnswer(videoState)`

User or app code answers the call.

- Sets state to `STATE_ACTIVE`.
- Stops ringtone, cancels incoming-call notification.
- Dispatches `AnswerCall` broadcast to main process.

### `onReject()` / `onReject(rejectWithMessage, textMessage)`

User or app code declines the call.

- Sets state to `STATE_DISCONNECTED` with cause `CAUSE_REMOTE_USER_HANGUP` (rejected).
- Dispatches `DeclineCall` broadcast to main process.
- Calls `destroy()`.

### `onDisconnect()`

Called by Telecom when the call ends (hang-up from either side).

- Stops ringtone, audio, cancels notifications.
- Sets state to `STATE_DISCONNECTED`.
- Dispatches `HungUp` broadcast to main process.
- Calls `destroy()`.

### `onHold()` / `onUnhold()`

- Updates state to `STATE_HOLDING` / `STATE_ACTIVE`.
- Dispatches `ConnectionHolding` broadcast with new hold state.
- **Member of a call group** (`isGrouped`): complies with Telecom (`setOnHold()` / `setActive()`)
  but dispatches nothing. Telecom holds one call whenever another becomes active; the application
  owns the media of a group and a member is never held on its own, so the application is not told.
  The reply is not optional - a connection that does not reach the state Telecom asked for is
  disconnected a few seconds later. Leaving the group changes nothing about the state: the call
  stays as Telecom left it and holds reach the application again from the next one on.

### `onPlayDtmfTone(c)` / `onStopDtmfTone()`

- Dispatches `SentDTMF` broadcast.

### `onStateChanged(state)`

Telecom-driven hook fired on every connection state transition.

- Maps the raw Telecom `state` int via `telecomConnectionState(state)`.
- On `STATE_DISCONNECTED`, a member leaves its call group, which is taken apart once fewer than
  two calls remain in it.
- For live states (RINGING/DIALING/ACTIVE/HOLDING) dispatches `ConnectionStateChanged`,
  carrying the state in `CallMetadata.connectionState` so the main process MIRRORS it into the
  shadow state rather than inferring a fixed state per event type.
- Terminal DISCONNECTED is skipped here -- it stays on the cause-carrying `HungUp` / `DeclineCall`
  dispatched from `onDisconnect()` / `onReject()`.

### `onCallEndpointChanged(endpoint)` (API 34+) / legacy audio device change

Telecom addresses these to the foreground call. Grouped calls are ordinary connections to it -
there is no conference object to address instead - so each one hears them under its own call id.

- Dispatches `AudioDeviceSet` broadcast with the new endpoint.
- Dispatches `AudioDevicesUpdate` broadcast with full device list.

## Media Methods

### `changeMuteState(muted)`

- Updates `isMute`.
- Sets Telecom audio mute.
- Dispatches `AudioMuting` broadcast.

### `setSpeaker(on)` / `setAudioDevice(device)`

- Routes audio via the Telecom `CallAudioState` or `CallEndpoint` APIs.
- Dispatches `AudioDeviceSet` broadcast.

## Factory Methods

```kotlin
companion object {
    fun createIncomingPhoneConnection(context, callId, metadata): PhoneConnection
    fun createOutgoingPhoneConnection(context, callId, metadata): PhoneConnection
}
```text

Incoming connections start in `STATE_RINGING`; outgoing connections start in `STATE_DIALING`.

## Lifecycle Summary

```text
Incoming: INITIALIZING -> RINGING -> (onAnswer) ACTIVE -> (onDisconnect) DISCONNECTED
                                  -> (onReject)  DISCONNECTED
Outgoing: DIALING -> (setActive) ACTIVE -> (onDisconnect) DISCONNECTED
```

## Related Components

- [phone-connection-service.md](phone-connection-service.md) — creates and owns this object
- [connection-manager.md](connection-manager.md) — stores this object
- [ipc-broadcasting.md](ipc-broadcasting.md) — events dispatched from callbacks here

## Shared state

`PhoneConnection` owns the backend-independent `CallConnection`; metadata, answer and mute
state live there. Framework state stays on Android `Connection`. See
[Shared call connection and group](call-connection.md) for the ownership and hold boundary.
