# Notification System

## Overview

Call notifications are built by four builder classes sharing one abstract base, and their
lifecycle is driven by the services that own them. Each call phase has a dedicated builder;
the dual-process (Telecom) path and the standalone path have separate builder families that
share the same notification channels.

| Phase / path                 | Builder                                     | Channel                                    |
|------------------------------|---------------------------------------------|--------------------------------------------|
| Incoming call (Telecom path) | `IncomingCallNotificationBuilder`           | `INCOMING_CALL_NOTIFICATION_CHANNEL_ID`    |
| Active call (Telecom path)   | `ActiveCallNotificationBuilder`             | `ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL` |
| Incoming call (standalone)   | `StandaloneIncomingCallNotificationBuilder` | `INCOMING_CALL_NOTIFICATION_CHANNEL_ID`    |
| Active call (standalone)     | `StandaloneActiveCallNotificationBuilder`   | `ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL` |

The abstract base `NotificationBuilder` (`kotlin/com/webtrit/callkeep/notifications/NotificationBuilder.kt`)
centralizes the audio/video branching of the incoming-call content (title, description, small
icon), so the ringing, silent and standalone variants stay in sync.

---

## NotificationChannelManager

**File**: `kotlin/com/webtrit/callkeep/managers/NotificationChannelManager.kt`

Registers the four notification channels (and deletes the legacy
`NOTIFICATION_ACTIVE_CALL_CHANNEL_ID` channel left behind by older versions). Called from
`ForegroundService.setUp()` on the Telecom path and from `StandaloneCallService` on the
standalone path.

| Channel ID                                 | Importance | Description                                                              |
|--------------------------------------------|------------|--------------------------------------------------------------------------|
| `INCOMING_CALL_NOTIFICATION_CHANNEL_ID`    | `HIGH`     | Heads-up notification with ringtone for incoming calls                   |
| `ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL` | `LOW`      | Persistent silent notification for active calls                          |
| `FOREGROUND_CALL_NOTIFICATION_CHANNEL_ID`  | `LOW`      | Standalone-service placeholder notification (see the standalone section) |
| `QUEUED_CALL_NOTIFICATION_CHANNEL`         | `LOW`      | A call waiting in the core's queue while another incoming call rings     |

---

## NotificationManager (Manager Facade)

**File**: `kotlin/com/webtrit/callkeep/managers/NotificationManager.kt`

Facade over the two notification-hosting services of the Telecom path. It keeps the list of
active calls in a **static in-memory list** (`activeCalls` in its companion object). Both of
its users - `PhoneConnection` and `ConnectionServicePerformBroadcaster` - run inside
`PhoneConnectionService` in the **`:callkeep_core` process**, so that is where the list
lives; the main-process `ActiveCallService` never reads it and only sees the copy serialized
into each start intent.

| Method                                       | Action                                                                                                            |
|----------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| `showIncomingCallNotification(metadata)`     | Starts `IncomingCallService` with the call data                                                                   |
| `cancelIncomingNotification(callId, reason)` | Releases `IncomingCallService` for that call via an internal broadcast; a service showing another call ignores it |
| `showActiveCallNotification(id, meta)`       | Adds/moves the call to the head of `activeCalls`, then upserts the service                                        |
| `cancelActiveCallNotification(id)`           | Removes the call from `activeCalls`, then upserts the service                                                     |
| `tearDown()`                                 | Stops both notification services                                                                                  |

The private `upsertActiveCallsService()` implements the active-call lifecycle: while
`activeCalls` is non-empty it (re)starts `ActiveCallService` with the full list serialized
into the `metadata` intent extra; when the list becomes empty it stops the service. A live
caller therefore never starts the service without metadata.

---

## IncomingCallNotificationBuilder

**File**: `kotlin/com/webtrit/callkeep/notifications/IncomingCallNotificationBuilder.kt`

Builds the notification shown while the phone is ringing, plus its silent variant.

### Ringing variant (`build()`)

- **Style**: `Notification.CallStyle.forIncomingCall(person, declineIntent, answerIntent)`
  (API 31+) or a plain builder with explicit answer/decline action buttons on API 26-30.
- **Insistent**: `FLAG_INSISTENT` is set, but the notification itself is soundless (the
  channel is registered with its sound suppressed) - the looping ringtone is played by
  `AudioManager.startRingtone`, driven from `PhoneConnection`, not by the notification.
- **Full-screen intent**: applied only when enabled by configuration and the full-screen
  intent permission is granted; it launches the **host app's launcher activity** over the
  lock screen - the plugin has no dedicated incoming-call activity (its only activities are
  the answer trampolines). The intent (`buildCallAlertIntent`) is marked as the alert's and
  has a request code of its own, so `LockScreenPresence` can tell it from any other opening
  of the app (see [plugin.md](plugin.md), Lock-Screen Flags).
