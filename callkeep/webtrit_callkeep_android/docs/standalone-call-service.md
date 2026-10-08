# StandaloneCallService

**File**: `kotlin/com/webtrit/callkeep/services/services/connection/StandaloneCallService.kt`

**Annotation**: `@Keep`

**Type**: Foreground service in the **main process** (`foregroundServiceType=phoneCall|microphone`)

The call backend for every device whose calls Telecom cannot host. It is the counterpart of
[PhoneConnectionService](phone-connection-service.md): the same commands come in, the same
connection events go out, so `ForegroundService` and the Flutter layer do not know which backend
is active.

---

## Where it runs

`CallServiceRouter` picks the backend once, from `TelephonyUtils.isTelecomSupported`
([callkeep-core.md](callkeep-core.md)). This service takes:

- every release below API 26, where a self-managed `PhoneAccount` cannot be registered;
- devices without the `android.software.telecom` feature and without a phone type - Wi-Fi-only
  tablets, Android Go builds, some OEM configurations.

Everything in it differs from the Telecom path in one way: there is no system component between
the plugin and the call. Nothing rings, routes audio, shows the call or wakes the device unless
this service does it.

|                        | Telecom path                                  | Standalone path                                  |
| ---------------------- | --------------------------------------------- | ------------------------------------------------ |
| Call object            | `PhoneConnection` in `:callkeep_core`         | `CallConnection` in `connections`, main process  |
| Events to the core     | broadcasts across processes                   | `CallkeepCore.notifyConnectionEvent`, in-process |
| Several incoming calls | one rings, the rest wait in the core's queue  | all ring, no queue                               |
| Incoming notification  | one per call, posted by `IncomingCallService` | the service's own foreground notification        |
| Active call            | `ActiveCallService`                           | this service, re-posting its notification        |
| Audio devices          | routed by Telecom                             | earpiece and speaker through `AudioManager`      |

---

## Commands

Commands arrive as intents and are parsed once into a `StandaloneServiceCommand`
(`StandaloneServiceCommand.from`). An intent whose action is unknown, or whose call id or
metadata is missing, is logged and ignored; the service then stops if it holds no call.

| Action (`StandaloneServiceAction`)                                         | Sent by                                                                               | Effect                                                                                                 |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `IncomingCall`                                                             | `startIncomingCall`                                                                   | Registers a ringing call, rings, posts the incoming notification, reports `IncomingConnectionReported` |
| `OutgoingCall`                                                             | `startOutgoingCall`                                                                   | Registers a dialing call, reports `OngoingCall`                                                        |
| `EstablishCall`                                                            | `communicate`                                                                         | Marks the call answered, activates audio, shows the ongoing notification, brings the app forward       |
| `AnswerCall`                                                               | `communicate`, the notification's Answer through `StandaloneAnswerTrampolineActivity` | Same as establish, without starting the Activity (the trampoline does that)                            |
| `ReserveAnswer`                                                            | `communicate`                                                                         | Answers the call if it is registered, else remembers the answer in `pendingAnswers`                    |
| `DeclineCall`, `HungUpCall`                                                | `communicate`, the notification's Decline                                             | Ends the call, reports `HungUp`                                                                        |
| `CancelIncomingCall`                                                       | `communicate`                                                                         | Remembers the id in `cancelledIncomingCallIds` and ends the call                                       |
| `UpdateCall`, `SendDtmf`, `Holding`, `Muting`, `Speaker`, `AudioDeviceSet` | `communicate`                                                                         | Updates the call and reports the matching media event                                                  |
| `SetCallGroup`, `UnsetCallGroup`, `HungUpCallGroup`                        | `sendCallGroup`, the grouped notification                                             | Presentation only - see [call-connection.md](call-connection.md)                                       |
| `ReplayAudioState`, `ReplayConnectionStates`                               | `communicate`                                                                         | Re-emits the state of answered calls for a delegate that attached late                                 |
| `TearDownConnections`, `CleanConnections`                                  | `tearDown`, `communicate`                                                             | Ends or forgets every call                                                                             |

Only `IncomingCall` and `OutgoingCall` start the service (`startForegroundService`). Every other
command goes to a running service; when none runs, `communicate` drops the command and, for a
teardown, answers `TearDownComplete` itself so the caller does not wait.

A call id in `cancelledIncomingCallIds` is refused for the lifetime of the process: an incoming
call that was already declined cannot start ringing afterwards. An `IncomingCall` for such an id
reports `IncomingFailure`.

---

## State

All of it lives in the companion object, in the main process, and is never read by the Telecom
backend.

| Field                          | Holds                                                                                                                                      |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `connections`                  | Every call of this backend by id - ringing, dialing, answered, held                                                                        |
| `ringingIncomingCallIds`       | Incoming calls from registration to their end. Not pruned on answer: "still ringing" is membership here and absence from `answeredCallIds` |
| `answeredCallIds`              | Derived from `connections`                                                                                                                 |
| `pendingAnswers`               | Answers reserved before their call was registered                                                                                          |
| `cancelledIncomingCallIds`     | Incoming calls refused for good                                                                                                            |
| `callGroup`                    | Declared grouping of calls                                                                                                                 |
| `shownNotification` (instance) | Which variant the foreground notification shows: none, incoming or ongoing, and for which call                                             |

The service stops itself when `connections` and `pendingAnswers` are both empty, and on
teardown. `onDestroy` stops the tones and removes the foreground notification.

---

## Notifications

The service is its own notification owner: there is no `IncomingCallService` and no
`ActiveCallService` on this path. Builders are in [notifications.md](notifications.md).

