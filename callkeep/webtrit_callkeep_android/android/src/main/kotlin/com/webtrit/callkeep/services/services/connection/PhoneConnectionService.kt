package com.webtrit.callkeep.services.services.connection

import android.Manifest
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.DisconnectCause
import android.telecom.PhoneAccountHandle
import androidx.annotation.RequiresApi
import androidx.annotation.RequiresPermission
import com.webtrit.callkeep.PIncomingCallError
import com.webtrit.callkeep.PIncomingCallErrorEnum
import com.webtrit.callkeep.common.AssetCacheManager
import com.webtrit.callkeep.common.CallDataConst
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.common.Log
import com.webtrit.callkeep.common.TelephonyUtils
import com.webtrit.callkeep.models.CallConnectionState
import com.webtrit.callkeep.models.CallGroup
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.models.FailureMetadata
import com.webtrit.callkeep.models.InvalidCallMetadataException
import com.webtrit.callkeep.services.broadcaster.CallCommandEvent
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.broadcaster.ConnectionEvent
import com.webtrit.callkeep.services.broadcaster.ConnectionServicePerformBroadcaster
import com.webtrit.callkeep.services.services.connection.dispatchers.ConnectionLifecycleAction
import com.webtrit.callkeep.services.services.connection.dispatchers.PhoneConnectionServiceDispatcher
import com.webtrit.callkeep.services.services.foreground.ForegroundService

/**
 * `PhoneConnectionService` is a service class responsible for managing phone call connections
 * in the Webtrit CallKeep Android library. It handles incoming and outgoing calls,
 * call actions (answer, decline, mute, hold, etc.), and provides methods for interacting with
 * phone call connections.
 *
 * @constructor Creates a new instance of `PhoneConnectionService`.
 */
@RequiresApi(Build.VERSION_CODES.O)
class PhoneConnectionService : ConnectionService() {
    private lateinit var phoneConnectionServiceDispatcher: PhoneConnectionServiceDispatcher

    private val dispatcher: ConnectionServicePerformBroadcaster.DispatchHandle =
        ConnectionServicePerformBroadcaster.handle

    override fun onCreate() {
        super.onCreate()
        // Initialize ContextHolder for the :callkeep_core process. Each OS process has its own
        // JVM, so ContextHolder.init() called in the main process has no effect here.
        ContextHolder.init(applicationContext)
        Log.initFromContext(applicationContext)
        // Initialize AssetCacheManager for the :callkeep_core process so that
        // PhoneConnection.onShowIncomingCallUi() can resolve the custom ringtone asset
        // path via AssetCacheManager.getAsset(). Without this, AssetCacheManager.getAsset()
        // may throw IllegalStateException, which is caught inside getRingtone() and causes
        // a fallback to the system default ringtone.
        AssetCacheManager.init(applicationContext)

        val proximitySensorManager =
            ProximitySensorManager(applicationContext, PhoneConnectionConsts())

        phoneConnectionServiceDispatcher =
            PhoneConnectionServiceDispatcher(
                connectionManager,
                ::performEventHandle,
                proximitySensorManager,
            )
    }

