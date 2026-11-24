package com.webtrit.callkeep

import android.content.Context
import com.webtrit.callkeep.common.Log
import com.webtrit.callkeep.services.services.screen_share.ScreenShareService
import com.webtrit.callkeep.services.services.screen_share.ScreenShareSession
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout

/**
 * Implements the Pigeon API that runs [ScreenShareService] for the app's screen share, and
 * forwards to Dart the ends of the share the app did not ask for.
 *
 * Registered with the activity's engine: a screen share is started from the call screen, and its
 * end has to reach the engine that shows it.
 */
class ScreenShareApi(
    private val context: Context,
    private val delegate: PDelegateScreenShareFlutterApi,
) : PHostScreenShareApi {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private val forwardEnd: () -> Unit = {
        scope.launch {
            try {
                delegate.didEndScreenShare()
            } catch (e: Exception) {
                Log.w(TAG, "didEndScreenShare was not delivered: $e")
            }
        }
    }

    init {
        ScreenShareSession.onEnded = forwardEnd
    }

    override suspend fun startScreenShareService() {
        Log.i(TAG, "startScreenShareService")
        val promotion = ScreenShareSession.expectPromotion()
        ScreenShareService.start(context)
        // The system kills a started foreground service that has not promoted itself within a few
        // seconds; past that the start has failed whatever the service says later.
        withTimeout(PROMOTION_TIMEOUT_MS) { promotion.await() }
    }

    override suspend fun stopScreenShareService() {
        if (!ScreenShareSession.mayStopNow()) {
            // A start that timed out on this side may still bring the service up; it stops itself
            // then, as stopping it before its promotion would end the app.
            Log.i(TAG, "stopScreenShareService: the service is not in the foreground yet, it stops once it is")
            return
        }
        Log.i(TAG, "stopScreenShareService")
        ScreenShareService.stop(context)
    }

    /** The engine went away: nothing is forwarded to it any more. */
    fun dispose() {
        // Only its own: an API made for a newer engine may have taken the place already.
        if (ScreenShareSession.onEnded === forwardEnd) ScreenShareSession.onEnded = null
        scope.cancel()
    }

    companion object {
        private const val TAG = "ScreenShareApi"
        private const val PROMOTION_TIMEOUT_MS = 5_000L
    }
}