| Id                                 | Notification                           | Channel                                                                             |
| ---------------------------------- | -------------------------------------- | ----------------------------------------------------------------------------------- |
| `PLACEHOLDER_NOTIFICATION_ID` (96) | Placeholder of `promoteToForeground()` | `FOREGROUND_CALL_NOTIFICATION_CHANNEL_ID`                                           |
| `NOTIFICATION_ID` (97)             | Incoming call, then the ongoing call   | `INCOMING_CALL_NOTIFICATION_CHANNEL_ID`, `ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL` |

**The placeholder.** A service started with `startForegroundService` has five seconds to call
`startForeground`, and the incoming handler can return before it posts anything (a cancelled
id). `onStartCommand` therefore promotes with a placeholder first, decided from the raw action
before the command is parsed.

**Why the placeholder has an id of its own.** The system sends a notification's full-screen
intent only for a notification it has not shown yet. Under the call's id the incoming
notification would be an update of the placeholder and its call alert would never be sent.
Moving the foreground state to another id removes the placeholder.

**One id for the calls.** The incoming and ongoing variants share `NOTIFICATION_ID` and
overwrite each other; `shownNotification` records which is up, so a refresh never replaces a
ringing call's Answer and Decline with the ongoing variant. When the call the ongoing
notification stands for ends, a surviving answered call takes it over (`survivingAnchor`).

**Foreground service type.** Ringing uses `phoneCall` only: since Android 14 the microphone type
cannot be taken from the background. An answered call re-promotes with `phoneCall|microphone`,
and falls back to `phoneCall` if that is refused.

---

## Showing an incoming call

Nothing but the notification's call alert opens the app for an incoming call - the service does
not start the Activity itself.

```text
push / signaling
  -> CallkeepCore.registerIncomingCall -> CallServiceRouter -> startIncomingCall
  -> onStartCommand: placeholder (id 96)
  -> handleIncomingCall: ringtone, incoming notification (id 97, full-screen intent)
       system: new notification -> sends the full-screen intent
  -> MainActivity opens or gets onNewIntent, marked EXTRA_OPENED_BY_CALL_ALERT
  -> LockScreenPresence.onActivityIntent
       screen still off  -> wakes it (needsWake)
       device locked     -> show-when-locked and turn-screen-on flags
  -> Flutter builds the call screen and holds the flags from there
```

What the system does with the call alert depends on the device's state:

| State                           | Result                                                                          |
| ------------------------------- | ------------------------------------------------------------------------------- |
| Screen off or locked            | The full-screen intent is sent; the Activity opens over the keyguard            |
| Screen on, app in front         | The app shows its call screen; the notification may also show as a heads-up     |
| Screen on, another app in front | A heads-up notification with Answer and Decline; the app is not brought forward |

The wake in `LockScreenPresence` ([plugin.md](plugin.md)) exists for this path. A window's
turn-screen-on flag acts only when the window goes from hidden to shown, and an Activity that
was on top when the device went to sleep with no keyguard up is still shown for the window
manager. Releases that wake the device for a full-screen intent themselves never reach it; on
Android 7 it is what turns the screen on.

A wake from this service was tried and dropped: with the screen already on and no keyguard, the
system shows the notification as a heads-up and does not send the full-screen intent, so the
app is never opened.

---

## Audio

- **Ringing.** `CallkeepAudioManager` plays the ringtone; with an answered call present, the
  call-waiting tone instead. The tones are one shared instance, so they stop only when no other
  incoming call is still ringing (`hasOtherRingingCall`).
- **Answer.** The process audio mode becomes `MODE_IN_COMMUNICATION`, and goes back to normal
  when the last call ends. Hold does not touch the mode: it belongs to the process, not to a
  call.
- **Devices.** Only earpiece and speaker are reported and switched, through `AudioManager`.
  Bluetooth and wired headsets are not detected on this path.

---

## Several calls

The core's waiting-call queue ([callkeep-core.md](callkeep-core.md)) is for Telecom, which lets
one incoming call ring. Here every incoming call is registered and rings at once, and the app
holds each as an ordinary call.

The notification does not follow: there is one id for all calls of this path. A second incoming
call replaces the first one's notification. It is posted as an update of it, and by the rule
under Notifications an update carries no call alert.

---

## Known Limits

- The active-call phase does not belong here. On the Telecom path `ActiveCallService` owns it,
  with permission-aware foreground types and the camera type for video; the `TODO` in the class
  describes the move.
- One notification id for every call (see Several calls).
- No audio devices beyond earpiece and speaker.

---

## Tests

- `StandaloneCallServiceIncomingAlertTest` - the incoming notification is posted beside the
  placeholder, not over it.
- `StandaloneCallServiceNotificationLifecycleTest` - grouping and call end never take Answer
  and Decline from a ringing call; the ongoing notification passes to a surviving call.
- `StandaloneCallServiceRingtoneGuardTest` - the tones stop only when nothing else rings.
- `CallConnectionAdaptersTest`, `IncomingCallCancellationTest` - shared with the Telecom
  backend.

## Related Components

- [callkeep-core.md](callkeep-core.md) - `CallServiceRouter`, backend choice, in-process events
- [notifications.md](notifications.md) - the standalone notification builders
- [plugin.md](plugin.md) - `LockScreenPresence`, lock-screen flags and the screen wake
- [call-connection.md](call-connection.md) - `CallConnection` and `CallGroup`
- [phone-connection-service.md](phone-connection-service.md) - the Telecom counterpart
