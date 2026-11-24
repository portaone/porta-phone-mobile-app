package com.webtrit.callkeep.services.services.screen_share

import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.annotation.Keep
import androidx.core.content.ContextCompat
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.common.Log
import com.webtrit.callkeep.common.startForegroundServiceCompat
import com.webtrit.callkeep.managers.NotificationChannelManager
import com.webtrit.callkeep.notifications.ScreenShareNotificationBuilder
import java.util.concurrent.CancellationException

/**
 * The foreground service that lets the app capture the screen during a call.
 *
 * Since Android 14 an app may capture the screen only while it runs a foreground service of the
 * `mediaProjection` type, and the system starts such a service only after the person has granted
 * the capture. The WebRTC plugin asks for that consent and captures, but starts no service, so
 * the app starts this one in between ([ScreenShareSession]).
 *
 * A service of its own rather than one more type on the call's service: the call is carried by
 * [com.webtrit.callkeep.services.services.active_call.ActiveCallService] on the Telecom path and
 * by the standalone service elsewhere, and both promote themselves again whenever their call
 * notification changes - each would have to keep the type for as long as a capture runs and drop
 * it when it ends. This one lives exactly as long as the capture, in the main process, where the
 * capture runs.
 *
 * It also tells the app when the capture ends without the app: the Stop action of its
 * notification, and the system ending the capture (the projection's own stop control), which
 * takes away the display the capture draws into ([ScreenCaptureDisplayWatch]).
 */
@Keep
class ScreenShareService : Service() {
    private var displayWatch: ScreenCaptureDisplayWatch? = null

    override fun onCreate() {
        super.onCreate()
        ContextHolder.init(applicationContext)
        Log.initFromContext(applicationContext)
        NotificationChannelManager.registerNotificationChannels(applicationContext)
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int,
    ): Int {
        if (intent?.action == ACTION_STOP) {
            Log.i(TAG, "onStartCommand: stopped from the notification")
            end()
            return START_NOT_STICKY
        }

        // A restart after the process died finds no capture to serve (it died with the process),
        // and a start the app did not ask for has no consent behind it: either way there is
        // nothing to do but the promotion the system demands of a started foreground service.
        try {
            startForegroundServiceCompat(
                this,
                ScreenShareNotificationBuilder.NOTIFICATION_ID,
                ScreenShareNotificationBuilder().build(),
                foregroundServiceType(),
            )
        } catch (e: Exception) {
            // SecurityException when the person has not granted the capture, or the app is not
            // allowed to start a foreground service now; the capture must not start then.
            Log.e(TAG, "onStartCommand: the mediaProjection foreground service was refused: $e")
            ScreenShareSession.promotionFailed(e)
            stopSelf(startId)
            return START_NOT_STICKY
        }

        // Stopped by the app while it came up - the app gave up waiting for it: it goes now that the
        // system lets it, without a word to the app, which asked for the stop itself.
        if (ScreenShareSession.takeStopRequest()) {
            Log.i(TAG, "onStartCommand: stopped by the app before it came to the foreground")
            ScreenShareSession.promotionFailed(CancellationException("stopped before it came to the foreground"))
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf(startId)
            return START_NOT_STICKY
        }

        if (displayWatch == null) {
            val displayManager = getSystemService(DisplayManager::class.java)
            displayWatch =
                ScreenCaptureDisplayWatch(
                    displayManager = displayManager,
                    isCaptureDisplay = { id -> displayManager.getDisplay(id)?.name == CAPTURE_DISPLAY_NAME },
                    onCaptureEnded = {
                        Log.i(TAG, "the capture display went away: the capture ended")
                        end()
                    },
                ).also { it.start(Handler(Looper.getMainLooper())) }
        }
        ScreenShareSession.promoted()
        return START_NOT_STICKY
    }

    /** The capture ended without the app: the app is told, and the service goes. */
    private fun end() {
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        ScreenShareSession.ended()
    }

    private fun foregroundServiceType(): Int? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
        } else {
            null
        }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        displayWatch?.stop()
        displayWatch = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    companion object {
        private const val TAG = "ScreenShareService"

        /** The Stop action of the notification. */
        const val ACTION_STOP = "com.webtrit.callkeep.SCREEN_SHARE_STOP"

        /**
         * The name the WebRTC plugin gives the virtual display its screen capture draws into
         * (`OrientationAwareScreenCapturer.createVirtualDisplay`). Matched by name so a display of
         * anything else - a cast session, another app's capture - is never taken for it; if the
         * plugin renames it, the system's stop is no longer seen and the app's own Stop still is.
         */
        const val CAPTURE_DISPLAY_NAME = "WebRTC_ScreenCapture"

        fun start(context: Context) {
            ContextCompat.startForegroundService(context, Intent(context, ScreenShareService::class.java))
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, ScreenShareService::class.java))
        }
    }
}
