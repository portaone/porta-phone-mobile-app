package com.webtrit.callkeep.services.services.incoming_call.handlers

import android.annotation.SuppressLint
import android.app.Service
import android.content.pm.ServiceInfo
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import com.webtrit.callkeep.WebtritCallkeep
import com.webtrit.callkeep.common.startForegroundServiceCompat
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.notifications.IncomingCallNotificationBuilder
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.core.CallkeepCore
import com.webtrit.callkeep.services.services.foreground.ForegroundService

/**
 * Handles the lifecycle of an incoming call within a foreground Service:
 *  - shows the initial high-priority incoming-call notification
 *  - gives the call to the app's delegate when one is ready, otherwise to a push isolate
 *  - transitions the notification to silent (ring muted) or releases it after answer
 *
 * This class is intentionally side-effectful and **does not** own Service lifecycle;
 * it only delegates to Service foreground APIs and the Notification builder.
 *
 * Thread-safety: methods are expected to be called on the main thread (Service thread).
 */
class IncomingCallHandler(
    private val service: Service,
    private val notificationBuilder: IncomingCallNotificationBuilder,
    private val isolateInitializer: IsolateInitializer,
    notifierOverride: NotificationManagerCompat? = null,
) {
    private var lastMetadata: CallMetadata? = null

    // Defaults to the system notifier for the service; tests inject their own. Lazy so the
    // default is not created (and the service not touched) until a notification is posted.
    private val notifier: NotificationManagerCompat by lazy {
        notifierOverride ?: NotificationManagerCompat.from(service)
    }

    // Derived from the current call's ID so each incoming call gets a unique notification ID.
    // A unique ID guarantees the system treats the notification as new — not an update to a
    // previous one — which is required for fullScreenIntent to fire on Android 14+.
    // lastMetadata is always non-null when this property is read: showNotification() sets it
    // before accessing currentNotificationId, and every other caller is guarded by its own
    // lastMetadata != null check before reaching it.
    private val currentNotificationId: Int
        get() = IncomingCallNotificationBuilder.notificationId(lastMetadata!!.callId)

    /**
     * Entry point to process a fresh incoming call.
     * Shows the ringing notification and starts background handling unless the main app is active.
     */
    fun handle(metadata: CallMetadata) {
        Log.d(
            TAG,
            "Handling incoming call: id=${metadata.callId}, handle=${metadata.handle}, " + "name=${metadata.displayName}, video=${metadata.hasVideo}",
        )
        show(metadata)
        maybeInitBackgroundHandling()
    }

    /**
     * Posts the ringing notification and takes the service into the foreground, nothing more:
     * the call is given to nobody. For a call that is released before it is shown.
     */
    fun show(metadata: CallMetadata) {
        lastMetadata = metadata
        showNotification(metadata)
    }

    /**
     * Replaces the ringing notification with a silent one to transition out of the ringing phase.
     * The silent notification keeps the FGS alive while the signaling layer completes teardown
     * (decline path) or while the active-call session takes over (answer path).
     *
     * Does nothing when the metadata is missing - reading the notification id or rebuilding the
     * notification without it would throw, and that happens when the service instance never
     * showed a notification of its own.
     */
    @SuppressLint("MissingPermission")
    fun releaseIncomingCallNotification() {
        if (lastMetadata == null) {
            Log.w(TAG, "releaseIncomingCallNotification: no metadata (service not initialized), skipping")
            return
        }
        Log.d(TAG, "releaseIncomingCallNotification: rewriting notification $currentNotificationId to silent")
        showSilentNotification()
    }

    /**
     * Drops the answer/decline buttons as soon as the call has been answered.
     *
     * The notification is rewritten in place to its silent variant: same id, same call, but with
     * nothing to press. Until now the buttons stayed up until the whole incoming-call service was
     * torn down, which on a cold start happens only once the app has finished starting - long
     * enough for the user to press answer a second time on a call that is already answered.
     *
     * Does nothing when the metadata is missing - reading the notification id or rebuilding the
     * notification without it would throw, and that happens when the service instance never
     * showed a notification of its own.
     */
    @SuppressLint("MissingPermission")
    fun dropIncomingCallActions() {
        if (lastMetadata == null) {
            Log.w(TAG, "dropIncomingCallActions: no metadata (service not initialized), skipping")
            return
        }
        Log.d(TAG, "dropIncomingCallActions: rewriting notification $currentNotificationId without actions")
        showSilentNotification()
    }

    /**
     * Takes this service out of the foreground and removes its notification, while the service
     * itself keeps running until the connection is handed over.
     *
     * Used once the active call is showing a notification of its own: from that moment the
     * incoming one describes a call the user is already on. `STOP_FOREGROUND_REMOVE` both drops
     * the foreground state and takes the notification away; the explicit cancel afterwards is
     * the same belt-and-braces as in [cancelCurrentNotification], because some Samsung builds
     * leave it in the shade.
     */
    @SuppressLint("MissingPermission")
    fun detachForegroundNotification() {
        if (lastMetadata == null) {
            Log.w(TAG, "detachForegroundNotification: no metadata (service not initialized), skipping")
            return
        }
        Log.d(TAG, "detachForegroundNotification: leaving foreground, removing notification $currentNotificationId")
        service.stopForeground(Service.STOP_FOREGROUND_REMOVE)
        notifier.cancel(currentNotificationId)
    }

    /**
     * Takes the service back into the foreground with the silent notification of its call.
     *
     * Every startForegroundService must be answered with startForeground, even when the service
     * shows nothing new: a second launch delivered after [detachForegroundNotification] finds the
     * service out of the foreground, and the system kills the process when it stops without one
     * (ForegroundServiceDidNotStartInTimeException).
     */
    fun returnToForegroundSilently() {
        if (lastMetadata == null) {
            Log.w(TAG, "returnToForegroundSilently: no metadata (service not initialized), skipping")
            return
        }
        Log.d(TAG, "returnToForegroundSilently: id=$currentNotificationId")
        service.startForegroundServiceCompat(
            service,
            currentNotificationId,
            notificationBuilder.buildSilent(),
            ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL,
        )
    }

    /**
     * Explicitly cancels the call-derived notification (ID ≥ 1000) if a call was handled.
     * Called from IncomingCallService.onDestroy() as a belt-and-suspenders cleanup:
     * stopForeground(REMOVE) does not reliably cancel the FGS notification on some Samsung
     * builds, so we cancel it directly to prevent a lingering notification in the shade.
     */
    @SuppressLint("MissingPermission")
    fun cancelCurrentNotification() {
        if (lastMetadata == null) return
        notifier.cancel(currentNotificationId)
    }

    /**
     * Rewrites the current call notification in place to its silent variant: same id, same
     * foreground-service association, no ringing style and no action buttons.
     *
     * Updating the live notification with [NotificationManagerCompat.notify] keeps the service
     * in the foreground throughout. The earlier approach detached the service from its
     * notification and re-promoted it (stopForeground(DETACH) + cancel + startForeground); that
     * momentarily left a CallStyle notification standing without a foreground service, which
     * Android 14+ rejects with CannotPostForegroundServiceNotificationException and terminates
     * the process - taking any call still ringing at that moment down with it.
     */
    @SuppressLint("MissingPermission")
    private fun showSilentNotification() {
        notifier.notify(currentNotificationId, notificationBuilder.buildSilent())
    }

    private fun showNotification(metadata: CallMetadata) {
        // Build a high-priority incoming call notification and elevate the Service to foreground.
        // foregroundServiceType must be passed explicitly: on API 34+ startForeground() without
        // a type throws InvalidForegroundServiceTypeException when the manifest declares one.
        val notification = notificationBuilder.apply { setCallMetaData(metadata) }.build()
        Log.d(TAG, "startForeground [ringing]: id=$currentNotificationId SDK=${Build.VERSION.SDK_INT}")
        service.startForegroundServiceCompat(
            service,
            currentNotificationId,
            notification,
            ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL,
        )
        Log.d(TAG, "startForeground [ringing]: completed")
    }

    private fun maybeInitBackgroundHandling() {
        // Skip isolate launch when callkeep is hosted on an external engine (attached via
        // WebtritCallkeep.attachToEngine, e.g. a persistent signaling foreground service). That
        // engine already owns the background work; callkeep only needs to show the call UI here.
        // Starting its own isolate would open a duplicate signaling connection.
        if (WebtritCallkeep.isHostedOnExternalEngine) {
            Log.d(TAG, "maybeInitBackgroundHandling: hosted on external engine, skipping isolate launch")
            return
        }
        // One rule, as on iOS where a push-registered call is reported to the app: a call the
        // push registered goes to the app's delegate when one is ready, and to a push isolate
        // otherwise. Whether an Activity is visible says nothing about who will take the call -
        // the app closes its socket when a call ends in the background, and the OS may close it
        // too - so holding the call is what makes the app reconnect and learn whether it still
        // rings. A delegate that is not ready (call handling not built yet, or torn down) leaves
        // the call to the isolate, and the app takes it over through the usual handoff once its
        // delegate attaches.
        val metadata = lastMetadata
        if (metadata != null && ForegroundService.isDelegateReady) {
            if (CallkeepCore.instance.isReportedByApp(metadata.callId)) {
                // The app reported this call itself; presenting it back would duplicate it.
                Log.d(TAG, "maybeInitBackgroundHandling: ${metadata.callId} was reported by the app")
            } else {
                Log.d(TAG, "maybeInitBackgroundHandling: delegate ready, presenting ${metadata.callId} to the app")
                presentToApp(metadata)
            }
            return
        }
        Log.d(TAG, "Launching isolate for callId: ${lastMetadata?.callId}")
        isolateInitializer.start()
    }

    companion object {
        private const val TAG = "IncomingCallHandler"
    }
}

/**
 * Gives an incoming call to the app's delegate through the path a freshly attached delegate is
 * seeded by ([CallLifecycleEvent.ReplayIncomingCall] -> ForegroundService ->
 * didPresentIncomingCall), marked present-only: no push session ran, so no handoff is confirmed,
 * and the incoming-call service keeps ringing - its notification is the call UI while the app is
 * in the background.
 */
private fun presentToApp(metadata: CallMetadata) {
    val extras = metadata.toBundle().apply { putBoolean(ForegroundService.PRESENT_ONLY, true) }
    CallkeepCore.instance.notifyConnectionEvent(CallLifecycleEvent.ReplayIncomingCall, extras)
}
