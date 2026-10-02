package com.webtrit.callkeep.services.core

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.annotation.RequiresPermission
import com.webtrit.callkeep.PCallkeepConnection
import com.webtrit.callkeep.PCallkeepConnectionState
import com.webtrit.callkeep.PEndCallReasonEnum
import com.webtrit.callkeep.PIncomingCallError
import com.webtrit.callkeep.PIncomingCallErrorEnum
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.common.Log
import com.webtrit.callkeep.common.PendingBroadcastQueue
import com.webtrit.callkeep.models.CallConnectionState
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.models.FailureMetadata
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.broadcaster.CallMediaEvent
import com.webtrit.callkeep.services.broadcaster.ConnectionEvent
import com.webtrit.callkeep.services.broadcaster.ConnectionServicePerformBroadcaster
import com.webtrit.callkeep.services.services.connection.ConnectionManager
import com.webtrit.callkeep.services.services.connection.PhoneConnectionService
import com.webtrit.callkeep.services.services.incoming_call.IncomingCallService
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicBoolean

/**
 * In-process implementation of [CallkeepCore].
 *
 * - **State** is delegated to [MainProcessConnectionTracker] (shadow registry in the main process).
 * - **Commands** are routed through [CallServiceRouter], which selects between
 *   [com.webtrit.callkeep.services.services.connection.PhoneConnectionService] (Telecom path)
 *   and [com.webtrit.callkeep.services.services.connection.StandaloneCallService] (no-Telecom path).
 *
 * All call sites are unaware of which backend is active — routing is entirely internal to [CallServiceRouter].
 */