    /**
     * Handles an event related to a call connection and dispatches it to the appropriate components.
     *
     * This method should be used to report events back to subscribers. If the connection reference
     * still exists, use it directly to handle the event. However, in cases where the connection
     * was destroyed due to concurrency (e.g., another component removed the connection before this
     * component tried to access it), this method serves as a proxy to forward the event via the
     * [PhoneConnectionServiceDispatcher].
     *
     * Using this proxy avoids potential freezes caused by unhandled async/await logic on the Flutter side.
     *
     * @param event The connection-related event to be handled.
     * @param data Optional call metadata associated with the event.
     */
    fun performEventHandle(
        event: ConnectionEvent,
        data: CallMetadata? = null,
    ) {
        Log.i(TAG, "performEventHandle: $event")
        dispatcher.dispatch(baseContext, event, data?.toBundle())
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int,
    ): Int {
        // Parse the intent into a typed command once, BEFORE the try, but without touching the
        // call metadata for commands that do not need it. This avoids the crash where
        // CallMetadata.fromBundle was eagerly invoked on empty Binder-delivered extras for the
        // no-extras lifecycle commands and threw an uncaught IllegalArgumentException.
        val command =
            intent?.let { PhoneServiceCommand.from(it) } ?: run {
                // Distinguish an unrecognised action from a known action whose required
                // callId/metadata is missing, so the log points at the actual failure.
                if (intent?.action?.let { ServiceAction.from(it) } != null) {
                    Log.w(TAG, "onStartCommand: action '${intent.action}' missing required callId/metadata, ignoring")
                } else {
                    Log.w(TAG, "onStartCommand: unknown or missing action '${intent?.action}', ignoring")
                }
                return START_NOT_STICKY
            }

        try {
            when (command) {
                // IPC commands from the main process — handled directly, not routed through the
                // call-connection dispatcher. Using startService (instead of broadcasts) guarantees
                // delivery even if the service is starting up: the intent is queued and processed
                // after onCreate() completes, so these handlers are always reachable.
                is PhoneServiceCommand.TearDown -> {
                    handleTearDownConnections()
                }

                is PhoneServiceCommand.Reserve -> {
                    handleReserveAnswer(command.callId)
                }

                is PhoneServiceCommand.Clean -> {
                    handleCleanConnections()
                }

                is PhoneServiceCommand.ReplayAudio -> {
                    handleReplayAudioState()
                }

                is PhoneServiceCommand.ReplayConnections -> {
                    handleReplayConnectionStates()
                }

                is PhoneServiceCommand.CallOp -> {
                    phoneConnectionServiceDispatcher.dispatch(command.action, command.metadata)
                }

                is PhoneServiceCommand.Group -> {
                    handleCallGroup(command.action, command.callIds)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception $e with service action: ${intent.action},")
        }

        return START_NOT_STICKY
    }

    /**
     * Declares or withdraws the membership [callIds] have in the one group this backend keeps.
     *
     * Telecom is not told. A [android.telecom.Conference] would be the sanctioned way to say that
     * several connections are one thing, and it cannot be used here: Telecom masks
     * [Connection.PROPERTY_SELF_MANAGED] off any call it did not itself mark self-managed, and it
     * marks connections only - `CallsManager.createConferenceCall` never does - so a conference
     * built by this application arrives as an ordinary managed call, the default dialer is bound
     * to it, and the platform in-call screen draws the group. Its hang-up button then ends every
     * leg of a room from a screen the application does not own.
     *
     * What the conference bought is kept without it. Telecom holds one call to make another
     * active whether or not they are grouped; what the group changes is that the hold is answered
     * and goes no further, which is [PhoneConnection.isGrouped] and nothing else. The calls
     * themselves are untouched either way - a room's audio was never mixed on the device.
     *
     * A group needs two calls, so a membership smaller than that takes the group apart instead,
     * which is the same rule the standalone backend applies.
     */
    private fun handleCallGroup(
        action: ServiceAction,
        callIds: List<String>,
    ) {
        // An empty list names no group: a caller that computes no members must not
        // accidentally dissolve the current group.
        if (callIds.isEmpty()) return
        val named = callIds.mapNotNull { connectionManager.getConnection(it) }.map { it.callId }
        Log.i(TAG, "handleCallGroup: action=$action requested=$callIds resolved=${named.size}")
        // "telecom" is only a placeholder for membership calculations, not group identity.
        // This adapter consumes members only; MainProcessConnectionTracker owns the real id.
        val current = CallGroup.of("telecom", currentCallGroup())
        val next =
            if (action == ServiceAction.UnsetCallGroup) {
                current.without(callIds)
            } else {
                // A non-empty declaration with no resolved calls ends the current group.
                if (named.isEmpty()) CallGroup.empty else current.declare(named) { "telecom" }
            }
        applyCallGroup(next.members)
    }

    /**
     * Creates an outgoing phone connection for a call and updates the call state based on the provided metadata.
     *
     * @param connectionManagerPhoneAccount The phone account handle for the connection manager.
     * @param request The connection request containing call information.
     * @return The created PhoneConnection object for the outgoing call.
     */
    override fun onCreateOutgoingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle,
        request: ConnectionRequest,
    ): Connection {
        // request.extras originates from our own placeOutgoingCall(metadata.toBundle()), so a
        // missing callId here is a "should never happen" invariant violation (e.g. Binder
        // truncation / framework edge case). Fail this one connection gracefully instead of
        // letting CallMetadata.fromBundle throw an uncaught IllegalArgumentException that would
        // crash the whole :callkeep_core process.
        val metadata =
            CallMetadata.fromBundleOrNull(request.extras) ?: run {
                Log.e(TAG, "onCreateOutgoingConnection: missing callId in request extras, rejecting")
                return Connection.createFailedConnection(DisconnectCause(DisconnectCause.ERROR))
            }

        // Check if a connection with the same call ID already exists.
        // If so, reject the new connection request to prevent conflicts.
        if (connectionManager.isConnectionAlreadyExists(metadata.callId)) {
            // Return a failed connection indicating the line is busy.
            return Connection.createFailedConnection(DisconnectCause(DisconnectCause.BUSY))
        }

        val connection =
            PhoneConnection.createOutgoingPhoneConnection(
                applicationContext,
                ::performEventHandle,
                metadata,
                ::disconnectConnection,
            )
        connectionManager.addConnection(metadata.callId, connection)
        phoneConnectionServiceDispatcher.dispatchLifecycle(
            ConnectionLifecycleAction.ConnectionCreated,
            metadata,
        )

        return connection
    }

    /**
     * Called when the creation of an outgoing connection fails. This method handles the failure by
     * notifying the TelephonyForegroundCallkeepApi about the failure and then calls the superclass
     * implementation.
     *
     * @param connectionManagerPhoneAccount The phone account handle for the connection manager.
     * @param request The connection request that failed.
     */
    override fun onCreateOutgoingConnectionFailed(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?,
    ) {
        val callMetadata = CallMetadata.fromBundleOrNull(request?.extras ?: Bundle.EMPTY)

        val failureContext = "onCreateOutgoingConnectionFailed"
        val failureMessage = "$failureContext: $connectionManagerPhoneAccount $request"
        val failureMetadata = FailureMetadata(callMetadata, failureMessage).toBundle()

        Log.e(TAG, failureMessage)

        dispatcher.dispatch(baseContext, CallLifecycleEvent.OutgoingFailure, failureMetadata)

        phoneConnectionServiceDispatcher.dispatchLifecycle(ConnectionLifecycleAction.ConnectionChanged)

        super.onCreateOutgoingConnectionFailed(connectionManagerPhoneAccount, request)
    }

    /**
     * Create an incoming connection and handle its initialization.
     *
     * @param connectionManagerPhoneAccount The phone account handle for the connection manager.
     * @param request The connection request containing extras.
     * @return The created Connection instance.
     */
    override fun onCreateIncomingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle,
        request: ConnectionRequest,
    ): Connection {
        // request.extras originates from our own addNewIncomingCall(metadata.toBundle()), so a
        // missing callId here is a "should never happen" invariant violation. Reject this one
        // connection instead of letting CallMetadata.fromBundle throw an uncaught
        // IllegalArgumentException that would crash the whole :callkeep_core process.
        val metadata =
            CallMetadata.fromBundleOrNull(request.extras) ?: run {
                Log.e(TAG, "onCreateIncomingConnection: missing callId in request extras, rejecting")
                return Connection.createFailedConnection(DisconnectCause(DisconnectCause.ERROR))
            }
        Log.i(TAG, "onCreateIncomingConnection: entry callId=${metadata.callId} account=$connectionManagerPhoneAccount")

        // This is where the pending slot is registered, and the only place that registers it in
        // this process: startIncomingCall reports the call straight to TelecomManager from the
        // reporting process, whose ConnectionManager is a different JVM instance, and Telecom then
        // binds this service and calls here on the main thread.
        //
        // A refusal means cleanConnections already captured this callId - a stale callback that
        // arrived after a tearDown - so the connection is refused rather than created into a
        // session that is already closed.
        if (!connectionManager.addPendingForIncomingCall(metadata.callId)) {
            Log.w(TAG, "onCreateIncomingConnection: callId=${metadata.callId} force-terminated by tearDown, rejecting stale callback")
            return Connection.createFailedConnection(DisconnectCause(DisconnectCause.LOCAL))
        }

        // Check if a connection with the same ID already exists.
        // This can occur if receivers from both the activity and the service
        // trigger the incoming call flow simultaneously.
        if (connectionManager.isConnectionAlreadyExists(metadata.callId)) {
            // Clean up pending state to avoid leaks — returning a failed Connection
            // does NOT trigger onCreateIncomingConnectionFailed.
            Log.w(TAG, "onCreateIncomingConnection: callId=${metadata.callId} — connection already exists, returning ERROR")
            connectionManager.removePending(metadata.callId)
            connectionManager.consumeAnswer(metadata.callId)
            return Connection.createFailedConnection(DisconnectCause(DisconnectCause.ERROR))
        }

        // Check if there is already an existing incoming connection.
        // If so, decline the new incoming connection to prevent conflicts in initializing the incoming call flow.
        if (connectionManager.isExistsIncomingConnection()) {
            // Clean up pending state to avoid leaks — returning a failed Connection
            // does NOT trigger onCreateIncomingConnectionFailed.
            Log.w(TAG, "onCreateIncomingConnection: callId=${metadata.callId} — another incoming connection already exists, returning BUSY")
            connectionManager.removePending(metadata.callId)
            connectionManager.consumeAnswer(metadata.callId)
            // Notify the main process that this call was rejected so it can clean
            // up its pending state. Without this, MainProcessConnectionTracker retains
            // the callId in pendingCallIds and a subsequent answerCall() sends a
            // ReserveAnswer that is never consumed (no onCreateIncomingConnection fires again).
            // This mirrors the HungUp path in onCreateIncomingConnectionFailed.
            dispatcher.dispatch(baseContext, CallLifecycleEvent.HungUp, metadata.toBundle())
            return Connection.createFailedConnection(DisconnectCause(DisconnectCause.BUSY))
        }

        val connection =
            PhoneConnection.createIncomingPhoneConnection(
                applicationContext,
                ::performEventHandle,
                metadata,
                ::disconnectConnection,
            )

        // Remove from pendingCallIds first (independent of the answer-reservation check).
        // The call is no longer "pending" — it now has a live PhoneConnection object.
        // Removing it from pendingCallIds ensures that a subsequent reportNewIncomingCall
        // for the same callId (e.g. main process CallBloc arriving ~6 s after the push
        // isolate already answered the call) skips the pendingCallIds branch in
        // checkAndReservePending and correctly reaches the hasAnswered check, returning
        // CALL_ID_ALREADY_EXISTS_AND_ANSWERED instead of CALL_ID_ALREADY_EXISTS.
        connectionManager.removePending(metadata.callId)

        // Atomically register the connection and consume any deferred answer reserved by
        // handleReserveAnswer. Using a single lock operation prevents the race where
        // handleReserveAnswer checks getConnection (null) then onCreateIncomingConnection
        // adds the connection + consumeAnswer (false) then handleReserveAnswer reserves —
        // leaving the answer permanently stuck in pendingAnswers with no consumer.
        if (connectionManager.addConnectionAndConsumeAnswer(metadata.callId, connection)) {
            // Schedule onAnswer() for the next main-thread loop iteration, AFTER
            // onCreateIncomingConnection returns to Telecom. Calling setActive() inside
            // onCreateIncomingConnection races with Telecom's own handleCreateConnectionComplete:
            // Telecom resets the call to RINGING after the callback returns, so our setActive()
            // (sent before the return) is overwritten. By posting to the handler we guarantee
            // Telecom has finished its setup before we send setActive(), so a subsequent
            // addNewIncomingCall for a second call sees the first call as ACTIVE (not RINGING)
            // and does not cancel it with DISCONNECTED/CANCELED.
            Log.i(TAG, "onCreateIncomingConnection: scheduling deferred answer after Telecom setup for callId=${metadata.callId}")
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                Log.i(TAG, "onCreateIncomingConnection: applying deferred answer for callId=${metadata.callId}")
                connection.onAnswer()
            }
        } else {
            // Notify the main process that an incoming call is registered, deterministically at
            // creation time. Previously this was emitted later from PhoneConnection.onShowIncomingCallUi
            // (a system UI callback the framework schedules separately), which made delivery to
            // Flutter and the reportNewIncomingCall callback resolution depend on UI-show timing.
            //
            // Only the not-yet-answered branch emits it: a call with a consumed deferred answer is
            // being answered immediately (no incoming UI), so it is surfaced to Flutter via the
            // answer flow instead — matching the previous behaviour where onShowIncomingCallUi
            // (and therefore IncomingConnectionReported) did not fire for an immediately-answered call.
            performEventHandle(CallLifecycleEvent.IncomingConnectionReported, metadata)
        }

