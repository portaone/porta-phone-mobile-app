package com.webtrit.callkeep.services.services.screen_share

import kotlinx.coroutines.CompletableDeferred

/**
 * What the app's requests and [ScreenShareService] tell each other about one screen share, in the
 * main process where both run.
 *
 * A service is started asynchronously, so whether the system let it into the foreground is known
 * only in its own `onStartCommand`: the request waits on [expectPromotion], the service settles it.
 * And the service is what learns that the capture ended outside the app; it reports that to
 * [onEnded], which the app's API forwards to Dart.
 *
 * Every member is used on the main thread: the service's callbacks and the Pigeon host calls run
 * there.
 */
internal object ScreenShareSession {
    private var promotion: CompletableDeferred<Unit>? = null

    /** A stop asked for while the service was started and not yet in the foreground. */
    private var stopWhenPromoted = false

    /** Told when the capture ended outside the app; set while the app's API is attached. */
    var onEnded: (() -> Unit)? = null

    /** A promotion to wait for, made before the service is started; replaces any earlier one. */
    fun expectPromotion(): CompletableDeferred<Unit> {
        promotion?.cancel()
        stopWhenPromoted = false
        return CompletableDeferred<Unit>().also { promotion = it }
    }

    /**
     * Whether the service may be stopped now. A service started and not yet promoted may not:
     * the system ends the app whose started foreground service is stopped before it promoted
     * itself. The request may have given up waiting (its timeout) while the service is still on
     * its way, so the stop is kept and the service carries it out once it is in the foreground
     * ([takeStopRequest]).
     */
    fun mayStopNow(): Boolean {
        if (promotion == null) return true
        stopWhenPromoted = true
        return false
    }

    /** Whether a stop waits for the promotion that has just happened; it is taken once. */
    fun takeStopRequest(): Boolean {
        val requested = stopWhenPromoted
        stopWhenPromoted = false
        return requested
    }

    fun promoted() {
        promotion?.complete(Unit)
        promotion = null
    }

    fun promotionFailed(error: Throwable) {
        promotion?.completeExceptionally(error)
        promotion = null
        stopWhenPromoted = false
    }

    fun ended() {
        onEnded?.invoke()
    }
}