- **Decline**: a service `PendingIntent` back to `IncomingCallService` carrying the call's
  bundle.
- **Answer**: an activity `PendingIntent` through `AnswerCallTrampolineActivity`, so the
  answer also works from the lock screen.
- **Notification ids**: derived per call, starting at 1000 - distinct from the active-call
  notification id.

### Silent variant (`buildSilent()`)

Same call content on the same channel, but with the answer/decline actions and the insistent
flag removed. Shown once the call has been answered, so the user is no longer offered buttons
for a call that is already taken while the app finishes starting.

---

## ActiveCallNotificationBuilder

**File**: `kotlin/com/webtrit/callkeep/notifications/ActiveCallNotificationBuilder.kt`

Builds the single persistent notification for calls in progress. There is always **one**
notification (`NOTIFICATION_ID = 1`) summarizing every active call, not one entry per call.

- **Title**: "Outgoing call" for a single call whose metadata says `DIALING` (an outgoing call
  the other side has not answered yet); otherwise "Active call", or "Active calls" for several.
- **Text**: the caller names of all active calls, joined.
- **Action**: one Hang up button. Its `PendingIntent` targets `ActiveCallService` with the
  `Decline` action and carries the **first** call's bundle in the extras. If that call is in a
  group (`CallkeepCore.groupMembersWith`), the service hangs up every member; otherwise that call alone.
- **Telecom groups**: nothing is posted by the platform. A group is not declared to Telecom at
  all (see [phone-connection-service.md](phone-connection-service.md)), so this notification is
  the only one the user gets for a room.
- **Behavior**: `setOngoing(true)`, `setOnlyAlertOnce(true)`, media style with the action in
  compact view. As an ongoing FGS notification it cannot be swiped away.

---

## Standalone builders

**Files**: `kotlin/com/webtrit/callkeep/notifications/StandaloneIncomingCallNotificationBuilder.kt`,
`StandaloneActiveCallNotificationBuilder.kt`

Internal builders used by `StandaloneCallService` (the single-process fallback path that does
not register with Telecom). They mirror the ringing and active variants on the incoming and
active channels; the standalone answer goes through `StandaloneAnswerTrampolineActivity` and
all action intents target `StandaloneCallService` instead of the dual-process services.

`StandaloneActiveCallNotificationBuilder` also takes the calls grouped with the one it is
built from. The calls of this path share a single notification id, so a group cannot be shown
as one entry per call - the entries would overwrite each other and leave whichever call was
answered last standing for the whole group. A grouped notification names every member, and
its hang-up action ends every one of them, through
`StandaloneServiceAction.HungUpCallGroup` rather than the single-call `HungUpCall`.

In addition, `StandaloneCallService.promoteToForeground()` posts a short-lived inline
placeholder notification (built without any of these builders) on
`FOREGROUND_CALL_NOTIFICATION_CHANNEL_ID`, only to satisfy the 5-second `startForeground`
window, and switches to the incoming-call notification right after - that placeholder is the
sole producer on the foreground channel.

The placeholder has a notification id of its own; the incoming and ongoing notifications share
the other one. The system sends a full-screen intent only for a notification it has not shown
yet, so an incoming-call notification posted under the placeholder's id would be an update of
the placeholder and its call alert would never open the app - on a sleeping device the call
rang behind a dark screen. Moving the foreground state to the call's id removes the
placeholder.

---

## QueuedCallNotifications

**File**: `kotlin/com/webtrit/callkeep/notifications/QueuedCallNotifications.kt`

The notification of a call waiting in the core's queue ([callkeep-core.md](callkeep-core.md),
Waiting calls). One per waiting call, id derived from `"queued:" + callId` so it never collides
with the incoming notification the same call gets once it rings. Silent, low importance and
ongoing: it never heads up over the ringing call or an open app, which shows every call itself.
Posted when the call starts waiting, cancelled when it is put through or leaves the queue.

- **Answer**: an activity `PendingIntent` to `QueuedCallTrampolineActivity`, which calls
  `CallkeepCore.answerQueuedCall` and brings the host app up - answering has to end on the call
  screen, and the tap carries the launch permission.
- **Decline current**: a broadcast to `QueuedCallActionReceiver`, which calls
  `CallkeepCore.declineRingingCalls`; the oldest waiting call then rings.
- **Tap**: opens the app.

Both actions are carried out by the core, so they work without a running Flutter engine.

## AudioManager

**File**: `kotlin/com/webtrit/callkeep/managers/AudioManager.kt`

Handles ringtone, ringback and call-waiting tone playback, plus device-capability queries.

