# Data Models

**Package**: `com.webtrit.callkeep.models`

---

## CallMetadata

**File**: `kotlin/com/webtrit/callkeep/models/CallMetaData.kt`

The central data class describing a single call. Passed across process boundaries as a `Bundle`
(not as a `Parcelable` — see constraint below).

### Fields

| Field              | Type                | Description                                      |
|--------------------|---------------------|--------------------------------------------------|
| `callId`           | `String`            | Unique call identifier                           |
| `displayName`      | `String?`           | Human-readable caller name                       |
| `handle`           | `CallHandle?`       | Phone number or SIP URI                          |
| `hasVideo`         | `Boolean?`          | Whether video is enabled                         |
| `audioDevice`      | `AudioDevice?`      | Currently selected audio device                  |
| `audioDevices`     | `List<AudioDevice>` | Available audio devices                          |
| `proximityEnabled` | `Boolean?`          | Whether proximity sensor should be active        |
| `hasMute`          | `Boolean?`          | Whether mute capability is available             |
| `hasHold`          | `Boolean?`          | Whether hold capability is available             |
| `speakerOnVideo`   | `Boolean?`          | Auto-route audio to speaker when video is active |
| `ringtonePath`     | `String?`           | Custom ringtone file path (asset cache)          |

`connectionState: CallConnectionState?` is the transient payload on
`ConnectionStateChanged` events: the live state the main process mirrors into
its shadow state. It is null on all other events.

`CallConnectionState` is a local domain enum (`models/CallConnectionState.kt`:
INITIALIZING/NEW/RINGING/DIALING/ACTIVE/HOLDING/DISCONNECTED). The Telecom adapter maps
framework constants via `telecomConnectionState(Int)`. The shared enum is
deliberately NOT the raw `android.telecom.Connection` state ints (untyped magic numbers, and the
no-Telecom backend has no android `Connection`) nor the Pigeon-generated enum (Pigeon types stay
out of the model layer; the Pigeon mapping happens only at the tracker boundary).

### Bundle Serialization

```kotlin
fun toBundle(): Bundle
companion fun fromBundle(bundle: Bundle): CallMetadata
fun mergeWith(other: CallMetadata): CallMetadata
```

`toBundle()` / `fromBundle()` are used instead of `Parcelable`. Android's `system_server`
process attempts to unparcel objects from Telecom `ConnectionRequest` extras, and using
`Parcelable` would cause a `ClassNotFoundException` because the app's classes are not accessible
from `system_server`.

---

## CallHandle

**File**: `kotlin/com/webtrit/callkeep/models/CallHandle.kt`

Wraps a phone number or SIP URI string passed to Android Telecom.

### Fields

| Field    | Type     | Description                                                 |
|----------|----------|-------------------------------------------------------------|
| `number` | `String` | Raw handle string (e.g., `+15551234567` or `sip:user@host`) |

---

## AudioDevice

**File**: `kotlin/com/webtrit/callkeep/models/AudioDevice.kt`

Represents an audio output endpoint.

### Fields

| Field  | Type              | Description                                                                 |
|--------|-------------------|-----------------------------------------------------------------------------|
| `name` | `String?`         | Display name                                                                |
| `type` | `AudioDeviceType` | `EARPIECE`, `SPEAKER`, `BLUETOOTH`, `WIRED_HEADSET`, `STREAMING`, `UNKNOWN` |
| `id`   | `String?`         | Device identifier (API 34+, corresponds to `CallEndpoint.identifier`)       |

---

## NotificationAction

**File**: `kotlin/com/webtrit/callkeep/models/NotificationAction.kt`

Enum of actions a user can perform from the call notification (answer, decline, hang up, etc.).
Used to route `PendingIntent` callbacks from notification buttons.

---

## FailedCallInfo / FailureMetadata

**Files**: `models/FailedCallInfo.kt`, `models/FailureMetaData.kt`

Carry structured error information when a call fails to connect.

`FailedCallInfo`, a failed outgoing call kept by `ForegroundService`:

| Field    | Description                                                           |
|----------|-----------------------------------------------------------------------|
| `callId` | Call that failed                                                      |
| `reason` | Optional failure description (`String?`)                              |
| `source` | `OutgoingFailureSource` (`DISPATCH_ERROR`, `CS_CALLBACK`, `TIMEOUT`)  |

`FailureMetadata`, the payload of the `OutgoingFailure` / `IncomingFailure` broadcasts, carries
`callMetadata`, `message` and `outgoingFailureType` instead.

---

## Converters

**File**: `kotlin/com/webtrit/callkeep/models/Converters.kt`

Extension functions and utilities for converting between Pigeon-generated types (`PHandle`,
`PAudioDevice`, etc.) and internal model types (`CallMetadata`, `AudioDevice`, etc.).

These are the only place where Pigeon types are translated to internal types. All business logic
works with internal types.

---

## Related Components

- [phone-connection.md](phone-connection.md) — holds `CallMetadata`
- [connection-tracker.md](connection-tracker.md) — stores `CallMetadata` by callId
- [pigeon-apis.md](pigeon-apis.md) — Pigeon types that are converted via `Converters`
