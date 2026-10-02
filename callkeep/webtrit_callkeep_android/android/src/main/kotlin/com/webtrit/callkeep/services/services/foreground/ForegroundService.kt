package com.webtrit.callkeep.services.services.foreground

import android.annotation.SuppressLint
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.annotation.Keep
import androidx.annotation.RequiresApi
import com.webtrit.callkeep.PAudioDevice
import com.webtrit.callkeep.PCallRequestError
import com.webtrit.callkeep.PCallRequestErrorEnum
import com.webtrit.callkeep.PCallkeepConnectionState
import com.webtrit.callkeep.PDelegateFlutterApi
import com.webtrit.callkeep.PEndCallReason
import com.webtrit.callkeep.PEndCallReasonEnum
import com.webtrit.callkeep.PHandle
import com.webtrit.callkeep.PHostApi
import com.webtrit.callkeep.PIncomingCallError
import com.webtrit.callkeep.PIncomingCallErrorEnum
import com.webtrit.callkeep.POptions
import com.webtrit.callkeep.common.ActivityHolder
import com.webtrit.callkeep.common.Log
import com.webtrit.callkeep.common.Platform
import com.webtrit.callkeep.common.StorageDelegate
import com.webtrit.callkeep.common.TelephonyUtils
import com.webtrit.callkeep.managers.NotificationChannelManager
import com.webtrit.callkeep.models.CallConnectionState
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.models.FailedCallInfo
import com.webtrit.callkeep.models.FailureMetadata
import com.webtrit.callkeep.models.InvalidCallMetadataException
import com.webtrit.callkeep.models.OutgoingFailureSource
import com.webtrit.callkeep.models.OutgoingFailureType
import com.webtrit.callkeep.models.toAudioDevice
import com.webtrit.callkeep.models.toCallHandle
import com.webtrit.callkeep.models.toPAudioDevice
import com.webtrit.callkeep.models.toPHandle
import com.webtrit.callkeep.services.broadcaster.CallCommandEvent
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.broadcaster.CallMediaEvent
import com.webtrit.callkeep.services.broadcaster.ConnectionEvent
import com.webtrit.callkeep.services.core.AnswerCallRoute
import com.webtrit.callkeep.services.core.CallEndListener
import com.webtrit.callkeep.services.core.CallGroupOutcome
import com.webtrit.callkeep.services.core.CallkeepCore
import com.webtrit.callkeep.services.services.incoming_call.IncomingCallRelease
import com.webtrit.callkeep.services.services.incoming_call.IncomingCallService
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean

/**
 * ForegroundService is an Android bound Service that maintains a connection with the main Flutter isolate
 * while the app's activity is active. It implements the [com.webtrit.callkeep.PHostApi] interface to receive and handle method calls
 * from the Flutter side via Pigeon.
 *
 * Responsibilities:
 * - Acts as a bridge between Android Telecom API and Flutter.
 * - Handles both incoming and outgoing call actions.
 * - Sends updates back to Flutter using [com.webtrit.callkeep.PDelegateFlutterApi].
 * - Manages call features such as mute, hold, speaker, DTMF.
 * - Registers notification channels and Telecom PhoneAccount on setup.
 * - Listens for ConnectionService reports via intents.
 *
 * Lifecycle:
 * - Bound to the activity lifecycle: starts when activity is active, stops when unbound.
 * - Registers and unregisters itself via [com.webtrit.callkeep.services.core.CallkeepCore] for connection events.
 */