| Method                     | Description                                                                                                                                                                  |
|----------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `startRingtone(sound)`     | Ring or vibrate by ringer mode: ringtone (asset path or system default) in normal mode with volume; vibration only in vibrate mode or at zero volume; nothing in silent mode |
| `stopRingtone()`           | Stop ringtone and vibration                                                                                                                                                  |
| `startRingback(asset)`     | Play outgoing ringback tone                                                                                                                                                  |
| `stopRingback()`           | Stop ringback                                                                                                                                                                |
| `startCallWaitingTone()`   | Play the call-waiting tone for a second incoming call                                                                                                                        |
| `stopCallWaitingTone()`    | Stop the call-waiting tone                                                                                                                                                   |
| `isSupportEarpiese()` etc. | Query available devices (earpiece, speakerphone, wired headset, Bluetooth)                                                                                                   |

---

## Call alert and screen wake

The call alert opens the app through the full-screen intent of the incoming-call notification.
The system decides whether to send that intent, and these facts decide what callkeep can do
around it. The rule about a new notification id is in the standalone section above; the flags
and the wake lock the Activity gets once it is open are in [plugin.md](plugin.md),
Lock-Screen Flags.

- **No full-screen intent on an awake, unlocked screen.** The system shows the notification as
  a heads-up instead. If you wake the screen before posting the notification, the system sees
  an awake device and the app does not open. Wake only after the intent has opened the
  Activity (`LockScreenPresence.onActivityIntent`). `IncomingCallService` follows the same
  rule: it acquires its screen wake lock (`acquireScreenWakeLockIfNeeded`) only when
  `isFullScreenIntentAvailable()` is false, where the notification itself is the call UI.
- **Window flags do not replace opening the Activity.** Show-when-locked and turn-screen-on
  on the window of an app that is already on top do not bring the call up by themselves: on
  Android 7 they lit the screen only with the keyguard already showing, on Android 13 not even
  then. The alert has to open the Activity.
- **Dozing is asleep.** A device can report its wakefulness as `Dozing` rather than `Asleep`.
  A check for "the screen is off" has to mean "not awake"; callkeep reads
  `PowerManager.isInteractive`, which is false for both.

### Bringing the app up from `:callkeep_core`

`PhoneConnection.establish()` calls `context.startActivity(Platform.getLaunchActivity(context))`
when an outgoing call is answered, from the `:callkeep_core` process. On Android 17 Telecom
binds the connection service without the right to start an activity from the background, and
the system logs `Background activity launch blocked!` for this start. The app still came to
the front in most runs, because the window manager moved its existing task forward right
after; in some runs it stayed in the background. Do not rely on this start to show the call
screen on Android 17. To watch it: `adb logcat -s ActivityTaskManager WindowManagerShell`
while the call is answered.

### Seeing it in the device log

`adb logcat -b events -b system -b main` shows what the system did without a debugger:

| Line                                                                  | Meaning                                                             |
|-----------------------------------------------------------------------|---------------------------------------------------------------------|
| `notification_enqueue: [uid,pid,pkg,id,tag,user,Notification(...),N]` | last field: 0 - a new notification, 1 - an update                   |
| `notification_canceled`                                               | notification removed, also when a foreground service changes its id |
| `sysui_fullscreen_notification`                                       | SystemUI sent the full-screen intent                                |
| `sysui_heads_up_status`, `sysui_heads_up_escalation`                  | shown as a heads-up; a heads-up escalated to full screen            |
| `START u0 {... cmp=.../.MainActivity (has extras)}`, `am_new_intent`  | the Activity was started; a running one got a new intent            |
| `PowerManagerService: Waking up from ... (uid ...)`                   | who woke the device: the app, SystemUI or the system                |

Screen and keyguard state: `adb shell dumpsys power | grep mWakefulness`; on Android 7
`dumpsys window policy` (`showing=`, `occluded=`), on Android 8+ `dumpsys window`
(`isKeyguardShowing=`, `mKeyguardOccluded=`); the focused window is `mCurrentFocus`.

The API 24 emulator image has no lock screen by default, and its `locksettings` has no shell
command yet. To turn the lock screen on, then reboot (`value=1` turns it off again):

```sh
adb root
adb shell sqlite3 /data/system/locksettings.db \
  "update locksettings set value=0 where name='lockscreen.disabled'"
```

Not checked: vendor SystemUI builds, Android 8-12 and 14+, and a Telecom device whose screen
timed out before the keyguard came up.

---

## Related Components

- [background-services.md](background-services.md) - services that host these notifications
- [incoming-call-handling.md](incoming-call-handling.md) - end-to-end incoming-call delivery
- [phone-connection.md](phone-connection.md) - triggers `showIncomingCallNotification` /
  `showActiveCallNotification` / the cancel calls from connection state changes
- [foreground-service.md](foreground-service.md) - registers the notification channels on setup
