package com.webtrit.callkeep.services.services.incoming_call.handlers

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.webtrit.callkeep.PCallkeepIncomingCallData
import com.webtrit.callkeep.PEndCallReason
import com.webtrit.callkeep.PHostBackgroundPushNotificationIsolateApi
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.core.CallkeepCore
import com.webtrit.callkeep.services.services.incoming_call.CallConnectionController
import com.webtrit.callkeep.services.services.incoming_call.FlutterIsolateCommunicator

enum class DeclineSource {
    USER,
    SERVER,
}

class CallLifecycleHandler(
    private val connectionController: CallConnectionController,
    private val stopService: () -> Unit,
    private var isolateHandler: FlutterIsolateHandler,
    private val core: CallkeepCore = CallkeepCore.instance,
) : PHostBackgroundPushNotificationIsolateApi {
    internal var flutterApi: FlutterIsolateCommunicator? = null

    var currentCallData: PCallkeepIncomingCallData? = null

    // Notify connection service about answering the call
    fun reportAnswerToConnectionService(metadata: CallMetadata) {
        connectionController.answer(metadata)
    }

    // Notify connection service about declining the call
    fun reportDeclineToConnectionService(metadata: CallMetadata) {
        connectionController.decline(metadata)
    }

    // Connection service event for answering the call, synchronized with Flutter if the app is in the background.
    // Does NOT call connectionController.answer() on success: Telecom already confirmed the answer by
    // invoking this method; a second answer() call would send a duplicate signal to the connection service.
    fun performAnswerCall(metadata: CallMetadata) {
        val api = flutterApi
        if (api == null) {
            Log.w(TAG, "performAnswerCall: flutterApi is null, no Flutter isolate to notify for callId=${metadata.callId}")
            // The push isolate is not reachable, so markAnswered() will never be
            // called through the normal Flutter callback path. Mark the connection
            // here so the connection tracker reflects STATE_ACTIVE instead of stateDisconnected.
            CallkeepCore.instance.markAnswered(metadata.callId)
            return
        }
        api.performAnswer(metadata.callId, onSuccess = {
            Log.d(TAG, "performAnswerCall: Flutter isolate acknowledged answer for callId=${metadata.callId}")
        }, onFailure = {
            Log.d(TAG, "Tear down connection due to answer failure: $it")
            connectionController.tearDown()
        })
    }

    fun performEndCall(metadata: CallMetadata) {
        val api = flutterApi
        if (api != null) {
            api.performEndCall(
                metadata.callId,
                onSuccess = { release() },
                onFailure = { release() },
            )
        } else {
            Log.w(TAG, "performEndCall: flutterApi is null, releasing resources directly")
            release()
        }
    }

    fun terminateCall(
        metadata: CallMetadata,
        source: DeclineSource,
    ) {
        declineCallByBackground(metadata, source)
    }

    fun declineCallByBackground(
        metadata: CallMetadata,
        source: DeclineSource,
    ) {
        when (source) {
            DeclineSource.USER -> handleUserDecline(metadata)
            DeclineSource.SERVER -> handleServerDecline(metadata)
        }
    }

    private fun handleUserDecline(metadata: CallMetadata) {
        if (isolateHandler.isReady == true) {
            performSafeEndCall(metadata.callId, metadata)
        } else {
            flutterApi?.syncPushIsolate(currentCallData, onSuccess = {
                performSafeEndCall(metadata.callId, metadata)
            }, onFailure = {
                Log.e(TAG, "Sync before decline failed: $it")
                connectionController.hangUp(metadata)
                stopServiceFor(metadata.callId)
            })
        }
    }

    // Event from flutter side, as case signaling declined the call
    private fun handleServerDecline(metadata: CallMetadata) {
        connectionController.decline(metadata)
    }

    private fun performSafeEndCall(
        callId: String,
        metadata: CallMetadata,
    ) {
        flutterApi?.performEndCall(callId, onSuccess = {
            Log.d(TAG, "Call end sent via signaling")
        }, onFailure = {
            Log.e(TAG, "Call end signaling failed: $it")
            connectionController.hangUp(metadata)
            stopServiceFor(metadata.callId)
        })
    }

    override suspend fun reportEndCall(
        callId: String,
        reason: PEndCallReason,
    ) {
        // The core owns the end: it ends the call in the backend and remembers that the session
        // knows, so the IC_RELEASE_ENDED that follows does not come back as performEndCall.
        // The service keeps running for whatever the session still has to do.
        core.reportCallEnded(CallMetadata(callId = callId), reason.value)
    }

    override suspend fun endCall(callId: String) {
        terminateCall(CallMetadata(callId = callId), DeclineSource.SERVER)
    }

    override suspend fun endAllCalls() {
        connectionController.tearDown()
    }

    override suspend fun releaseCall(callId: String) {
        Log.d(TAG, "releaseCall: $callId — unanswered, terminating connection and stopping service")
        terminateCall(CallMetadata(callId = callId), DeclineSource.SERVER)
        stopServiceFor(callId)
    }

    override suspend fun handoffCall(callId: String) {
        // Called when the Activity is taking over the call — either because the user
        // answered via push-notification UI, or because the Activity launched as a
        // full-screen intent and the push isolate's budget expired while the call was
        // still ringing. In both cases the PhoneConnection must stay alive; only
        // IncomingCallService is stopped so the Activity can handle the call normally.
        Log.d(TAG, "handoffCall: $callId — stopping service only, connection stays alive (Activity handoff)")
        stopServiceFor(callId)
    }

    /**
     * Stops the service only when [callId] is the call it shows.
     *
     * The push isolate ends and hands off calls by id, and a session can learn of more than one
     * call (the handshake lists every line). Stopping on another call's end took the ringing
     * call's notification and foreground state away while it still rang.
     */
    private fun stopServiceFor(callId: String) {
        val shown = currentCallData?.callId
        if (shown != null && shown != callId) {
            Log.i(TAG, "stopService for $callId skipped: this service shows $shown")
            return
        }
        stopService()
    }

    fun release(onComplete: (() -> Unit)? = null) {
        Log.d(TAG, "Resources released")
        onComplete?.invoke()
        stopServiceWithDelay()
    }

    private fun stopServiceWithDelay() {
        Log.d(TAG, "Stopping service")
        Handler(Looper.getMainLooper()).postDelayed({
            Log.d(TAG, "Stopped service")
            stopService()
        }, SERVICE_STOP_DELAY_MS)
    }

    companion object {
        private const val SERVICE_STOP_DELAY_MS = 1000L
        private const val TAG = "CallLifecycleHandler"
    }
}