@Keep
class ForegroundService :
    Service(),
    PHostApi,
    CallEndListener {
    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }

    // Carries the calls into Dart. Pigeon generates them as suspend functions; the service
    // fires them from broadcast handlers and never waits for the answer, so they run here.
    // Main.immediate sends a call made on the main thread before the caller continues,
    // which keeps the order the callback-style generated code had.
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    /**
     * Fire a delegate call into Dart without waiting for it. A failure is logged, as the
     * callback-style code used to ignore it: the delegate may be gone, and there is nobody
     * to hand the error to.
     */
    private fun notifyFlutter(
        name: String,
        onSuccess: (() -> Unit)? = null,
        block: suspend PDelegateFlutterApi.() -> Unit,
    ) {
        val api = flutterDelegateApi ?: return
        scope.launch {
            runCatching { api.block() }
                .onFailure { logger.w("$name: delegate call failed: ${it.message}") }
                .onSuccess { onSuccess?.invoke() }
        }
    }

    private val activityWakelockManager = ActivityWakelockManager(ActivityHolder)

    // Stored as fields so onDestroy() can cancel the timeout and unregister the receiver
    // if the service is destroyed before the TearDownComplete ack arrives.
    private var tearDownAckReceiver: BroadcastReceiver? = null
    private var tearDownTimeoutRunnable: Runnable? = null

    private val binder = LocalBinder()

    // Per-call cleanup lambdas keyed by callId. Each entry cancels the per-call timeout
    // and unregisters the per-call receiver without resuming the suspended host call (the
    // service is being destroyed, so the channel is already gone). Populated in startCall()
    // after the receiver is registered, and removed in finish() when the call resolves
    // normally. Using a map instead of a set allows cancelling a previous pending call
    // when startCall() is invoked again with the same callId.
    private val pendingCallCleanupsByCallId: ConcurrentHashMap<String, () -> Unit> = ConcurrentHashMap()

    /**
     * Resume a suspended host call once. The second answer for one call - a timeout that
     * already resolved it, then the late Telecom reply - is dropped, as Flutter used to drop
     * the second reply to one request.
     */
    private fun <T> CancellableContinuation<T>.resumeIfActive(result: Result<T>) {
        if (isActive) resumeWith(result)
    }

    private var _flutterDelegateApi: PDelegateFlutterApi? = null
    var flutterDelegateApi: PDelegateFlutterApi?
        get() = _flutterDelegateApi
        set(value) {
            _flutterDelegateApi = value
        }

    override fun onConnectionEvent(
        event: ConnectionEvent,
        data: Bundle?,
    ) {
        logger.d("onConnectionEvent: ${event.name}")
        when (event) {
            CallLifecycleEvent.IncomingConnectionReported -> {
                syncScreenWakelock()
            }

            CallLifecycleEvent.ConnectionStateChanged -> {
                handleCSReportConnectionStateChanged(data)
            }

            CallLifecycleEvent.ReplayIncomingCall -> {
                handleCSReplayIncomingCall(data)
            }

            CallLifecycleEvent.DeclineCall -> {
                handleCSReportDeclineCall(data)
            }

            CallLifecycleEvent.HungUp -> {
                handleCSReportDeclineCall(data)
            }

            CallLifecycleEvent.ConnectionNotFound -> {
                handleCSReportDeclineCall(data)
            }

            CallLifecycleEvent.AnswerCall -> {
                handleCSReportAnswerCall(data)
            }

            CallMediaEvent.AudioDeviceSet -> {
                handleCSReportAudioDeviceSet(data)
            }

            CallMediaEvent.AudioDevicesUpdate -> {
                handleCsReportAudioDevicesUpdate(data)
            }

            CallMediaEvent.AudioMuting -> {
                handleCSReportAudioMuting(data)
            }

            CallMediaEvent.ConnectionHolding -> {
                handleCSReportConnectionHolding(data)
            }

            CallMediaEvent.SentDTMF -> {
                handleCSReportSentDTMF(data)
            }

            else -> { /* per-call events handled by dynamic receivers in startCall() */ }
        }
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onCreate() {
        super.onCreate()
        logger.d("onCreate")
        core.addConnectionEventListener(this)
        isRunning = true
        // Connection-state replay is triggered from onDelegateSet() (the deterministic
        // "delegate ready" signal), not here: at onCreate the Flutter delegate is not yet
        // attached, so a replay fired now would only race the attach.
    }

    override suspend fun setUp(options: POptions) {
        logger.i("setUp")
        if (!TelephonyUtils.isTelecomSupported(baseContext)) {
            logger.i("setUp: Telecom cannot host our calls here (no android.software.telecom, or API below 26 where a self-managed PhoneAccount does not exist) — skipping phone account registration, using standalone call mode")
            applySetupOptions(options)
            return
        }
        registerPhoneAccountWithRetry()
        applySetupOptions(options)
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private suspend fun registerPhoneAccountWithRetry() {
        val maxAttempts = 5
        val retryDelayMs = 500L

        repeat(maxAttempts) { attempt ->
            try {
                TelephonyUtils(baseContext).registerPhoneAccount()
                logger.i("setUp: registerPhoneAccount succeeded${if (attempt > 0) " on attempt ${attempt + 1}" else ""}")
                return
            } catch (e: Exception) {
                if (attempt < maxAttempts - 1) {
                    logger.w("setUp: registerPhoneAccount failed (attempt ${attempt + 1}/$maxAttempts), retrying in ${retryDelayMs}ms: ${e.message}")
                    delay(retryDelayMs)
                } else {
                    logger.e("setUp: registerPhoneAccount failed after $maxAttempts attempts", e)
                    throw e
                }
            }
        }
    }

    private fun applySetupOptions(options: POptions) {
        runCatching {
            // Registers all necessary notification channels for the application.
            // This includes channels for active calls, incoming calls, missed calls, and foreground calls.
            NotificationChannelManager.registerNotificationChannels(baseContext)
        }.onFailure { Log.w("CallKeep", "Channel registration failed: ${it.message}", it) }

        runCatching {
            // Only persist a field when the caller explicitly provides a value.
            // A null option means "unspecified / leave as-is"; it must not overwrite a
            // previously persisted value on each setUp() call.
            options.android.ringtoneSound?.let { StorageDelegate.Sound.initRingtonePath(baseContext, it) }
            options.android.ringbackSound?.let { StorageDelegate.Sound.initRingbackPath(baseContext, it) }
            options.android.incomingCallFullScreen?.let { StorageDelegate.IncomingCall.setFullScreen(baseContext, it) }
            options.android.incomingCallTimeoutMs?.let { StorageDelegate.Timeout.setIncomingCallTimeoutMs(baseContext, it) }
            options.android.outgoingCallTimeoutMs?.let { StorageDelegate.Timeout.setOutgoingCallTimeoutMs(baseContext, it) }
            options.android.logFilePath?.let {
                StorageDelegate.Logging.setLogFilePath(baseContext, it)
                Log.setLogFilePath(it)
                logger.i("applySetupOptions: native logging initialized path=$it")
            }
        }.onFailure { Log.w("CallKeep", "Android options init failed: ${it.message}", it) }
    }

    override suspend fun startCall(
        callId: String,
        handle: PHandle,
        displayNameOrContactIdentifier: String?,
        video: Boolean,
        proximityEnabled: Boolean,
    ): PCallRequestError? =
        suspendCancellableCoroutine { continuation ->
            startCall(callId, handle, displayNameOrContactIdentifier, video, proximityEnabled, continuation)
        }

    /**
     * The outgoing-call handshake with :callkeep_core. It is resolved from a broadcast or a
     * timeout, never in line, so it takes the continuation of the suspended host call and
     * resumes it exactly once from whichever arrives first.
     */
    private fun startCall(
        callId: String,
        handle: PHandle,
        displayNameOrContactIdentifier: String?,
        video: Boolean,
        proximityEnabled: Boolean,
        continuation: CancellableContinuation<PCallRequestError?>,
    ) {
        val metadata =
            CallMetadata(
                callId = callId,
                handle = handle.toCallHandle(),
                displayName = displayNameOrContactIdentifier,
                hasVideo = video,
                proximityEnabled = proximityEnabled,
            )

        val logContext = "startCall($callId|$handle)"
        logger.i("$logContext: trying to start call")

        // Cancel any previous pending call for this callId before creating a new one.
        // This prevents duplicate receivers/timeouts if startCall() is invoked again with the same callId.
        pendingCallCleanupsByCallId.remove(callId)?.invoke()

        // Register as pending so answerCall/endCall can locate this call via the core shadow
        // before the outgoing connection is confirmed by ConnectionService.
        core.addPending(callId)

        // Each outgoing call owns its own receiver + AtomicBoolean so that the callback
        // and performStartCall are invoked exactly once, regardless of whether the
        // ConnectionService responds before or after the timeout fires.
        val handler = Handler(Looper.getMainLooper())
        val resolved = AtomicBoolean(false)
        var receiver: BroadcastReceiver? = null

        fun cancelResources() {
            handler.removeCallbacksAndMessages(null)
            // Guard against the window where the cleanup is invoked before receiver
            // is registered (i.e., between pendingCallCleanupsByCallId.put and registerConnectionPerformReceiver).
            receiver?.let {
                try {
                    core.unregisterConnectionEvents(baseContext, it)
                } catch (_: IllegalArgumentException) {
                }
            }
        }

        fun finish(result: Result<PCallRequestError?>) {
            if (!resolved.compareAndSet(false, true)) return
            pendingCallCleanupsByCallId.remove(callId)
            cancelResources()
            // Remove from pending regardless of outcome. On the success path (OngoingCall)
            // promote() has already removed the callId from pendingCallIds, so this is a
            // no-op. On failure/timeout paths the pending entry would otherwise linger until
            // tearDown(), causing drainUnconnectedPendingCallIds() to fire a spurious
            // performEndCall and routing answerCall() into the deferred-answer path.
            core.removePending(callId)
            continuation.resumeIfActive(result)
        }

        val callEventReceiver =
            object : BroadcastReceiver() {
                override fun onReceive(
                    context: Context?,
                    intent: Intent?,
                ) {
                    // Acquire resolution before any side effects so that a stale broadcast
                    // arriving after a timeout cannot trigger performStartCall or saveFailedOutgoingCall.
                    if (resolved.get()) return
                    when (intent?.action) {
                        CallLifecycleEvent.OngoingCall.name -> {
                            val callMetaData = CallMetadata.fromBundle(intent.extras ?: return)
                            if (callMetaData.callId != callId) return
                            logger.i("$logContext: ongoing call confirmed by CS")
                            // Outgoing call is now active in Telecom — promote from pending.
                            core.promote(callMetaData.callId, callMetaData, PCallkeepConnectionState.STATE_DIALING)
                            syncScreenWakelock()
                            val handle = callMetaData.handle
                            if (handle == null) {
                                // Should not happen for a confirmed outgoing call. Fail the request
                                // through the normal channel instead of crashing on handle!! or
                                // leaving a ghost call that Telecom shows but Flutter never learns of.
                                val error =
                                    InvalidCallMetadataException(
                                        "OngoingCall confirmed for ${callMetaData.callId} without a handle",
                                    )
                                logger.e("$logContext: ${error.message}")
                                saveFailedOutgoingCall(metadata, OutgoingFailureSource.CS_CALLBACK, error)
                                finish(Result.failure(error))
                                return
                            }
                            notifyFlutter("performStartCall") {
                                performStartCall(
                                    callMetaData.callId,
                                    handle.toPHandle(),
                                    // Pass the resolved label (display name or number), or null when
                                    // unknown; the pigeon contract is nullable and the Flutter client
                                    // decides how to render an unknown caller.
                                    callMetaData.name,
                                    callMetaData.hasVideo ?: false,
                                )
                            }
                            finish(Result.success(null))
                        }

                        CallLifecycleEvent.OutgoingFailure.name -> {
                            val failureMetaData = FailureMetadata.fromBundle(intent.extras ?: return)
                            if (failureMetaData.callMetadata?.callId != callId) return
                            logger.e("$logContext: CS reported failure: ${failureMetaData.outgoingFailureType}")
                            saveFailedOutgoingCall(
                                metadata,
                                OutgoingFailureSource.CS_CALLBACK,
                                failureMetaData.getThrowable(),
                            )
                            val result: Result<PCallRequestError?> =
                                when (failureMetaData.outgoingFailureType) {
                                    OutgoingFailureType.UNENTITLED -> {
                                        Result.failure(failureMetaData.getThrowable())
                                    }
                                }
                            finish(result)
                        }
                    }
                }
            }
        receiver = callEventReceiver

        core.registerConnectionEvents(
            baseContext,
            listOf(CallLifecycleEvent.OngoingCall, CallLifecycleEvent.OutgoingFailure),
            callEventReceiver,
            exported = false,
        )

        // Add cleanup AFTER receiver is registered to avoid UninitializedPropertyAccessException
        // if onDestroy() fires in the narrow window before receiver assignment.
        pendingCallCleanupsByCallId[callId] = {
            if (resolved.compareAndSet(false, true)) {
                cancelResources()
            }
        }

        handler.postDelayed({
            val exception = Exception("Overall timeout reached")
            logger.w("$logContext: timeout", exception)
            saveFailedOutgoingCall(metadata, OutgoingFailureSource.TIMEOUT, exception)
            finish(Result.success(PCallRequestError(PCallRequestErrorEnum.TIMEOUT)))
        }, OUTGOING_CALL_TIMEOUT_MS)

        try {
            // Suppress MissingPermission lint: self-managed PhoneAccount does not require
            // CALL_PHONE permission — the Telecom framework handles the call directly.
            @SuppressLint("MissingPermission")
            core.startOutgoingCall(metadata)
            logger.i("$logContext: startOutgoingCall dispatched")
        } catch (e: Exception) {
            logger.e("$logContext failed: ${e.javaClass.simpleName}: ${e.message}", e)
            saveFailedOutgoingCall(metadata, OutgoingFailureSource.DISPATCH_ERROR, e)
            finish(Result.success(PCallRequestError(PCallRequestErrorEnum.INTERNAL)))
        }
    }

    /**
     * Saves information about a failed outgoing call to an in-memory store for diagnostics.
     *
     * @param metadata The [CallMetadata] associated with the failed call attempt.
     * @param source The [OutgoingFailureSource] indicating where the failure was detected
     * (e.g., timeout, ConnectionService callback).
     * @param error The [Throwable] that caused the failure, if available. Its message is extracted for logging.
     */
    private fun saveFailedOutgoingCall(
        metadata: CallMetadata,
        source: OutgoingFailureSource,
        error: Throwable?,
    ) = failedCallsStore.add(metadata, source, error?.message)

    override suspend fun reportNewIncomingCall(
        callId: String,
        handle: PHandle,
        displayName: String?,
        hasVideo: Boolean,
    ): PIncomingCallError? {
        val metadata =
            CallMetadata(
                callId = callId,
                handle = handle.toCallHandle(),
                displayName = displayName,
                hasVideo = hasVideo,
                ringtonePath = StorageDelegate.Sound.getRingtonePath(baseContext),
            )
        val result = core.registerIncomingCall(metadata, this)
        if (result?.value == PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS_AND_ANSWERED) {
            // The backend already answered before this engine learned the call's offer.
            // Core adopted it; the bridge only delivers the Flutter-side answer effect.
            notifyFlutter("performAnswerCall") { performAnswerCall(callId) }
        }
        return result
    }

    override fun isSetUp(): Boolean = true

    override suspend fun tearDown(): Unit =
        suspendCancellableCoroutine { continuation ->
            tearDown(continuation)
        }

    /**
     * Session teardown. It completes on the TearDownComplete ack from :callkeep_core or on
     * the safety timeout, so it takes the continuation of the suspended host call and resumes
     * it from whichever arrives first.
     */
    private fun tearDown(continuation: CancellableContinuation<Unit>) {
        logger.i("tearDown")

        // Synchronously notify Flutter and clean up connections before returning.
        //
        // Why not rely on async HungUp broadcasts:
        //   connection.hungUp() sends an async HungUp broadcast that can arrive AFTER the
        //   next session's delegate is registered, causing stale performEndCall for the wrong callId.
        //
        // Why not send PhoneConnectionService.tearDown(baseContext):
        //   That enqueues a TearDown intent processed asynchronously. Its handleTearDown()
        //   calls cleanConnections() which can clear the next session's pendingCallIds,
        //   causing a concurrent reportNewIncomingCall to slip through a second time.
        //
        // Solution: fire performEndCall directly here, register each callId in
        // directNotifiedCallIds so the stale async HungUp broadcast is suppressed
        // in handleCSReportDeclineCall.
        // core.clear() at the end of tearDown handles all per-session state including
        // callback guards (directNotified, endCallDispatched).

        // Step 1: Collect active call IDs from the core shadow state (promoted connections).
        val activeCallIds = core.getAll().map { it.callId }

        // The session ends for every client, including push registrations. Core rejects
        // them and suppresses their later terminal broadcasts before pending calls are drained.
        core.endIncomingRegistrations()

        // Step 2: Drain pending calls that were registered with Telecom but whose
        // PhoneConnection was never created (no IncomingConnectionReported received yet).
        val unconnectedPending = core.drainUnconnectedPendingCallIds()

        // Step 3: Notify Flutter for active connections. Mark directNotified
        // BEFORE CallkeepCore/ConnectionService tears down the underlying connections so
        // that any async HungUp broadcast emitted during that teardown phase is suppressed.
        // Also mark terminated + endCallDispatched so that any endCall() arriving during
        // the tearDown window does not re-fire performEndCall or dispatch a duplicate
        // startHungUpCall IPC.
        activeCallIds.forEach { callId ->
            core.markDirectNotified(callId)
            core.clearAndMarkEndCallDispatched(callId)
            notifyFlutter("performEndCall") { performEndCall(callId) }
        }

        // Step 4: Notify Flutter for pending-only calls.
        // Mark in directNotified BEFORE firing performEndCall so that any async HungUp
        // broadcast from connection.hungUp() (Step 5) is suppressed — this happens when
        // the deferred-answer path caused CS to create a PhoneConnection via reserveAnswer
        // even though IncomingConnectionReported had not yet arrived and the callId was still pending.
        // Also mark terminated + endCallDispatched to match the onDestroy path and prevent
        // a duplicate startHungUpCall IPC if endCall() arrives during the tearDown window.
        unconnectedPending.forEach { callId ->
            core.markDirectNotified(callId)
            core.clearAndMarkEndCallDispatched(callId)
            notifyFlutter("performEndCall") { performEndCall(callId) }
        }

        if (activeCallIds.isNotEmpty() || unconnectedPending.isNotEmpty()) {
            notifyFlutter("didDeactivateAudioSession") { didDeactivateAudioSession() }
        }

        // Step 5: Send TearDownConnections command to :callkeep_core via startService.
        // PhoneConnectionService will call hungUp() on all its PhoneConnections,
        // cleanConnections(), and reply with TearDownComplete.
        // We wait for the ack (or a short timeout) before resetting tracker state
        // so that the next session is not started with stale connection objects.

        // Cancel any in-progress tearDown from a previous invocation before setting up a new one.
        tearDownTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        tearDownAckReceiver?.let {
            runCatching {
                core.unregisterConnectionEvents(baseContext, it)
            }
        }

        val tearDownResolved = AtomicBoolean(false)

        fun finishTearDown() {
            if (!tearDownResolved.compareAndSet(false, true)) return
            tearDownTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
            tearDownTimeoutRunnable = null
            tearDownAckReceiver?.let {
                runCatching {
                    core.unregisterConnectionEvents(baseContext, it)
                }
            }
            tearDownAckReceiver = null
            // Step 6: Reset tracker state for the next session.
            core.clear()
            syncScreenWakelock()
            // Keep PhoneConnectionService alive for the next session so that its next
            // incoming intents (e.g. AnswerCall) arrive at a live service instance.
            core.tearDownService()
            continuation.resumeIfActive(Result.success(Unit))
        }

        val ackReceiver =
            object : BroadcastReceiver() {
                override fun onReceive(
                    context: Context?,
                    intent: Intent?,
                ) {
                    if (intent?.action == CallCommandEvent.TearDownComplete.name) {
                        logger.d("tearDown: received TearDownComplete ack")
                        finishTearDown()
                    }
                }
            }
        tearDownAckReceiver = ackReceiver

        core.registerConnectionEvents(
            baseContext,
            listOf(CallCommandEvent.TearDownComplete),
            ackReceiver,
            exported = false,
        )

        // Safety timeout: if TearDownComplete never arrives (e.g. CS was not running),
        // proceed anyway so tearDown() always resolves.
        val timeoutRunnable =
            Runnable {
                logger.w("tearDown: TearDownComplete ack timed out, proceeding")
                finishTearDown()
            }
        tearDownTimeoutRunnable = timeoutRunnable
        mainHandler.postDelayed(timeoutRunnable, TEAR_DOWN_ACK_TIMEOUT_MS)

        core.sendTearDownConnections()
    }

    // Only for iOS, not used in Android
    override suspend fun reportConnectingOutgoingCall(callId: String) {
        logger.i("reportConnectingOutgoingCall: callId=$callId")
    }

    override suspend fun reportConnectedOutgoingCall(callId: String) {
        logger.i("reportConnectedOutgoingCall: callId=$callId")
        val metadata = CallMetadata(callId = callId)
        core.startEstablishCall(metadata)
    }

    override suspend fun reportUpdateCall(
        callId: String,
        handle: PHandle?,
        displayName: String?,
        hasVideo: Boolean?,
        proximityEnabled: Boolean?,
    ) {
        logger.i("reportUpdateCall: callId=$callId")
        val metadata =
            CallMetadata(
                callId = callId,
                handle = handle?.toCallHandle(),
                displayName = displayName,
                hasVideo = hasVideo,
                proximityEnabled = proximityEnabled,
            )
        core.startUpdateCall(metadata)
        syncScreenWakelock()
    }

    override suspend fun reportEndCall(
        callId: String,
        displayName: String,
        reason: PEndCallReason,
    ) {
        logger.i("reportEndCall: callId=$callId, reason=$reason")
        core.reportCallEnded(CallMetadata(callId = callId, displayName = displayName), reason.value)
    }

    override suspend fun answerCall(callId: String): PCallRequestError? {
        val metadata = CallMetadata(callId = callId)
        // IncomingConnectionReported is delivered via sendBroadcast() which is async. Between the
        // moment CS creates the PhoneConnection and the moment the broadcast reaches
        // ForegroundService, core.exists() is false even though the call is live on the
        // CS side. Resolution order:
        //   1. AnswerImmediately -> promoted, answer via IPC immediately.
        //   2. DeferAnswer       -> PhoneConnection not yet created, defer via ReserveAnswer.
        //   3. NotFound          -> unknown call, return error.
        return when (core.routeAnswerCall(callId)) {
            is AnswerCallRoute.AnswerImmediately -> {
                logger.i("answerCall $callId: connection exists in core shadow, answering immediately.")
                core.startAnswerCall(metadata)
                null
            }

            is AnswerCallRoute.DeferAnswer -> {
                // Telecom accepted the call but CS has not yet created the PhoneConnection.
                // Reserve the answer in the core shadow and send a ReserveAnswer command to CS so
                // onCreateIncomingConnection can apply it immediately on the :callkeep_core side.
                logger.i("answerCall $callId: pending in core shadow, CS has no connection yet, deferring answer.")
                core.reserveAnswer(callId)
                core.sendReserveAnswer(callId)
                null
            }

            is AnswerCallRoute.NotFound -> {
                logger.e("answerCall: no connection or pending entry for callId=$callId in core shadow or CS")
                PCallRequestError(PCallRequestErrorEnum.INTERNAL)
            }
        }
    }

    override suspend fun endCall(callId: String): PCallRequestError? {
        logger.i("endCall $callId.")

        core.appEndingCall(callId)

        if (core.isTerminated(callId)) {
            // Re-fire performEndCall only on the first endCall for a Telecom-terminated call
            // (e.g. onCreateIncomingConnectionFailed fired before the Dart callback was registered).
            // markEndCallDispatched guards against a second explicit endCall() re-firing the event
            // and inflating the delegate's endCallIds count.
            val isFirstEndCall = core.markEndCallDispatched(callId)
            if (isFirstEndCall) {
                logger.w("endCall: $callId terminated by Telecom before endCall was dispatched — re-notifying Flutter.")
                notifyFlutter("performEndCall") { performEndCall(callId) }
            } else {
                logger.w(
                    "endCall: $callId already terminated and endCall was already dispatched — returning error without re-notifying.",
                )
            }
            return PCallRequestError(PCallRequestErrorEnum.UNKNOWN_CALL_UUID)
        }
        core.markEndCallDispatched(callId)
        val metadata = CallMetadata(callId = callId)
        core.startHungUpCall(metadata)
        return null
    }

    override suspend fun sendDTMF(
        callId: String,
        key: String,
    ): PCallRequestError? {
        logger.i("sendDTMF: callId=$callId, key=$key")
        val metadata = CallMetadata(callId = callId, dualToneMultiFrequency = key.getOrNull(0))
        core.startSendDtmfCall(metadata)
        return null
    }

    override suspend fun setMuted(
        callId: String,
        muted: Boolean,
    ): PCallRequestError? {
        logger.i("setMuted: callId=$callId, muted=$muted")
        val metadata = CallMetadata(callId = callId, hasMute = muted)
        core.startMutingCall(metadata)
        return null
    }

    override suspend fun setHeld(
        callId: String,
        onHold: Boolean,
    ): PCallRequestError? {
        logger.i("setHeld: callId=$callId, onHold=$onHold")
        if (core.isGrouped(callId)) {
            // A member of a group is never held on its own; see PCallRequestErrorEnum.CALL_IS_GROUPED.
            logger.i("setHeld: $callId is in a call group, refusing")
            return PCallRequestError(PCallRequestErrorEnum.CALL_IS_GROUPED)
        }
        val metadata = CallMetadata(callId = callId, hasHold = onHold)
        core.startHoldingCall(metadata)
        return null
    }

    override suspend fun setSpeaker(
        callId: String,
        enabled: Boolean,
    ): PCallRequestError? {
        logger.i("setSpeaker: callId=$callId, enabled=$enabled")
        val metadata = CallMetadata(callId = callId, hasSpeaker = enabled)
        core.startSpeaker(metadata)
        return null
    }

    override suspend fun setAudioDevice(
        callId: String,
        device: PAudioDevice,
    ): PCallRequestError? {
        logger.i("setAudioDevice: callId=$callId, device=$device")
        val metadata =
            CallMetadata(
                callId = callId,
                audioDevice = device.toAudioDevice(),
            )
        core.setAudioDevice(metadata)
        return null
    }

    /**
     * A grouping request's outcome, as a pigeon answer. Grouping is presentation either way, so
     * a refusal is never a reason to end a call; it is explicit rather than a silent success so
     * the caller can tell that the system presentation does not match the call state it holds.
     */
    private fun callGroupResult(outcome: CallGroupOutcome): PCallRequestError? =
        when (outcome) {
            CallGroupOutcome.ACCEPTED -> null
            CallGroupOutcome.NOT_SUPPORTED -> PCallRequestError(PCallRequestErrorEnum.CALL_GROUPING_NOT_SUPPORTED)
            CallGroupOutcome.LIMIT_REACHED -> PCallRequestError(PCallRequestErrorEnum.MAXIMUM_CALL_GROUPS_REACHED)
        }

    override suspend fun setCallGroup(
        groupId: String,
        callIds: List<String>,
    ): PCallRequestError? {
        logger.i("setCallGroup: groupId=$groupId, callIds=$callIds")
        return callGroupResult(core.startSetCallGroup(groupId, callIds))
    }

    override suspend fun unsetCallGroup(callIds: List<String>): PCallRequestError? {
        logger.i("unsetCallGroup: callIds=$callIds")
        return callGroupResult(core.startUnsetCallGroup(callIds))
    }

    // --------------------------------
    // Handlers for ConnectionService reports to communicate with the Flutter side
    // --------------------------------
    //

    private fun syncScreenWakelock() {
        val hasVideo = core.getAll().any { it.hasVideo == true }
        if (hasVideo) {
            activityWakelockManager.acquireScreenWakeLock()
        } else {
            activityWakelockManager.releaseScreenWakeLock()
        }
    }

    /**
     * Notify the Flutter delegate of an incoming call via the public `didPresentIncomingCall` callback.
     * The single delivery point to the foreground delegate, used by the connection-state replay
     * ([handleCSReplayIncomingCall]) to seed a freshly attached delegate. A call already terminated
     * in the main-process tracker is skipped (see below); otherwise delivery is unconditional: the
     * Dart CallBloc deduplicates by callId, so re-delivering a call the app already knows about
     * (e.g. from signaling) does not create a second ActiveCall.
     */
    private fun deliverIncomingToDelegate(
        metadata: CallMetadata,
        confirmsHandoff: Boolean = true,
    ) {
        if (core.isTerminated(metadata.callId)) {
            // The call was already reported ended in the main process (e.g. a signaling hangup
            // arrived while the connection-state replay was still in flight from :callkeep_core).
            // Delivering it now would seed a ghost incoming call into CallBloc for a dead call.
            logger.w("deliverIncomingToDelegate: callId=${metadata.callId} already terminated; skipping seed")
            return
        }
        val handle = metadata.handle
        if (handle == null) {
            // Cannot build a PHandle without a number; skip rather than crash on a
            // malformed/handle-less broadcast (the call is already promoted in the tracker).
            logger.w("deliverIncomingToDelegate: missing handle for callId=${metadata.callId}; skipping didPresentIncomingCall")
            return
        }
        logger.i("deliverIncomingToDelegate: delivering incoming callId=${metadata.callId} to delegate")
        notifyFlutter("didPresentIncomingCall", onSuccess = { if (confirmsHandoff) confirmHandoff(metadata.callId) }) {
            didPresentIncomingCall(
                handleArg = handle.toPHandle(),
                displayNameArg = metadata.displayName,
                videoArg = metadata.hasVideo ?: false,
                callIdArg = metadata.callId,
                errorArg = null,
            )
        }
    }

    /**
     * The delegate has taken [callId]: this engine holds the call from here on. The push session
     * that presented it, if still up, is told so and finishes; nothing else is a confirmation - an
     * Activity on screen or a connected WebSocket says nothing about who receives the call's
     * events.
     */
    private fun confirmHandoff(callId: String) {
        if (!IncomingCallService.isRunning) return
        logger.i("confirmHandoff: the delegate holds $callId, the push session is done with it")
        IncomingCallService.release(baseContext, callId, IncomingCallRelease.IC_RELEASE_HANDED_OVER)
    }

    /**
     * Mirror the authoritative connection state carried by ConnectionStateChanged
     * (PhoneConnection.onStateChanged in :callkeep_core, or StandaloneCallService) into the shadow
     * state. Live states only; terminal DISCONNECTED is owned by the cause-carrying HungUp/DeclineCall
     * path (handleCSReportDeclineCall -> markTerminated), so it is ignored here.
     */
    private fun handleCSReportConnectionStateChanged(extras: Bundle?) {
        extras?.let {
            val metadata = CallMetadata.fromBundle(it)
            val state = metadata.connectionState ?: return@let
            if (state == CallConnectionState.DISCONNECTED) return@let
            logger.d("handleCSReportConnectionStateChanged: callId=${metadata.callId} state=$state")
            core.updateState(metadata.callId, state)
        }
    }

    /**
     * Deliver a still-ringing incoming call to the (freshly attached) Flutter delegate. This is the
     * sole foreground delivery of an incoming call: triggered by
     * [com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent.ReplayIncomingCall] from
     * [com.webtrit.callkeep.services.services.connection.PhoneConnectionService.handleReplayConnectionStates]
     * on delegate attach (e.g. a push->foreground isolate handoff or hot restart). The delegate that
     * received the original report is gone, so the new one must be seeded. A duplicate is harmless --
     * the Flutter CallBloc deduplicates by callId and enriches the existing entry with the signaling
     * offer when it arrives.
     */
    private fun handleCSReplayIncomingCall(extras: Bundle?) {
        logger.d("handleCSReplayIncomingCall")
        // A call the incoming-call service hands to the app is only presented: no push session
        // ran for it, and a handoff release would end the ringing phase of a call the user has
        // not answered yet - the notification is the app's call UI while it is in the background.
        extras?.let {
            deliverIncomingToDelegate(CallMetadata.fromBundle(it), confirmsHandoff = !it.getBoolean(PRESENT_ONLY))
        }
    }

    private fun handleCSReportDeclineCall(extras: Bundle?) {
        logger.d("handleCSReportDeclineCall")
        extras?.let {
            val callMetaData = CallMetadata.fromBundle(it)
            val callId = callMetaData.callId

            // Mark terminated and record that performEndCall is being dispatched now,
            // so that a subsequent endCall() call with isTerminated=true does NOT
            // re-fire performEndCall. Without this, if onCreateIncomingConnectionFailed
            // fires a HungUp broadcast while the call is still in the pending window
            // (before Dart calls endCall), the broadcast fires performEndCall once here
            // AND the endCall re-fire path fires it a second time — producing a duplicate
            // delegate callback.
            core.clearAndMarkEndCallDispatched(callId)
            syncScreenWakelock()

            notifyFlutter("performEndCall") { performEndCall(callId) }
            notifyFlutter("didDeactivateAudioSession") { didDeactivateAudioSession() }

            if (Platform.isLockScreen(baseContext) && isLastCall(callId)) {
                ActivityHolder.finish()
            }
        }
    }

    /**
     * True when no call other than [endedCallId] is still live.
     *
     * The activity on the lock screen shows every call, not one: sending it back when any call
     * ends took the screen away from a call still ringing (a second incoming call refused by
     * Telecom while the first rang). A refused call was never registered, so it never counts; a
     * call reported to Telecom but not yet connected (pending) does, since its screen is on the way.
     */
    internal fun isLastCall(endedCallId: String): Boolean = core.getAll().none { it.callId != endedCallId } && core.getPendingCallIds().none { it != endedCallId }

    private fun handleCSReportAnswerCall(extras: Bundle?) {
        logger.d("handleCSReportAnswerCall")
        extras?.let {
            val callMetaData = CallMetadata.fromBundle(it)
            // Consume any deferred answer reservation (set by the answerCall deferred path).
            // This mirrors ConnectionManager.consumeAnswer so pendingAnswers does not leak.
            core.consumeAnswer(callMetaData.callId)
            // Update tracker: call has been answered.
            core.markAnswered(callMetaData.callId)
            notifyFlutter("didActivateAudioSession") { didActivateAudioSession() }

            if (IncomingCallService.isRunning) {
                // Push-notification path: tell the background isolate to release its
                // signaling WebSocket. ActivityHolder.start() already fired from
                // PhoneConnection.onAnswer() in :callkeep_core.
                IncomingCallService.release(baseContext, callMetaData.callId, IncomingCallRelease.IC_RELEASE_HANDED_OVER)
            }
            notifyFlutter("performAnswerCall") { performAnswerCall(callMetaData.callId) }
        }
    }

    private fun handleCSReportAudioDeviceSet(extras: Bundle?) {
        logger.d("handleCSReportAudioDeviceSet")
        extras?.let {
            val callMetaData = CallMetadata.fromBundle(it)
            val audioDevice =
                callMetaData.audioDevice ?: run {
                    logger.w("handleCSReportAudioDeviceSet: audioDevice not set for callId=${callMetaData.callId}")
                    return
                }
            notifyFlutter("performAudioDeviceSet") {
                performAudioDeviceSet(
                    callMetaData.callId,
                    audioDevice.toPAudioDevice(),
                )
            }
        }
    }

    private fun handleCsReportAudioDevicesUpdate(extras: Bundle?) {
        logger.d("handleCsReportAudioDevicesUpdate")
        extras?.let {
            val callMetaData = CallMetadata.fromBundle(it)
            notifyFlutter("performAudioDevicesUpdate") {
                performAudioDevicesUpdate(
                    callMetaData.callId,
                    callMetaData.audioDevices.map { audioDevice -> audioDevice.toPAudioDevice() },
                )
            }
        }
    }

    private fun handleCSReportAudioMuting(extras: Bundle?) {
        logger.d("handleCSReportAudioMuting")
        extras?.let {
            val callMetaData = CallMetadata.fromBundle(it)
            notifyFlutter("performSetMuted") {
                performSetMuted(
                    callMetaData.callId,
                    callMetaData.hasMute ?: false,
                )
            }
        }
    }

    private fun handleCSReportConnectionHolding(extras: Bundle?) {
        logger.d("handleCSReportConnectionHolding")
        extras?.let {
            val callMetaData = CallMetadata.fromBundle(it)
            val onHold = callMetaData.hasHold ?: false
            // The HOLDING / ACTIVE shadow state is mirrored from the real connection via
            // ConnectionStateChanged (onStateChanged for Telecom; explicit emit from StandaloneCallService),
            // so this handler only relays the hold action to Flutter.
            notifyFlutter("performSetHeld") { performSetHeld(callMetaData.callId, onHold) }
        }
    }

    private fun handleCSReportSentDTMF(extras: Bundle?) {
        logger.d("handleCSReportSentDTMF")
        extras?.let {
            val callMetaData = CallMetadata.fromBundle(it)
            notifyFlutter("performSendDTMF") {
                performSendDTMF(
                    callMetaData.callId,
                    callMetaData.dualToneMultiFrequency.toString(),
                )
            }
        }
    }

    /**
     * Callback triggered from the Flutter side when the delegate is set.
     *
     * This method is invoked when the Flutter application is ready to receive events from the native side.
     * It checks for any existing active connections (calls) and restores their state on the Flutter side.
     * This is crucial for re-synchronizing the UI after a hot restart or when the app comes to the
     * foreground and re-establishes its communication channel with this service.
     */
    override fun onDelegateSet() {
        logger.d("onDelegateSet: Flutter delegate attached. Replaying connection state...")
        isDelegateReady = true

        // Replay the current connection lifecycle now that the delegate is attached and GUARANTEED
        // to receive the re-fired events. This is the single replay trigger: it fires only once the
        // Flutter delegate is ready (so re-delivery is not raced/dropped) and on every attach,
        // including a warm engine re-attach. It is deliberately NOT gated on the local tracker
        // below: in a push->foreground handoff the main process has no record of the call yet --
        // the replay from :callkeep_core is exactly what surfaces it to the freshly attached engine.
        core.replayConnectionStates()

        // Ask :callkeep_core to re-emit audio state (device + mute) for any active connections.
        // PhoneConnection.forceUpdateAudioState() runs in the :callkeep_core process and sends
        // CallMediaEvent broadcasts back to the main process, which updates the Flutter UI.
        // Not gated on the main-process tracker: handleReplayAudioState() iterates the live
        // :callkeep_core connections, so it is already a no-op when there are none -- and the
        // local tracker is transiently empty right after the replay above (and during a
        // push->foreground handoff), which would otherwise skip the re-sync exactly when needed.
        core.replayAudioState()
    }

    /** The app removed its delegate: a call arriving now goes to a push session. */
    override fun onDelegateCleared() {
        logger.d("onDelegateCleared: Flutter delegate removed")
        isDelegateReady = false
    }

    //
    // --------------------------------
    // Handlers for ConnectionService reports to communicate with the Flutter side
    // --------------------------------

    override fun onUnbind(intent: Intent?): Boolean {
        logger.i("onUnbind")
        stopSelf()
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        logger.d("onDestroy")
        core.removeConnectionEventListener(this)
        isDelegateReady = false

        pendingCallCleanupsByCallId.values.toList().forEach { it() }
        pendingCallCleanupsByCallId.clear()

        // Destroying this bridge does not end the session or a push client's registration.
        core.detachIncomingClient(this)

        // Cancel any in-progress tearDown so the receiver and timeout do not outlive the service.
        tearDownTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        tearDownTimeoutRunnable = null
        tearDownAckReceiver?.let {
            runCatching {
                core.unregisterConnectionEvents(baseContext, it)
            }
        }
        tearDownAckReceiver = null

        activityWakelockManager.dispose()
        scope.cancel()
        // The group registry is not cleared here: this service is the activity's bridge and
        // goes with the activity, while the calls and their group live on in the backend.
        // The registry follows the calls, so it is emptied with the session in tearDown.

        // Phone account registration is tied to the user session, not the service lifecycle.
        // Unregistration happens only in finishTearDown() (explicit logout/tearDown call).
        // Removing it here ensures cold-start push calls work even if the service was killed.

        isRunning = false
    }

    inner class LocalBinder : Binder() {
        fun getService(): ForegroundService = this@ForegroundService
    }

    companion object {
        private const val TAG = "ForegroundService"

        private val logger = Log(TAG)

        val failedCallsStore = FailedCallsStore()

        var isRunning = false

        /**
         * The Flutter side has a delegate to take calls: set by onDelegateSet, cleared by
         * onDelegateCleared and onDestroy. A bound service is not enough - the app's call
         * handling may not be built yet.
         */
        @Volatile
        var isDelegateReady = false

        /** Extra on a [CallLifecycleEvent.ReplayIncomingCall]: present the call, confirm no handoff. */
        const val PRESENT_ONLY = "present_only"

        private const val OUTGOING_CALL_TIMEOUT_MS = 5_000L
        private const val TEAR_DOWN_ACK_TIMEOUT_MS = 3_000L

        /**
         * Process-wide facade for all interactions with the `:callkeep_core` process.
         *
         * Provides a single access point for both reading shadow connection state and
         * sending commands to [PhoneConnectionService]. After the process split, swap
         * [CallkeepCore.instance] to change the IPC strategy without touching call sites.
         */
        val core: CallkeepCore get() = CallkeepCore.instance
    }
}

/**
 * A thread-safe in-memory store for failed outgoing calls.
 *
 * This class provides a simple, volatile storage mechanism to log details about outgoing call
 * attempts that did not succeed. Since it uses a [ConcurrentHashMap], it is safe for use
 * across multiple threads.
 *
 * The store is in-memory only, meaning its contents are lost when the application process
 * is terminated. It is intended for short-term diagnostics and debugging rather than
 * persistent call logging.
 *
 */
class FailedCallsStore {
    private val logger = Log("FailedCallsStore")
    private val store = ConcurrentHashMap<String, FailedCallInfo>()

    fun add(
        metadata: CallMetadata,
        source: OutgoingFailureSource,
        reason: String?,
    ) {
        logger.w("add: callId=${metadata.callId}, source=$source, reason=$reason")
        val info =
            FailedCallInfo(
                callId = metadata.callId,
                metadata = metadata,
                source = source,
                reason = reason,
            )
        store[metadata.callId] = info
    }

    fun getAll(): List<FailedCallInfo> = store.values.toList().sortedByDescending { it.timestamp }
}
