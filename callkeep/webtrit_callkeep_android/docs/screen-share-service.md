# ScreenShareService

The foreground service a screen share runs under during a call: what Android 14 asks of a screen
capture, how the app starts it, and how it tells the app that the capture ended.

**File**: `kotlin/com/webtrit/callkeep/services/services/screen_share/ScreenShareService.kt`

**Annotation**: `@Keep`

**Type**: Foreground service (`foregroundServiceType=mediaProjection`), main process

## Capture order

Since Android 14 an app may capture the screen only while it runs a foreground service of the
`mediaProjection` type, and the system lets such a service into the foreground only after the
person has granted the capture (the `MediaProjection` consent). The WebRTC plugin the app uses asks
for the consent (`Helper.requestCapturePermission`) and captures (`getDisplayMedia`), but starts
no service. So the app runs, in this order:

1. the consent, through the WebRTC plugin;
2. `startScreenShareService()` - this service, in the foreground;
3. the capture, through the WebRTC plugin;
4. `stopScreenShareService()` once the capture is released.

A service of its own rather than one more type on the call's service: the call is carried by
`ActiveCallService` on the Telecom path and by `StandaloneCallService` elsewhere, and both promote
themselves again whenever their call notification changes, so each would have to keep the type for
as long as a capture runs. This one lives exactly as long as the capture, in the main process,
where the capture runs, and serves both backends alike.

## Starting and stopping

`ScreenShareApi` (`PHostScreenShareApi`, registered with the activity's engine) starts the service
with `startForegroundService` and waits for `onStartCommand` to promote it. Whether the system took
the promotion is known only there, so the two meet in `ScreenShareSession`: the request makes a
deferred (`expectPromotion`), the service completes it (`promoted`) or fails it with the refusal
(`promotionFailed`, then `stopSelf`). The request gives up after 5 s, the time the system gives a
started foreground service to promote itself. `stopScreenShareService()` stops the service; it is
`START_NOT_STICKY`, as a capture does not outlive the process.

A request that gave up may still see the service come up later, and the app stops the service as
soon as its start failed. A started foreground service stopped before it promoted itself ends the
app, so while a promotion is awaited the stop is not sent: `ScreenShareSession.mayStopNow` keeps it,
and the service, once in the foreground, takes it (`takeStopRequest`) and stops itself without
telling the app of an end.

## Ends outside the app

The service tells the app, through `PDelegateScreenShareFlutterApi.didEndScreenShare`, when the
capture ends without it, and stops itself:

| End                                                                       | Seen by                             |
|---------------------------------------------------------------------------|-------------------------------------|
| The Stop action of the service's notification                             | `onStartCommand` with `ACTION_STOP` |
| The system ending the projection (its own stop control, another capture)  | `ScreenCaptureDisplayWatch`         |

The WebRTC plugin holds the projection and reports its end to nobody, so the end is read from the
display the capture draws into: the system releases it with the projection.
`ScreenCaptureDisplayWatch` registers a `DisplayManager.DisplayListener` while the service runs,
takes a display added meanwhile under the plugin's name (`WebRTC_ScreenCapture`) for the capture's,
and reports its removal. The app's own stop releases the same display; the report then finds the
share already gone and changes nothing. If the plugin renames the display, the system's stop is no
longer seen; the notification's Stop and the app's own Stop still are.

## Notification

`ScreenShareNotificationBuilder`, id 98, on `SCREEN_SHARE_NOTIFICATION_CHANNEL` (low importance):
"Sharing your screen" with a Stop sharing action; a tap opens the app.

## Tests

- `ScreenShareServiceTest` - the `mediaProjection` type, a refused type failing the request, a stop
  asked for before the promotion and carried out after it, the notification's Stop.
- `ScreenCaptureDisplayWatchTest` - only the capture display seen to appear counts.

What no JVM test shows: the system's consent and its refusal of the type on a device, and the
display going away when the system stops the projection.

## Related Components

- [pigeon-apis.md](pigeon-apis.md) - `PHostScreenShareApi`, `PDelegateScreenShareFlutterApi`
- [notifications.md](notifications.md) - channel registration
- [background-services.md](background-services.md) - the call's own foreground services