        phoneConnectionServiceDispatcher.dispatchLifecycle(
            ConnectionLifecycleAction.ConnectionCreated,
            metadata,
        )

        return connection
    }

    /**
     * Called when the creation of an incoming connection fails. This method handles the failure by
     * notifying the TelephonyForegroundCallkeepApi about the failure and then calls the superclass
     * implementation.
     *
     * @param connectionManagerPhoneAccount The phone account handle for the connection manager.
     * @param request The connection request that failed.
     */
    override fun onCreateIncomingConnectionFailed(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?,
    ) {
        val callMetadata = CallMetadata.fromBundleOrNull(request?.extras ?: Bundle.EMPTY)
        val callId = callMetadata?.callId

        // Check before removing: if this callId was pending, the failure was for a real call
        // that should be reported to Flutter as ended (e.g., rejected with BUSY because another
        // incoming call was already ringing). If it was not pending, this is treated as a stale
        // Telecom callback and routed to IncomingFailure.
        //
        // Since startIncomingCall reports directly via TelecomManager.addNewIncomingCall (no
        // pre-registration in this process), wasPending can be false even for a genuine fresh
        // rejection; in that case the main-process confirmation timeout in
        // ForegroundService.reportNewIncomingCall is the authoritative resolver that fails the
        // Pigeon callback with CALL_REJECTED_BY_SYSTEM, so the call is not left hung.
        val wasPending = callId != null && connectionManager.isPending(callId)
        callId?.let { connectionManager.removePending(it) }

        val failureContext = "onCreateIncomingConnectionFailed"
        val failureMessage = "$failureContext: callId=$callId wasPending=$wasPending account=$connectionManagerPhoneAccount"

        Log.e(TAG, "$failureMessage — Telecom rejected the incoming call registration")

        if (wasPending) {
            // callId comes off callMetadata, so wasPending being true makes both non-null.
            // The pending slot is already dropped above; what is left is telling the main process
            // the call ended, so it resolves the Pigeon callback waiting on this one. The metadata
            // rather than the bare id, so receivers get the handle and display name with it.
            Log.i(TAG, "onCreateIncomingConnectionFailed: firing HungUp for pending callId=$callId")
            dispatcher.dispatch(baseContext, CallLifecycleEvent.HungUp, callMetadata!!.toBundle())
        } else {
            val failureMetadata = FailureMetadata(callMetadata, failureMessage).toBundle()
            dispatcher.dispatch(baseContext, CallLifecycleEvent.IncomingFailure, failureMetadata)
        }

        phoneConnectionServiceDispatcher.dispatchLifecycle(ConnectionLifecycleAction.ConnectionChanged)

        super.onCreateIncomingConnectionFailed(connectionManagerPhoneAccount, request)
    }

    private fun disconnectConnection(connection: PhoneConnection) {
        Log.i(TAG, "disconnectConnection:: $connection")

        phoneConnectionServiceDispatcher.dispatchLifecycle(ConnectionLifecycleAction.ConnectionChanged)
    }

    private fun handleTearDownConnections() {
        Log.i(TAG, "handleTearDownConnections: hanging up all connections and cleaning up")
        val connections = connectionManager.getConnections()
        connections.forEach { connection ->
            runCatching { connection.hungUp() }
                .onFailure { e -> Log.e(TAG, "handleTearDownConnections: hungUp failed for ${connection.callId}", e) }
        }
        connectionManager.cleanConnections()
        dispatcher.dispatch(baseContext, CallCommandEvent.TearDownComplete)
    }

    private fun handleReserveAnswer(callId: String) {
        Log.i(TAG, "handleReserveAnswer: callId=$callId")
        // reserveOrGetConnectionToAnswer is atomic: it either returns the existing connection
        // for immediate answering, or reserves the deferred answer in pendingAnswers under
        // the same lock that addConnectionAndConsumeAnswer uses. This eliminates the race
        // where getConnection returns null, onCreateIncomingConnection adds the connection
        // and consumeAnswer returns false, then reserveAnswer adds to pendingAnswers
        // permanently (no consumer will ever drain it).
        val connection = connectionManager.reserveOrGetConnectionToAnswer(callId)
        if (connection != null) {
            Log.i(TAG, "handleReserveAnswer: connection exists, answering immediately for callId=$callId")
            connection.onAnswer()
        } else {
            Log.d(TAG, "handleReserveAnswer: no connection yet, deferred answer reserved for callId=$callId")
        }
    }

    private fun handleCleanConnections() {
        Log.i(TAG, "handleCleanConnections: clearing all connections")
        connectionManager.cleanConnections()
    }

    private fun handleReplayAudioState() {
        Log.i(TAG, "handleReplayAudioState: re-emitting audio state for all active connections")
        connectionManager.getConnections().forEach { it.forceUpdateAudioState() }
    }

    private fun handleReplayConnectionStates() {
        Log.i(TAG, "handleReplayConnectionStates: re-emitting lifecycle + connection state for active connections")
        connectionManager.getConnections().forEach { connection ->
            // Mirror the live Telecom state back into the main-process shadow tracker. On a cold
            // start the original onStateChanged fired before this process existed, so the state
            // (e.g. ACTIVE for a call answered via the notification button) is restored only here --
            // and reportNewIncomingCall's already-answered adoption reads getState() == STATE_ACTIVE.
            // markAnswered() is a guard only since the state-mirror refactor, so AnswerCall below no
            // longer repopulates connectionStates; this does. Live states only (DISCONNECTED stays
            // on the cause-carrying termination events).
            telecomConnectionState(connection.state)
                ?.takeIf { it != CallConnectionState.DISCONNECTED }
                ?.let { performEventHandle(CallLifecycleEvent.ConnectionStateChanged, connection.currentMetadata.copy(connectionState = it)) }

            // Re-deliver the call-setup event so a freshly attached delegate adopts/shows the call.
            when {
                connection.hasAnswered -> {
                    performEventHandle(CallLifecycleEvent.AnswerCall, CallMetadata(callId = connection.callId))
                }

                connection.state == Connection.STATE_RINGING -> {
                    // A still-ringing incoming call whose owning Flutter delegate is freshly attached
                    // (push->foreground isolate handoff or hot restart). The delegate that originally
                    // received IncomingConnectionReported is gone, so the new one has no record of this call.
                    // Re-deliver the full metadata so the main process seeds its call state BEFORE it
                    // processes signaling events (handshake/hangup). Without this the call lives only
                    // as a native connection and an incoming hangup is dropped (no matching ActiveCall).
                    performEventHandle(CallLifecycleEvent.ReplayIncomingCall, connection.currentMetadata)
                }
            }
        }
    }

    override fun onDestroy() {
        Log.i(TAG, "onDestroy")
        cleanupResources()
        super.onDestroy()
    }

    /**
     * Called when the user removes the application from the recent tasks list (swipes away the app).
     * This ensures that active connections are forcefully disconnected to remove the system call UI
     * and the service is stopped to prevent it from running as a zombie process.
     */
    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.i(TAG, "onTaskRemoved: App swiped away. Force cleaning connections.")

        cleanupResources()
        stopSelf()

        super.onTaskRemoved(rootIntent)
    }

    /**
     * Dispatches a ServiceDestroyed lifecycle event to the dispatcher.
     *
     * This unifies the cleanup flow for both onDestroy and onTaskRemoved. Actual resource
     * release and disconnection of active calls are performed by the
     * phoneConnectionServiceDispatcher in response to the ServiceDestroyed event.
     */
    private fun cleanupResources() {
        phoneConnectionServiceDispatcher.dispatchLifecycle(ConnectionLifecycleAction.ServiceDestroyed)
    }

    companion object {
        private const val TAG = "PhoneConnectionService"

        /** Local name for [ConnectionManager.instance], which this service is the busiest user of. */
        private val connectionManager: ConnectionManager
            get() = ConnectionManager.instance

        /** The calls that stand as the one group, read off the connections that carry it. */
        fun currentCallGroup(): Set<String> =
            connectionManager
                .getConnections()
                .filter { it.isGrouped }
                .map { it.callId }
                .toSet()

        /**
         * Makes [members] the group, and everything else not the group.
         *
         * One call is not a group, so a membership that would leave one behind leaves nobody in
         * it.
         *
         * Nothing else is touched. Telecom's own idea of which call is active is left exactly as
         * it stands, because taking a held call off hold while another is active is not a swap
         * here - it ends the call. `CallsManager.holdActiveCallForNewCall` first asks whether the
         * active call can be held, and a self-managed connection of ours advertises
         * CAPABILITY_SUPPORT_HOLD without CAPABILITY_HOLD, so it cannot; the same-source branch
         * then disconnects the held call of this account outright ("Disconnect held call %s
         * before holding active call %s") - measured, a leg of a room gone 20 ms after
         * `setActive()`. Membership does not need it either way: a held member carries the room
         * like any other, because the room is mixed off the device.
         *
         * A call on the way out is left held as well, even though the application believes it is
         * speaking. Asking "is anything else active" first is not enough: a call whose connection
         * has reached DISCONNECTED is still ACTIVE for Telecom for a few more milliseconds, and
         * that window is exactly when the last member leaves a room - measured, the survivor was
         * disconnected 12 ms after being made active. The disagreement is Telecom's bookkeeping
         * only; who is held is the application's to publish, and it publishes it when the room
         * ends.
         */
        fun applyCallGroup(members: Set<String>) {
            // Normalize membership only; the placeholder id has no identity semantics here.
            val settled = CallGroup.of("telecom", members).members
            connectionManager.getConnections().forEach { connection ->
                val belongs = connection.callId in settled
                if (connection.isGrouped == belongs) return@forEach
                Log.i(TAG, "applyCallGroup: ${connection.callId} ${if (belongs) "joins" else "leaves"} the group")
                connection.isGrouped = belongs
            }
        }

        /**
         * Takes [connection] out of the group, taking the group apart if one call is left in it.
         *
         * The flag is cleared on the connection itself rather than through [applyCallGroup],
         * because the one caller is a connection that has just reached DISCONNECTED and a
         * disconnected connection is no longer among [ConnectionManager.getConnections].
         */
        fun releaseFromCallGroup(connection: PhoneConnection) {
            connection.isGrouped = false
            applyCallGroup(currentCallGroup())
        }

        fun startAnswerCall(
            context: Context,
            metadata: CallMetadata,
        ) {
            communicate(context, ServiceAction.AnswerCall, metadata)
        }

        fun startEstablishCall(
            context: Context,
            metadata: CallMetadata,
        ) {
            communicate(context, ServiceAction.EstablishCall, metadata)
        }

        fun startUpdateCall(
            context: Context,
            metadata: CallMetadata,
        ) {
            communicate(context, ServiceAction.UpdateCall, metadata)
        }

        fun startDeclineCall(
            context: Context,
            metadata: CallMetadata,
        ) {
            communicate(context, ServiceAction.DeclineCall, metadata)
        }

        fun startHungUpCall(
            context: Context,
            metadata: CallMetadata,
        ) {
            communicate(context, ServiceAction.HungUpCall, metadata)
        }

        fun startSendDtmfCall(
            context: Context,
            metadata: CallMetadata,
        ) {
            communicate(context, ServiceAction.SendDTMF, metadata)
        }

        fun startMutingCall(
            context: Context,
            metadata: CallMetadata,
        ) {
            communicate(context, ServiceAction.Muting, metadata)
        }

        fun startHoldingCall(
            context: Context,
            metadata: CallMetadata,
        ) {
            communicate(context, ServiceAction.Holding, metadata)
        }

        fun startSpeaker(
            context: Context,
            metadata: CallMetadata,
        ) {
            communicate(context, ServiceAction.Speaker, metadata)
        }

        fun setAudioDevice(
            context: Context,
            metadata: CallMetadata,
        ) {
            communicate(context, ServiceAction.AudioDeviceSet, metadata)
        }

        fun tearDown(context: Context) {
            communicate(context, ServiceAction.TearDown, null)
        }

        /**
         * Sends a [ServiceAction.TearDownConnections] command to this service via [startService].
         *
         * Using an explicit [startService] intent (instead of a broadcast) guarantees that:
         * - Only this app can trigger the action (explicit intents are not interceptable by others).
         * - The command is queued and processed after [onCreate] completes, so it is never dropped
         *   even if the service is starting up concurrently.
         *
         * The service will hang up all active [PhoneConnection]s, call [ConnectionManager.cleanConnections],
         * and reply with [CallCommandEvent.TearDownComplete].
         */
        fun sendTearDownConnections(context: Context) {
            val intent =
                Intent(context, PhoneConnectionService::class.java).apply {
                    action = ServiceAction.TearDownConnections.action
                }
            runCatching { context.startService(intent) }
                .onFailure { e -> Log.w(TAG, "sendTearDownConnections: startService failed: $e") }
        }

        /**
         * Sends a [ServiceAction.ReserveAnswer] command with [callId] to this service via [startService].
         *
         * Using an explicit [startService] intent guarantees delivery even if the service is still
         * starting up (the intent is queued to [onStartCommand] after [onCreate] completes), which
         * closes the race where a broadcast could be dropped before [commandReceiver] is registered.
         */
        fun sendReserveAnswer(
            context: Context,
            callId: String,
        ) {
            val intent =
                Intent(context, PhoneConnectionService::class.java).apply {
                    action = ServiceAction.ReserveAnswer.action
                    putExtras(CallMetadata(callId = callId).toBundle())
                }
            runCatching { context.startService(intent) }
                .onFailure { e -> Log.w(TAG, "sendReserveAnswer: startService failed for callId=$callId: $e") }
        }

        /**
         * Sends a [ServiceAction.CleanConnections] command to this service via [startService].
         *
         * Using an explicit [startService] intent (instead of a broadcast) prevents external apps
         * from injecting a fake CleanConnections command on API < 33 where broadcast receivers
         * registered without a permission are effectively exported.
         */
        fun sendCleanConnections(context: Context) {
            val intent =
                Intent(context, PhoneConnectionService::class.java).apply {
                    action = ServiceAction.CleanConnections.action
                }
            runCatching { context.startService(intent) }
                .onFailure { e -> Log.w(TAG, "sendCleanConnections: startService failed: $e") }
        }

        /**
         * Sends [ServiceAction.ReplayAudioState] to [PhoneConnectionService].
         * The service will call [PhoneConnection.forceUpdateAudioState] on all active connections,
         * which re-emits audio device and mute state broadcasts back to the main process.
         * Used by [ForegroundService.onDelegateSet] to restore Flutter UI after hot restart.
         */
        fun replayAudioState(context: Context) {
            val intent =
                Intent(context, PhoneConnectionService::class.java).apply {
                    action = ServiceAction.ReplayAudioState.action
                }
            runCatching { context.startService(intent) }
                .onFailure { e -> Log.w(TAG, "replayAudioState: startService failed: $e") }
        }

        /**
         * Sends [ServiceAction.ReplayConnectionStates] to [PhoneConnectionService].
         * The service will re-fire [CallLifecycleEvent.AnswerCall] for every connection whose
         * [PhoneConnection.hasAnswered] flag is true. This lets the main process
         * ([ForegroundService]) populate [MainProcessConnectionTracker.connectionStates] even
         * when it starts after the AnswerCall broadcast was originally emitted (cold-start race).
         */
        fun replayConnectionStates(context: Context) {
            val intent =
                Intent(context, PhoneConnectionService::class.java).apply {
                    action = ServiceAction.ReplayConnectionStates.action
                }
            runCatching { context.startService(intent) }
                .onFailure { e -> Log.w(TAG, "replayConnectionStates: startService failed: $e") }
        }

        /**
         * Handles new outgoing calls and starts the connection service if the service is not running.
         * For more information on system management of creating connection services,
         * refer to the [Android Telecom Framework Documentation](https://developer.android.com/reference/android/telecom/ConnectionService#implementing-connectionservice).
         *
         * @param metadata The [CallMetadata] for the incoming call.
         */
        @RequiresPermission(Manifest.permission.CALL_PHONE)
        fun startOutgoingCall(
            context: Context,
            metadata: CallMetadata,
        ) {
            Log.i(TAG, "onOutgoingCall, callId: ${metadata.callId}")

            val number =
                metadata.number
                    ?: throw InvalidCallMetadataException(
                        "startOutgoingCall: missing destination number for callId=${metadata.callId}",
                    )
            val telephonyUtils = TelephonyUtils(context)

            val uri: Uri = TelephonyUtils.buildOutgoingUri(number)

            // If there is already an active call not on hold, we terminate it and start a new one,
            // otherwise, we would encounter an exception when placing the outgoing call. A member
            // of a group is never that call: the group is what Telecom holds for the new one.
            connectionManager.getActiveConnection()?.takeUnless { it.isGrouped }?.let {
                Log.i(TAG, "onOutgoingCall, hung up previous call: $it")
                it.hungUp()
            }

            telephonyUtils.placeOutgoingCall(uri, metadata)
        }

        /**
         * Handles new incoming calls and starts the connection service if the service is not running.
         * For more information on system management of creating connection services,
         * refer to the [Android Telecom Framework Documentation](https://developer.android.com/reference/android/telecom/ConnectionService#implementing-connectionservice).
         *
         * @param metadata The [CallMetadata] for the incoming call.
         */
        fun startIncomingCall(
            context: Context,
            metadata: CallMetadata,
            onSuccess: () -> Unit,
            onError: (PIncomingCallError?) -> Unit,
        ) {
            Log.i(TAG, "startIncomingCall: callId=${metadata.callId}")

            ConnectionManager.validateConnectionAddition(metadata = metadata, onSuccess = {
                // Report the incoming call straight to Telecom via TelecomManager.addNewIncomingCall.
                // The Telecom system server then binds our ConnectionService itself with
                // BIND_AUTO_CREATE, launching/reviving :callkeep_core even when an app-side
                // startService cannot - e.g. when an aggressive OEM power manager killed that process
                // and flagged it "process is bad" (startService then throws SecurityException and the
                // call is lost). onCreateIncomingConnection registers the pending slot itself.
                //
                // On a cold push the self-managed PhoneAccount may not be registered yet
                // (ForegroundService.registerPhoneAccountWithRetry still in flight), so on the first
                // failure we re-register and retry once before giving up.
                runCatching { TelephonyUtils(context).addNewIncomingCall(metadata) }
                    .recoverCatching {
                        Log.w(TAG, "startIncomingCall: addNewIncomingCall failed for callId=${metadata.callId}, re-registering PhoneAccount and retrying once", it)
                        TelephonyUtils(context).registerPhoneAccount()
                        TelephonyUtils(context).addNewIncomingCall(metadata)
                    }.onSuccess { onSuccess() }
                    .onFailure { e ->
                        Log.e(TAG, "startIncomingCall: addNewIncomingCall failed after re-register for callId=${metadata.callId}", e)
                        connectionManager.removePending(metadata.callId)
                        onError(PIncomingCallError(PIncomingCallErrorEnum.UNKNOWN))
                    }
            }, onError = { incomingCallError ->
                Log.w(TAG, "Incoming call rejected: ${incomingCallError.value}")
                onError(incomingCallError)
            })
        }

        /**
         * Sends a group membership to the connection service.
         *
         * Carries a plain array of ids rather than [CallMetadata], because membership belongs to
         * the group and not to any one call in it.
         */
        fun startCallGroup(
            context: Context,
            action: ServiceAction,
            callIds: List<String>,
        ) {
            val intent = Intent(context, PhoneConnectionService::class.java)
            intent.action = action.action
            intent.putExtra(CallDataConst.CALL_IDS, callIds.toTypedArray())
            try {
                context.startService(intent)
            } catch (e: Exception) {
                Log.w(TAG, "startCallGroup: failed to start service for ${action.name}: $e")
            }
        }

        private fun communicate(
            context: Context,
            action: ServiceAction,
            metadata: CallMetadata?,
        ) {
            val intent = Intent(context, PhoneConnectionService::class.java)
            intent.action = action.action
            metadata?.toBundle()?.let { intent.putExtras(it) }

            try {
                context.startService(intent)
            } catch (e: Exception) {
                val reportDispatcher = ConnectionServicePerformBroadcaster.handle

                // Fallback: failed to start PhoneConnectionService.
                // This may happen if the app is in the background, lacks sufficient permissions,
                // or the system restricts service launches (e.g., background start limitations).
                //
                // To avoid the call hanging indefinitely, we proactively finish the call
                // as "HungUp" to ensure consistent call termination on the UI side.
                reportDispatcher.dispatch(context, CallLifecycleEvent.HungUp, metadata?.toBundle())
                Log.d(TAG, "Failed to start service with action: ${action.name}, error: $e")
            }
        }
    }
}
