package com.webtrit.callkeep

import com.webtrit.callkeep.common.Log
import kotlinx.coroutines.CompletableDeferred

/**
 * The [PHostApi] handler registered the moment the activity attaches, so that Dart calls are
 * never lost while the asynchronous bindService() completes. Every call is forwarded to the
 * bound [ForegroundService] at call time.
 *
 * setUp() is the only call that may arrive before the service binds: it suspends until
 * [connected] runs. All other calls are only reachable after a successful setUp(), by which
 * point the service is bound. A call that is still waiting, or that resumes, after
 * [disconnected] fails with an error rather than reaching a service the activity no longer
 * holds: pigeon runs each host call on a later main-looper step, so a detach can land between
 * the call arriving and the call running.
 */
internal class ForegroundServiceProxy : PHostApi {
    @Volatile
    private var target: PHostApi? = null

    // Completed with the service on bind. Renewed when a bind starts and failed on unbind, so
    // a setUp() that waited across a detach gets an error, one that arrives after the detach
    // does not pick up a service completed before it, and one that arrives while the
    // activity is binding again waits for the new service rather than failing on the old
    // detach.
    @Volatile
    private var connected: CompletableDeferred<PHostApi> = CompletableDeferred()

    /** A bind has started; a setUp() from now on waits for the service it will bring. */
    fun binding() {
        if (connected.isCompleted) connected = CompletableDeferred()
    }

    /** The service is bound; release every setUp() waiting for it. */
    fun connected(service: PHostApi) {
        target = service
        binding()
        connected.complete(service)
    }

    /** The service is gone; fail every setUp() waiting for it, and every one still to come. */
    fun disconnected() {
        target = null
        val gone = IllegalStateException("ForegroundService not connected")
        connected.completeExceptionally(gone)
        connected = CompletableDeferred<PHostApi>().also { it.completeExceptionally(gone) }
    }

    private fun service(): PHostApi = target ?: throw IllegalStateException("ForegroundService not connected")

    override fun isSetUp(): Boolean = target?.isSetUp() ?: false

    override suspend fun setUp(options: POptions) {
        val service =
            target ?: run {
                Log.i(TAG, "setUp: ForegroundService not yet connected, waiting for it")
                connected.await()
            }
        // The await may resume after a detach: the service it returned is no longer the one
        // this activity holds, and pigeon must not report a setUp that never happened.
        if (service !== target) throw IllegalStateException("ForegroundService not connected")
        service.setUp(options)
    }

    override suspend fun tearDown() = service().tearDown()

    override suspend fun reportNewIncomingCall(
        callId: String,
        handle: PHandle,
        displayName: String?,
        hasVideo: Boolean,
    ): PIncomingCallError? = service().reportNewIncomingCall(callId, handle, displayName, hasVideo)

    override suspend fun reportConnectingOutgoingCall(callId: String) = service().reportConnectingOutgoingCall(callId)

    override suspend fun reportConnectedOutgoingCall(callId: String) = service().reportConnectedOutgoingCall(callId)

    override suspend fun reportUpdateCall(
        callId: String,
        handle: PHandle?,
        displayName: String?,
        hasVideo: Boolean?,
        proximityEnabled: Boolean?,
    ) = service().reportUpdateCall(callId, handle, displayName, hasVideo, proximityEnabled)

    override suspend fun reportEndCall(
        callId: String,
        displayName: String,
        reason: PEndCallReason,
    ) = service().reportEndCall(callId, displayName, reason)

    override suspend fun startCall(
        callId: String,
        handle: PHandle,
        displayNameOrContactIdentifier: String?,
        video: Boolean,
        proximityEnabled: Boolean,
    ): PCallRequestError? = service().startCall(callId, handle, displayNameOrContactIdentifier, video, proximityEnabled)

    override suspend fun answerCall(callId: String): PCallRequestError? = service().answerCall(callId)

    override suspend fun endCall(callId: String): PCallRequestError? = service().endCall(callId)

    override suspend fun setHeld(
        callId: String,
        onHold: Boolean,
    ): PCallRequestError? = service().setHeld(callId, onHold)

    override suspend fun setMuted(
        callId: String,
        muted: Boolean,
    ): PCallRequestError? = service().setMuted(callId, muted)

    override suspend fun setSpeaker(
        callId: String,
        enabled: Boolean,
    ): PCallRequestError? = service().setSpeaker(callId, enabled)

    override suspend fun setAudioDevice(
        callId: String,
        device: PAudioDevice,
    ): PCallRequestError? = service().setAudioDevice(callId, device)

    override suspend fun sendDTMF(
        callId: String,
        key: String,
    ): PCallRequestError? = service().sendDTMF(callId, key)

    override fun onDelegateSet() = target?.onDelegateSet() ?: Unit

    companion object {
        private const val TAG = "ForegroundServiceProxy"
    }
}
