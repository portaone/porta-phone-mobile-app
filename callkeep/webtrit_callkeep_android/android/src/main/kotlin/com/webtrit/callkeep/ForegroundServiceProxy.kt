package com.webtrit.callkeep

import com.webtrit.callkeep.common.Log

/**
 * The [PHostApi] handler registered the moment the activity attaches, so that Dart calls are
 * never lost while the asynchronous bindService() completes. Every call is forwarded to the
 * bound [ForegroundService] at call time.
 *
 * setUp() is the only call that may arrive before the service binds: it is queued and
 * replayed by [connected]. Only one setUp can be in flight at a time; a second call replaces
 * the first. All other calls are only reachable after a successful setUp(), by which point
 * the service is bound.
 */
internal class ForegroundServiceProxy : PHostApi {
    @Volatile
    private var target: PHostApi? = null

    private var pendingSetUp: Pair<POptions, (Result<Unit>) -> Unit>? = null

    /** The service is bound; replay the setUp() that arrived before it. */
    fun connected(service: PHostApi) {
        target = service
        pendingSetUp?.let { (options, callback) ->
            Log.i(TAG, "connected: replaying queued setUp()")
            pendingSetUp = null
            service.setUp(options, callback)
        }
    }

    /** The service is gone. */
    fun disconnected() {
        target = null
    }

    private fun notConnected() = IllegalStateException("ForegroundService not connected")

    override fun isSetUp(): Boolean = target?.isSetUp() ?: false

    override fun setUp(
        options: POptions,
        callback: (Result<Unit>) -> Unit,
    ) {
        val svc = target
        if (svc != null) {
            svc.setUp(options, callback)
        } else {
            Log.i(TAG, "setUp: ForegroundService not yet connected, queuing call")
            pendingSetUp = Pair(options, callback)
        }
    }

    override fun tearDown(callback: (Result<Unit>) -> Unit) =
        target?.tearDown(callback)
            ?: callback(Result.failure(notConnected()))

    override fun reportNewIncomingCall(
        callId: String,
        handle: PHandle,
        displayName: String?,
        hasVideo: Boolean,
        callback: (Result<PIncomingCallError?>) -> Unit,
    ) = target?.reportNewIncomingCall(callId, handle, displayName, hasVideo, callback)
        ?: callback(Result.failure(notConnected()))

    override fun reportConnectingOutgoingCall(
        callId: String,
        callback: (Result<Unit>) -> Unit,
    ) = target?.reportConnectingOutgoingCall(callId, callback)
        ?: callback(Result.failure(notConnected()))

    override fun reportConnectedOutgoingCall(
        callId: String,
        callback: (Result<Unit>) -> Unit,
    ) = target?.reportConnectedOutgoingCall(callId, callback)
        ?: callback(Result.failure(notConnected()))

    override fun reportUpdateCall(
        callId: String,
        handle: PHandle?,
        displayName: String?,
        hasVideo: Boolean?,
        proximityEnabled: Boolean?,
        callback: (Result<Unit>) -> Unit,
    ) = target?.reportUpdateCall(callId, handle, displayName, hasVideo, proximityEnabled, callback)
        ?: callback(Result.failure(notConnected()))

    override fun reportEndCall(
        callId: String,
        displayName: String,
        reason: PEndCallReason,
        callback: (Result<Unit>) -> Unit,
    ) = target?.reportEndCall(callId, displayName, reason, callback)
        ?: callback(Result.failure(notConnected()))

    override fun startCall(
        callId: String,
        handle: PHandle,
        displayNameOrContactIdentifier: String?,
        video: Boolean,
        proximityEnabled: Boolean,
        callback: (Result<PCallRequestError?>) -> Unit,
    ) = target?.startCall(callId, handle, displayNameOrContactIdentifier, video, proximityEnabled, callback)
        ?: callback(Result.failure(notConnected()))

    override fun answerCall(
        callId: String,
        callback: (Result<PCallRequestError?>) -> Unit,
    ) = target?.answerCall(callId, callback)
        ?: callback(Result.failure(notConnected()))

    override fun endCall(
        callId: String,
        callback: (Result<PCallRequestError?>) -> Unit,
    ) = target?.endCall(callId, callback)
        ?: callback(Result.failure(notConnected()))

    override fun setHeld(
        callId: String,
        onHold: Boolean,
        callback: (Result<PCallRequestError?>) -> Unit,
    ) = target?.setHeld(callId, onHold, callback)
        ?: callback(Result.failure(notConnected()))

    override fun setMuted(
        callId: String,
        muted: Boolean,
        callback: (Result<PCallRequestError?>) -> Unit,
    ) = target?.setMuted(callId, muted, callback)
        ?: callback(Result.failure(notConnected()))

    override fun setSpeaker(
        callId: String,
        enabled: Boolean,
        callback: (Result<PCallRequestError?>) -> Unit,
    ) = target?.setSpeaker(callId, enabled, callback)
        ?: callback(Result.failure(notConnected()))

    override fun setAudioDevice(
        callId: String,
        device: PAudioDevice,
        callback: (Result<PCallRequestError?>) -> Unit,
    ) = target?.setAudioDevice(callId, device, callback)
        ?: callback(Result.failure(notConnected()))

    override fun sendDTMF(
        callId: String,
        key: String,
        callback: (Result<PCallRequestError?>) -> Unit,
    ) = target?.sendDTMF(callId, key, callback)
        ?: callback(Result.failure(notConnected()))

    override fun onDelegateSet() = target?.onDelegateSet() ?: Unit

    companion object {
        private const val TAG = "ForegroundServiceProxy"
    }
}
