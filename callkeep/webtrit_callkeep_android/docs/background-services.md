# Background Services

Two foreground services operate in the **main process** to handle calls that arrive while the
Flutter app is backgrounded or killed.

---

## IncomingCallService

**File**: `kotlin/com/webtrit/callkeep/services/services/incoming_call/IncomingCallService.kt`

**Annotation**: `@Keep`

**Implements**: `ConnectionEventListener`

**Type**: One-shot foreground service (`foregroundServiceType=phoneCall`)

### Responsibility

Spawned when an FCM push notification (or SMS trigger) announces an incoming call. It:

1. Starts a short-lived Flutter background isolate.
2. Shows the incoming-call notification / system UI.
3. Waits for the user or app code to answer or decline.
4. Exits when the app's push session finishes, or a safety-net timeout fires.

### Lifecycle

- Started by `NotificationManager.showIncomingCallNotification()`, whose only caller is
  `PhoneConnection.onShowIncomingCallUi()` in the `:callkeep_core` process. (The push path
  gets there indirectly: `reportNewIncomingCall()` hands the call to
  `CallkeepCore.registerIncomingCall()`, Telecom registers it, and this service starts from the
  resulting connection callback.)
- `onCreate()` - registers the internal release receiver (see below), subscribes to
  `CallkeepCore` events via `addConnectionEventListener(this)`, and wires the handlers.
  It does **not** promote to foreground yet.
- `onStartCommand(IC_INITIALIZE)` - delegates to `IncomingCallHandler`, which shows the
  ringing notification and promotes the service to foreground (per-call notification id,
  1000+). The call itself was already registered with Telecom by `PhoneConnectionService`
  before this service started. Every `onStartCommand` path returns `START_NOT_STICKY`: if
  the OS kills the service, a restart with a null intent must not re-post a notification
  for a call that is gone.
- The notification's Answer and Decline buttons also enter through `onStartCommand`, as
  service `PendingIntent`s (`NotificationAction.Answer` / `Decline`); Answer additionally
  drops the notification buttons right away.
- Release (the end of the ringing phase) is delivered via an **internal broadcast**
  (`IC_RELEASE_HANDED_OVER` / `IC_RELEASE_ENDED`), not via `onStartCommand`: the
  receiver only lives while the service is alive, so a release arriving after the service
  stopped goes nowhere instead of restarting it.
- Every release names its call (`callId` extra), and the service acts only on a release for
  the call it shows. The release is sent on the end of any call - an outgoing or active one,
  or a second incoming call Telecom refused while this one rings - so acting on another
  call's release would tear down a call that is still ringing. A release can also come before
  the service knows its call: one posted while the service is not running waits in
  `PendingBroadcastQueue` under its call id, and one received before `IC_INITIALIZE` is kept
  by the service per call id. `handleLaunch` acts only on the release for the call it
  launches. An `AnswerCall` event is ignored only once the service shows another call.
- Only the push session's end stops the service: the completion of the app's `syncPushIsolate`
  callback (`onSessionFinished`), with the connection left as the session left it - ended
  through `reportEndCall`, or alive for the engine that holds it. A late completion for another
  call than the one the service shows, or one after the service started stopping, changes
  nothing. The service therefore stays up for everything the session does before its future
  resolves - the missed-call record and its notification included - and the app owes it a
  future that resolves only when that work is done.