class InProcessCallkeepCore internal constructor(
    private val tracker: ConnectionTracker = MainProcessConnectionTracker.instance,
    routerInit: () -> CallServiceRouter = { CallServiceRouter(ContextHolder.context) },
) : CallkeepCore {
    // The context is read per call (not at construction time) so the singleton can be
    // created early without risking a NullPointerException. ContextHolder.init() must
    // have been called before any CS command method is invoked (guaranteed by Application.onCreate).
    private val context get() = ContextHolder.context

    private val router: CallServiceRouter by lazy(routerInit)

    // -------------------------------------------------------------------------
    // Listener registry and lazy global BroadcastReceiver
    // -------------------------------------------------------------------------

    private val listeners = CopyOnWriteArrayList<ConnectionEventListener>()
    private var globalReceiver: BroadcastReceiver? = null
    private val receiverLock = Any()

    // Tracks per-call receivers registered via registerConnectionEvents so that
    // notifyConnectionEvent can deliver events in-process without going through AMS.
    private val inProcessReceivers = ConcurrentHashMap<BroadcastReceiver, List<String>>()

    override fun addConnectionEventListener(listener: ConnectionEventListener) {
        listeners.add(listener)
        ensureReceiving()
    }

    override fun removeConnectionEventListener(listener: ConnectionEventListener) {
        // The receiver stays: the calls, and the state the core keeps for them, outlive the
        // listeners - the foreground service goes with the activity - and a call that ends
        // meanwhile still has to reach the tracker. Registration handling and terminal-state tracking stay in the core.
        listeners.remove(listener)
    }

    /**
     * Registers the global receiver once. It is needed from the first listener, and from the
     * first call the tracker learns about, since a call may end while nobody is listening.
     */
    private fun ensureReceiving() {
        synchronized(receiverLock) {
            if (globalReceiver == null) {
                globalReceiver =
                    createGlobalReceiver().also { receiver ->
                        ConnectionServicePerformBroadcaster.registerConnectionPerformReceiver(
                            GLOBAL_LISTENER_EVENTS,
                            context,
                            receiver,
                            exported = false,
                        )
                    }
            }
        }
    }

    private fun createGlobalReceiver(): BroadcastReceiver =
        object : BroadcastReceiver() {
            override fun onReceive(
                ctx: Context?,
                intent: Intent?,
            ) {
                val action = intent?.action ?: return
                val event = GLOBAL_LISTENER_EVENTS.find { it.name == action } ?: return
                deliverConnectionEvent(event, intent.extras)
            }
        }

    /** Registration transitions always precede observers and never depend on a UI bridge. */
    private fun deliverConnectionEvent(
        event: ConnectionEvent,
        data: Bundle?,
    ) {
        if (consumeRegistrationEvent(event, data)) return
        listeners.forEach { it.onConnectionEvent(event, data) }
    }

    /** True when a terminal event only rejected an unpresented call or was already notified. */
    private fun consumeRegistrationEvent(
        event: ConnectionEvent,
        data: Bundle?,
    ): Boolean {
        val callId = data?.let { callIdOf(event, it) } ?: return false
        // Dart declines a failed registration without adding the call. Once that outcome
        // is final, neither replay nor a late Telecom answer can recreate just the native half.
        if (wasEndedWithoutFlutterState(callId)) {
            when (event) {
                CallLifecycleEvent.IncomingConnectionReported,
                CallLifecycleEvent.AnswerCall,
                CallLifecycleEvent.ReplayIncomingCall,
                -> {
                    cancelRejectedIncomingCall(callId)
                    return true
                }

                CallLifecycleEvent.ConnectionStateChanged -> {
                    val metadata = CallMetadata.fromBundle(data)
                    if (metadata.connectionState != CallConnectionState.DISCONNECTED) cancelRejectedIncomingCall(callId)
                    return true
                }

                else -> {
                    Unit
                }
            }
        }
        val registration = incomingRegistrations[callId]
        when (event) {
            CallLifecycleEvent.IncomingConnectionReported -> {
                // Raw dispatch clients (SMS) have no waiter, but still receive confirmation.
                // A host failure is final: Dart may already have declined the server call.
                if (isStaleIncomingConfirmation(callId)) return true
                val metadata = CallMetadata.fromBundle(data)
                val state =
                    if (isAnswered(callId) || getState(callId) == PCallkeepConnectionState.STATE_ACTIVE) {
                        PCallkeepConnectionState.STATE_ACTIVE
                    } else {
                        PCallkeepConnectionState.STATE_RINGING
                    }
                val promoteCall = {
                    if (!exists(callId)) promote(callId, metadata, state)
                    if (state == PCallkeepConnectionState.STATE_ACTIVE) markAnswered(callId)
                }
                if (registration != null) {
                    incomingRegistrations.complete(registration, Result.success(null), beforeAnswer = promoteCall)
                } else {
                    promoteCall()
                }
            }

            CallLifecycleEvent.AnswerCall -> {
                if (isStaleIncomingConfirmation(callId)) return true
                // A deferred answer replaces IncomingConnectionReported while registration
                // is still waiting. Confirmed push calls can also be answered without a bridge.
                val reported = CallMetadata.fromBundle(data)
                val metadata = registration?.metadata ?: get(callId)
                val answerCall = {
                    if (metadata != null) promote(callId, metadata.mergeWith(reported), PCallkeepConnectionState.STATE_ACTIVE)
                    markAnswered(callId)
                }
                if (registration != null) {
                    incomingRegistrations.complete(registration, Result.success(null), beforeAnswer = answerCall)
                } else {
                    answerCall()
                }
                // Keep the real event for the bridge's single Flutter notification.
            }

            CallLifecycleEvent.IncomingFailure -> {
                if (registration != null) {
                    rejectIncomingRegistration(registration, "Telecom refused registration")
                } else if (isPending(callId)) {
                    // A dispatch-only SMS registration still owns a pending reservation.
                    rejectUnconfirmedIncomingCall(callId)
                }
            }

            in TERMINAL_EVENTS -> {
                if (consumeDirectNotified(callId) || incomingRegistrations.wasRejected(callId)) return true
                if (registration != null) {
                    rejectIncomingRegistration(registration, "ended before confirmation")
                    return true
                }
                // Connected-call UI effects still belong to the existing bridge. Without one,
                // the shadow state and groups must follow the backend's terminal event anyway.
                if (listeners.none { it is CallEndListener }) tracker.markTerminated(callId)
            }

            else -> {
                Unit
            }
        }
        return false
    }

    private fun isStaleIncomingConfirmation(callId: String): Boolean =
        incomingRegistrations.wasRejected(callId) ||
            (isTerminated(callId) && getState(callId) == PCallkeepConnectionState.STATE_DISCONNECTED)

    private fun callIdOf(
        event: ConnectionEvent,
        data: Bundle,
    ): String? =
        if (event == CallLifecycleEvent.IncomingFailure) {
            FailureMetadata.fromBundle(data).callMetadata?.callId
        } else {
            CallMetadata.fromBundleOrNull(data)?.callId
        }

    // -------------------------------------------------------------------------
    // State queries
    // -------------------------------------------------------------------------

    override fun exists(callId: String): Boolean = tracker.exists(callId)

    override fun isPending(callId: String): Boolean = tracker.isPending(callId)

    override fun isTerminated(callId: String): Boolean = tracker.isTerminated(callId)

    override fun isAnswered(callId: String): Boolean = tracker.isAnswered(callId)

    override fun checkIncomingDuplicate(callId: String): PIncomingCallError? =
        when {
            tracker.isAnswered(callId) -> PIncomingCallError(PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS_AND_ANSWERED)
            tracker.exists(callId) -> PIncomingCallError(PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS)
            else -> null
        }

    override fun routeAnswerCall(callId: String): AnswerCallRoute =
        when {
            tracker.exists(callId) -> AnswerCallRoute.AnswerImmediately
            tracker.isPending(callId) -> AnswerCallRoute.DeferAnswer
            else -> AnswerCallRoute.NotFound
        }

    override fun getAll(): List<CallMetadata> = tracker.getAll()

    override fun getPendingCallIds(): Set<String> = tracker.getPendingCallIds()

    override fun get(callId: String): CallMetadata? = tracker.get(callId)

    override fun getState(callId: String): PCallkeepConnectionState? = tracker.getState(callId)

    override fun toPCallkeepConnection(callId: String): PCallkeepConnection? = tracker.toPCallkeepConnection(callId)

    // -------------------------------------------------------------------------
    // State mutations
    // -------------------------------------------------------------------------

    override fun addPending(callId: String): Boolean {
        ensureReceiving()
        return tracker.addPending(callId)
    }

    override fun removePending(callId: String) = tracker.removePending(callId)

    override fun promote(
        callId: String,
        metadata: CallMetadata,
        state: PCallkeepConnectionState,
    ) {
        ensureReceiving()
        tracker.promote(callId, metadata, state)
    }

    override fun markAnswered(callId: String) = tracker.markAnswered(callId)

    override fun updateState(
        callId: String,
        state: CallConnectionState,
    ) = tracker.updateState(callId, state)

    override fun markTerminated(callId: String) {
        if (Looper.myLooper() != mainHandler.looper) {
            // The terminal fact is recorded on the calling thread, so nothing that reads the
            // tracker waits for the main looper. The registrations live on the main looper: a
            // registration still waiting on this call is rejected there, a moment later.
            tracker.markTerminated(callId)
            mainHandler.post { markTerminated(callId) }
            return
        }
        incomingRegistrations[callId]?.let {
            rejectIncomingRegistration(it, "app reported call ended")
            return
        }
        tracker.markTerminated(callId)
    }

    override fun reportCallEnded(
        metadata: CallMetadata,
        reason: PEndCallReasonEnum,
    ) {
        val callId = metadata.callId
        Log.i(TAG, "Call ended by the app: $callId ($reason)")
        // The push session reports from a Pigeon background thread (its reportEndCall is served
        // off the platform thread): on a cold start the main looper is busy for seconds and the
        // caller has already hung up. The facts below are recorded on the calling thread - the
        // tracker is a concurrent map and the router only starts a service - in an order that
        // holds against a registration of the same id running on the main looper at the same
        // time: the replay guard first, so a registration arriving between the lines already
        // sees a call that is never to be presented. What lives on the main looper is done there.
        // The app never presented this call, so a replay must not present it either. A call the
        // app did present (a transfer-back reuses one) stays eligible for a new registration.
        if (reason == PEndCallReasonEnum.MISSED_WHILE_CONNECTING) markEndedWithoutFlutterState(callId)
        // Terminated now, ahead of the DeclineCall echo from the backend: a late state replay for
        // this call is already suppressed, and a registration still waiting on it is rejected.
        markTerminated(callId)
        // The app knows this end: the backend's terminal event must not turn into a request to
        // end the call again, in this engine or in the push session's.
        tracker.markEndCallDispatched(callId)
        // An incoming-call service started for this call after its end would present a call that
        // is over: the pending release lets its launch end the call without showing it. A running
        // service has its receiver up and takes the IC_RELEASE_ENDED that follows directly; a
        // post for it would be an orphan entry, never consumed. The check is atomic against the
        // service's start only on the main looper, so that is where it runs.
        runOnMain {
            if (!IncomingCallService.isRunning) {
                PendingBroadcastQueue.post(PendingBroadcastQueue.incomingReleaseKey(callId))
            }
        }
        router.startDeclineCall(metadata)
    }

    private fun runOnMain(block: () -> Unit) {
        if (Looper.myLooper() == mainHandler.looper) block() else mainHandler.post(block)
    }

    override fun clearAndMarkEndCallDispatched(callId: String): Boolean {
        tracker.markTerminated(callId)
        // Remove the main-process ConnectionManager pending reservation so a subsequent
        // reportNewIncomingCall with the same callId (e.g. blind transfer-back) is not
        // permanently blocked by the stale pendingCallIds entry from the original registration.
        ConnectionManager.instance.removePending(callId)
        return tracker.markEndCallDispatched(callId)
    }

    override fun reserveAnswer(callId: String) = tracker.reserveAnswer(callId)

    override fun consumeAnswer(callId: String): Boolean = tracker.consumeAnswer(callId)

    override fun drainUnconnectedPendingCallIds(): Set<String> = tracker.drainUnconnectedPendingCallIds()

    override fun clear() {
        endIncomingRegistrations()
        incomingRegistrations.clearRejections()
        tracker.clear()
    }

    // -------------------------------------------------------------------------
    // Callback guards
    // -------------------------------------------------------------------------

    override fun markDirectNotified(callId: String) = tracker.markDirectNotified(callId)

    override fun consumeDirectNotified(callId: String): Boolean = tracker.consumeDirectNotified(callId)

    override fun markEndCallDispatched(callId: String): Boolean = tracker.markEndCallDispatched(callId)

    override fun markEndedWithoutFlutterState(callId: String) = tracker.markEndedWithoutFlutterState(callId)

    override fun wasEndedWithoutFlutterState(callId: String): Boolean = tracker.wasEndedWithoutFlutterState(callId)

    // -------------------------------------------------------------------------
    // Connection event receivers
    // -------------------------------------------------------------------------

    override fun registerConnectionEvents(
        context: Context,
        events: List<ConnectionEvent>,
        receiver: BroadcastReceiver,
        exported: Boolean,
    ): IntentFilter {
        inProcessReceivers[receiver] = events.map { it.name }
        return ConnectionServicePerformBroadcaster.registerConnectionPerformReceiver(events, context, receiver, exported)
    }

    override fun unregisterConnectionEvents(
        context: Context,
        receiver: BroadcastReceiver,
    ) {
        inProcessReceivers.remove(receiver)
        ConnectionServicePerformBroadcaster.unregisterConnectionPerformReceiver(context, receiver)
    }

    override fun notifyConnectionEvent(
        event: ConnectionEvent,
        data: Bundle?,
    ) {
        val actionName = event.name
        val intent = Intent(actionName).apply { data?.let { putExtras(it) } }

        deliverConnectionEvent(event, data)

        // Deliver to per-call dynamic receivers (OngoingCall, TearDownComplete, etc.)
        inProcessReceivers.entries.toList().forEach { (receiver, actions) ->
            if (actionName in actions) {
                receiver.onReceive(context, intent)
            }
        }
    }

    // -------------------------------------------------------------------------
    // CS commands
    // -------------------------------------------------------------------------

    @RequiresPermission(Manifest.permission.CALL_PHONE)
    override fun startOutgoingCall(metadata: CallMetadata) = router.startOutgoingCall(metadata)

    private fun dispatchIncomingCall(
        metadata: CallMetadata,
        onSuccess: () -> Unit,
        onError: (PIncomingCallError?) -> Unit,
        isCurrent: () -> Boolean = { true },
    ) {
        val callId = metadata.callId
        // Reserve before dispatch so answer/end can find the call while Telecom is creating it.
        // Callers of the same id already joined one registration; this guards the tracker itself.
        val addedPending = tracker.addPending(callId)
        if (!addedPending) {
            Log.w(TAG, "dispatchIncomingCall: callId=$callId already pending, rejecting concurrent duplicate")
            onError(PIncomingCallError(PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS))
            return
        }

        // From here on we own the pendingCallIds entry. Any failure must drain it so the
        // next reportNewIncomingCall for the same callId is not rejected as a stale duplicate.
        val drained = AtomicBoolean(false)

        fun drainOnce() {
            if (drained.compareAndSet(false, true)) {
                tracker.removePending(callId)
            }
        }

        try {
            router.startIncomingCall(
                metadata,
                onSuccess = onSuccess,
                onError = { err ->
                    if (isCurrent()) {
                        drainOnce()
                        onError(err)
                    }
                },
            )
        } catch (t: Throwable) {
            // Keep the original exception for Pigeon diagnostics. A late throw after a
            // synchronous confirmation must not drain a newer attempt with the same call id.
            if (isCurrent()) drainOnce()
            throw t
        }
    }

    // -------------------------------------------------------------------------
    // Incoming registration
    // -------------------------------------------------------------------------

    private val mainHandler = Handler(Looper.getMainLooper())

    private val incomingRegistrations: IncomingRegistrations by lazy {
        IncomingRegistrations(
            mainHandler,
            timeoutMs = { incomingRegistrationTimeoutMs(runCatching { context }.getOrNull()) },
        ) { registration ->
            rejectIncomingRegistration(registration, "confirmation timeout") {
                // Returning CALL_REJECTED_BY_SYSTEM makes Dart decline the server call and
                // omit ActiveCall. Cancel the backend too, before allowing Dart to continue.
                // This UUID was never presented, so a later report must not start it again.
                markEndedWithoutFlutterState(registration.callId)
                cancelRejectedIncomingCall(registration.callId)
            }
        }
    }

    override suspend fun registerIncomingCall(
        metadata: CallMetadata,
        client: Any,
    ): PIncomingCallError? {
        ensureReceiving()
        val callId = metadata.callId
        if (wasEndedWithoutFlutterState(callId)) {
            return PIncomingCallError(PIncomingCallErrorEnum.CALL_ID_ALREADY_TERMINATED)
        }
        checkIncomingDuplicate(callId)?.let { return adoptIncomingCall(metadata, it) }

        return incomingRegistrations.await(metadata, client) { registration ->
            try {
                dispatchIncomingCall(
                    metadata,
                    onSuccess = { Log.d(TAG, "Incoming call dispatched: $callId; waiting for confirmation") },
                    onError = { error ->
                        val duplicate =
                            error?.value == PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS ||
                                error?.value == PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS_AND_ANSWERED
                        if (duplicate) {
                            // A prior dispatch-only report (SMS) or a cold-start connection can
                            // already exist in the backend. Adoption belongs to the core too.
                            val result = adoptIncomingCall(metadata, error)
                            incomingRegistrations.complete(registration, Result.success(result))
                        } else {
                            incomingRegistrations.complete(
                                registration,
                                Result.success(error ?: PIncomingCallError(PIncomingCallErrorEnum.INTERNAL)),
                                rejected = true,
                            ) {
                                clearAndMarkEndCallDispatched(callId)
                                markDirectNotified(callId)
                            }
                        }
                    },
                    isCurrent = { incomingRegistrations.isCurrent(registration) },
                )
            } catch (error: Throwable) {
                // No orphan timer after a synchronous dispatch failure; joined callers learn
                // the same exception and a retry receives a fresh operation and deadline.
                incomingRegistrations.complete(registration, Result.failure(error), rejected = true) {
                    clearAndMarkEndCallDispatched(callId)
                    markDirectNotified(callId)
                }
            }
        }
    }

    private fun adoptIncomingCall(
        metadata: CallMetadata,
        error: PIncomingCallError,
    ): PIncomingCallError {
        val callId = metadata.callId
        val answered =
            error.value == PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS_AND_ANSWERED ||
                getState(callId) == PCallkeepConnectionState.STATE_ACTIVE
        if (answered) {
            promote(callId, metadata, PCallkeepConnectionState.STATE_ACTIVE)
            markAnswered(callId)
            return PIncomingCallError(PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS_AND_ANSWERED)
        }
        if (!exists(callId)) promote(callId, metadata, PCallkeepConnectionState.STATE_RINGING)
        return error
    }

    override fun endIncomingRegistrations() {
        incomingRegistrations.snapshot().forEach { rejectIncomingRegistration(it, "session ended") }
    }

    override fun detachIncomingClient(client: Any) {
        incomingRegistrations.snapshot().filter { incomingRegistrations.hasClient(it, client) }.forEach { registration ->
            if (incomingRegistrations.hasOtherClients(registration, client)) {
                incomingRegistrations.detach(registration, client)
            } else {
                rejectIncomingRegistration(registration, "client detached")
            }
        }
    }

    override fun appEndingCall(callId: String) {
        incomingRegistrations[callId]?.let { incomingRegistrations.complete(it, Result.success(null)) }
    }

    private fun rejectUnconfirmedIncomingCall(callId: String) {
        incomingRegistrations.markRejected(callId)
        clearAndMarkEndCallDispatched(callId)
        markDirectNotified(callId)
    }

    private fun rejectIncomingRegistration(
        registration: IncomingRegistrations.Registration,
        reason: String,
        beforeAnswer: () -> Unit = {},
    ): Boolean =
        incomingRegistrations.complete(
            registration,
            Result.success(PIncomingCallError(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM)),
            rejected = true,
        ) {
            Log.i(TAG, "Incoming registration rejected: ${registration.callId} ($reason)")
            clearAndMarkEndCallDispatched(registration.callId)
            markDirectNotified(registration.callId)
            beforeAnswer()
        }

    private fun cancelRejectedIncomingCall(callId: String) {
        // A failed service start must not strand the host continuation. A late lifecycle
        // event proves the backend is reachable again and retries this idempotent command.
        runCatching { router.cancelIncomingCall(callId) }
            .onFailure { Log.w(TAG, "Could not cancel rejected incoming call $callId", it) }
    }

    override fun startAnswerCall(metadata: CallMetadata) = router.startAnswerCall(metadata)

    override fun startDeclineCall(metadata: CallMetadata) = router.startDeclineCall(metadata)

    override fun startHungUpCall(metadata: CallMetadata) = router.startHungUpCall(metadata)

    override fun startEstablishCall(metadata: CallMetadata) = router.startEstablishCall(metadata)

    override fun startUpdateCall(metadata: CallMetadata) {
        tracker.updateMetadata(metadata)
        router.startUpdateCall(metadata)
    }

    override fun startSendDtmfCall(metadata: CallMetadata) = router.startSendDtmfCall(metadata)

    override fun startMutingCall(metadata: CallMetadata) = router.startMutingCall(metadata)

    override fun startHoldingCall(metadata: CallMetadata) = router.startHoldingCall(metadata)

    override fun startSetCallGroup(
        groupId: String,
        callIds: List<String>,
    ): CallGroupOutcome {
        // One group at a time on both backends. A second name while another group is live is
        // refused and nothing changes; the name is kept with the membership so the next request
        // can be told apart. The backends themselves keep only the membership.
        val live = tracker.currentGroupId()
        if (live != null && live != groupId) return CallGroupOutcome.LIMIT_REACHED
        if (!router.setCallGroup(callIds)) return CallGroupOutcome.NOT_SUPPORTED
        tracker.declareGroup(groupId, callIds)
        return CallGroupOutcome.ACCEPTED
    }

    override fun startUnsetCallGroup(callIds: List<String>): CallGroupOutcome {
        if (!router.unsetCallGroup(callIds)) return CallGroupOutcome.NOT_SUPPORTED
        tracker.releaseFromGroup(callIds)
        return CallGroupOutcome.ACCEPTED
    }

    override fun isGrouped(callId: String): Boolean = tracker.isGrouped(callId)

    override fun groupMembersWith(callId: String): List<String> = tracker.groupMembersWith(callId)

    override fun startSpeaker(metadata: CallMetadata) = router.startSpeaker(metadata)

    override fun setAudioDevice(metadata: CallMetadata) = router.setAudioDevice(metadata)

    override fun tearDownService() = router.tearDownService()

    override fun sendTearDownConnections() = router.sendTearDownConnections()

    override fun sendReserveAnswer(callId: String) = router.sendReserveAnswer(callId)

    override fun sendCleanConnections() = router.sendCleanConnections()

    override fun replayAudioState() = router.replayAudioState()

    override fun replayConnectionStates() = router.replayConnectionStates()

    companion object {
        private const val TAG = "InProcessCallkeepCore"

        // How long an incoming registration waits for Telecom before it is rejected. The safety
        // net, not the normal path: a refusal arrives as IncomingFailure long before this; the
        // timer is for a backend that never answers. Dispatch exceptions are cleaned immediately.
        private const val INCOMING_REGISTRATION_TIMEOUT_MS = 5_000L

        // A debuggable app starts Flutter on the main thread far slower, and the backend's answer
        // waits behind that start. On a slow device a cold-start registration took up to 5 s in a
        // debug build and under 1 s in release, so debug gets the longer wait.
        private const val DEBUG_INCOMING_REGISTRATION_TIMEOUT_MS = 10_000L

        internal fun incomingRegistrationTimeoutMs(context: Context?): Long {
            val debuggable = context != null && context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
            return if (debuggable) DEBUG_INCOMING_REGISTRATION_TIMEOUT_MS else INCOMING_REGISTRATION_TIMEOUT_MS
        }

        val instance: CallkeepCore = InProcessCallkeepCore()

        /**
         * Events delivered to all [ConnectionEventListener] subscribers.
         *
         * Covers the persistent global subscriptions used by [ForegroundService] and
         * [IncomingCallService]. Per-call one-off receivers (OngoingCall, OutgoingFailure,
         * TearDownComplete) are excluded — they stay as dynamic receivers registered via
         * [registerConnectionEvents].
         *
         * IncomingFailure must reach the core even on a cold push with no listeners:
         * it completes the incoming registration without waiting for the safety timeout.
         */

        internal val GLOBAL_LISTENER_EVENTS: List<ConnectionEvent> =
            listOf(
                CallLifecycleEvent.IncomingConnectionReported,
                CallLifecycleEvent.IncomingFailure,
                CallLifecycleEvent.ReplayIncomingCall,
                CallLifecycleEvent.ConnectionStateChanged,
                CallLifecycleEvent.DeclineCall,
                CallLifecycleEvent.HungUp,
                CallLifecycleEvent.ConnectionNotFound,
                CallLifecycleEvent.AnswerCall,
                CallMediaEvent.AudioDeviceSet,
                CallMediaEvent.AudioDevicesUpdate,
                CallMediaEvent.AudioMuting,
                CallMediaEvent.ConnectionHolding,
                CallMediaEvent.SentDTMF,
            )

        // The events after which a call is over, whoever ended it.
        internal val TERMINAL_EVENTS: Set<ConnectionEvent> =
            setOf(CallLifecycleEvent.DeclineCall, CallLifecycleEvent.HungUp, CallLifecycleEvent.ConnectionNotFound)
    }
}