- A release ends the ringing phase (wake lock, silent notification) and tells the session what
  happened, nothing more: `IC_RELEASE_ENDED` for an end nobody reported yet becomes
  `performEndCall` (the session ends the call on the server, records it and finishes);
  `IC_RELEASE_HANDED_OVER`, or an end the app reported itself, becomes `performHandoff` (the
  call is no longer the session's concern; it finishes). A session that cannot be reached has
  nothing to finish and the service stops at once. From the release the session has
  `SESSION_FINISH_TIMEOUT_MS` (10 s) to finish; then the service stops without it.
- The handoff is confirmed by callkeep, not guessed by the session: `ForegroundService` sends
  `IC_RELEASE_HANDED_OVER` once its delegate has taken the call (`didPresentIncomingCall` returned,
  or the answered call's `AnswerCall` was delivered). An Activity on screen or the Activity's
  WebSocket displacing the session's (4441) says nothing about who receives the call's events -
  on a Samsung M32 cold start the delegate attached 8.8 s after that socket connected, and a
  session that let go on the socket left the hangup of that window with nobody to report it.
- The push isolate also reports and ends calls by id (`reportEndCall`, `releaseCall`,
  `handoffCall`), and its session can know more than one call. `reportEndCall` hands the end to
  the core and keeps the service running. `CallLifecycleHandler` stops the service only when
  the id of a `releaseCall` or `handoffCall` is the call the service shows; for another call it
  ends that call and keeps running. Neither is needed on the normal paths any more.
- Two safety-net timeouts force-stop the service if the normal flow stalls: an independent
  60 s timeout armed at launch, and the 10 s session-finish budget armed when the ringing
  phase ends.
- `onDestroy()` - unsubscribes, stops foreground, and explicitly cancels the current
  notification (on some Samsung builds `stopForeground(REMOVE)` alone leaves it in the
  shade), then tears the isolate down.

### Answered-call notification handoff

Once the call is answered (from the notification button, the system call UI, a headset or a
watch) the ringing notification is replaced in place by its **silent form** - same call, no
buttons - so the user is not offered Answer for a call already taken while the app finishes
starting. When `ActiveCallService` posts the in-progress notification, it broadcasts
`IC_ACTIVE_CALL_VISIBLE`; on receiving it, `IncomingCallService` gives its own notification
up (`stopForeground`) so the shade does not describe the same call twice. The service itself
keeps running - no longer foreground - until the connection is handed over to the app or a
safety-net timeout stops it.

### Connection Event Listener

`IncomingCallService` implements `ConnectionEventListener` and receives events routed by
`CallkeepCore`. It only acts on `AnswerCall` - when the system UI or the user answers,
`PhoneConnectionService` fires `AnswerCall`, which drops the notification buttons and forwards
to `CallLifecycleHandler.performAnswerCall()`. `DeclineCall` and `HungUp` are handled via the
`IC_RELEASE_ENDED` broadcast path instead to avoid a double `performEndCall` race. On that
release the service asks the push isolate to end the call (`performEndCall`) only when the end
was not reported by the app: after `reportEndCall` the core has marked the end dispatched
(`markEndCallDispatched` answers false), and the service releases without it, so the session
never declines on the server a call the server already hung up.

### Key Handlers (Composition)

| Handler                                                | Responsibility                                                            |
|--------------------------------------------------------|---------------------------------------------------------------------------|
| `IncomingCallHandler`                                  | Owns the incoming-call notification and the foreground promotion          |
| `CallLifecycleHandler`                                 | Handles answer/decline events; dispatches to Flutter isolate              |
| `FlutterIsolateCommunicator` / `FlutterIsolateHandler` | Manages the background Flutter isolate lifecycle                          |

### Related Bootstrap API

`BackgroundPushNotificationIsolateBootstrapApi` (registered in `WebtritCallkeepPlugin`):

| Method                                                                       | Description                                                                                                                                                                                                                                        |
|------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `initializePushNotificationCallback(callbackDispatcher, onNotificationSync)` | Stores the two Dart entry-point handles                                                                                                                                                                                                            |
| `reportNewIncomingCall(callId, handle, displayName, hasVideo)`               | Builds `CallMetadata` and awaits `CallkeepCore.registerIncomingCall(metadata, client)`: null once Telecom confirms, an error on refusal, duplicate or the registration deadline (`IncomingCallService` starts later, from the connection callback) |

---

## ActiveCallService

**File**: `kotlin/com/webtrit/callkeep/services/services/active_call/ActiveCallService.kt`

**Annotation**: `@Keep`

**Type**: Foreground service (`foregroundServiceType=phoneCall|microphone|camera`)

### Responsibility

Owns the single **active call notification** summarizing every call in progress (one
notification, `ActiveCallNotificationBuilder.NOTIFICATION_ID = 1`). It renders whatever
call list it is started with; the list itself lives in `NotificationManager`'s static
`activeCalls` state in the `:callkeep_core` process (see notifications.md), and this
service only ever sees the copy serialized into each start intent.

### Lifecycle

- Started (and re-started on every change) by `NotificationManager.upsertActiveCallsService()`
  whenever a call is added, removed or reordered: the service receives the full call list in
  the `metadata` intent extra and re-posts the notification.
- Stopped by `NotificationManager` (`context.stopService`) when the call list becomes empty,
  or by `NotificationManager.tearDown()`. The service stops itself only in the empty-restart
  guard (see below); on every other path it is stopped from outside.
- `onStartCommand` promotes to foreground with a type set computed per start: `phoneCall`
  always; `microphone` whenever the permission is granted (deliberately not conditioned on
  audio state - some OEM builds block microphone access with the screen off if the type is
  missing); `camera` when a video call is present and the permission is granted. On
  Android 14+ a background promotion (the sticky restart) rejects the `microphone` type with
  `SecurityException`; the service falls back to the plain `phoneCall` type so the restart
  does not crash-loop.
- After posting the notification it broadcasts `IC_ACTIVE_CALL_VISIBLE` so
  `IncomingCallService` can give up its now-redundant notification (see above).
- Returns `START_STICKY` for starts carrying calls (if the process is killed mid-call, the
  OS restarts the service); the Decline action and the empty-restart guard return
  `START_NOT_STICKY`.

### Notification action

The notification offers one Hang up button. Its intent carries the first call's bundle in
the extras. The service hangs up the first call of its in-memory list via
`CallkeepCore.startHungUpCall(call)`; when that list is empty (a fresh instance created by
the tap after a process death), it falls back to the call bundle from the intent extras.
With neither - Hang up tapped on a notification re-posted by a null-intent restart - it
tears down the connection services, removes the notification and stops itself.

### Sticky restart with a null intent

A `START_STICKY` restart after a main-process kill delivers a **null intent**, so the
restarted instance builds an empty call list. The restart bypasses `NotificationManager`
(whose call list lives in `:callkeep_core` and died with it), so nothing external would
ever stop such an instance - historically its half-empty ongoing notification could only
be removed by force-stopping the app. `onStartCommand` guards against this: after
satisfying the `startForeground` contract it detects the empty list, logs a warning,
tears down the connection services (a call leg may have survived in `:callkeep_core`,
and this restart is the last signal the main process gets about it), removes the
notification and stops itself with `stopSelf(startId)`, returning `START_NOT_STICKY`.
The teardown runs before `stopForeground` so the command toward the connection services
is still exempt from background-start restrictions; `stopSelf(startId)` (not a blanket
`stopSelf()`) keeps a queued metadata start from the recovering app alive.

---

## Related Components

- [plugin.md](plugin.md) - registers bootstrap APIs on engine attach
- [pigeon-apis.md](pigeon-apis.md) - bootstrap API definitions
- [notifications.md](notifications.md) - notification builders used by these services
- [incoming-call-handling.md](incoming-call-handling.md) - end-to-end incoming-call delivery
- [foreground-service.md](foreground-service.md) - coordinates with `ActiveCallService`
- [callkeep-core.md](callkeep-core.md) - `ConnectionEventListener` API used by `IncomingCallService`
