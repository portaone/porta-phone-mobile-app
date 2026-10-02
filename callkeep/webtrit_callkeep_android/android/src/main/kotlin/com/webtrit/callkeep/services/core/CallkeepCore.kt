package com.webtrit.callkeep.services.core

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.IntentFilter
import android.os.Bundle
import androidx.annotation.RequiresPermission
import com.webtrit.callkeep.PCallkeepConnection
import com.webtrit.callkeep.PCallkeepConnectionState
import com.webtrit.callkeep.PEndCallReasonEnum
import com.webtrit.callkeep.PIncomingCallError
import com.webtrit.callkeep.PIncomingCallErrorEnum
import com.webtrit.callkeep.models.CallConnectionState
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.broadcaster.ConnectionEvent

/** What became of a grouping request, as the core answers it. */
enum class CallGroupOutcome {
    /** The backend took the request and the membership is recorded. */
    ACCEPTED,

    /** The active backend cannot group calls at all. */
    NOT_SUPPORTED,

    /** Another group is live under another name; every backend holds one at a time. */
    LIMIT_REACHED,
}

/**
 * Routing result for [CallkeepCore.routeAnswerCall].
 *
 * Encodes which action [ForegroundService.answerCall] should take without
 * leaking state-query details outside the facade.
 */

sealed class AnswerCallRoute {
    /** A live [PhoneConnection] exists — answer via IPC immediately. */
    object AnswerImmediately : AnswerCallRoute()

    /** Telecom accepted the call but [PhoneConnection] is not yet created — defer via ReserveAnswer. */
    object DeferAnswer : AnswerCallRoute()

    /** No connection or pending entry found for this callId. */
    object NotFound : AnswerCallRoute()
}

/**
 * Receives connection events dispatched by [CallkeepCore].
 *
 * Register via [CallkeepCore.addConnectionEventListener]; unregister via
 * [CallkeepCore.removeConnectionEventListener]. The callback is invoked on the main thread.
 */
fun interface ConnectionEventListener {
    fun onConnectionEvent(
        event: ConnectionEvent,
        data: Bundle?,
    )
}

/**
 * Owns the UI effects and termination of already-presented calls. Core first handles pending
 * registrations and stale teardown events, regardless of listeners. Remaining terminal events
 * go to this bridge; when no bridge is attached, core terminates their shadow state itself.
 */
interface CallEndListener : ConnectionEventListener

/**
 * Single facade for all interactions with the `:callkeep_core` process.
 *
 * Replaces two separate access points:
 * - `ConnectionTracker` (read/write shadow state in the main process), and
 * - `PhoneConnectionService` static methods (commands sent to `:callkeep_core`).
 *
 * The [companion] exposes a process-wide [instance]. After the process split, swap
 * [InProcessCallkeepCore] for a broadcast/binder-backed implementation by changing
 * only the [instance] assignment — no call sites change.
 *
 * ## Method groups
 *
 * **State queries** — read the main-process shadow of connection state.
 * **State mutations** — update the shadow as broadcasts arrive from `:callkeep_core`.
 * **CS commands** — send actions to `:callkeep_core` (via `startService` or broadcast).
 */
interface CallkeepCore {
    // -------------------------------------------------------------------------
    // State queries
    // -------------------------------------------------------------------------

    fun exists(callId: String): Boolean

    fun isPending(callId: String): Boolean

    fun isTerminated(callId: String): Boolean

    fun isAnswered(callId: String): Boolean

    /**
     * Returns null if [callId] is free and a new incoming call may proceed.
     * Returns [PIncomingCallError] with [PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS_AND_ANSWERED]
     * if already answered, or [PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS] if still ringing/active.
     */
    fun checkIncomingDuplicate(callId: String): PIncomingCallError?

    /**
     * Returns the action to take for an answer request on [callId]:
     * [AnswerCallRoute.AnswerImmediately] if a live connection exists,
     * [AnswerCallRoute.DeferAnswer] if pending but not yet connected,
     * [AnswerCallRoute.NotFound] if the callId is unknown.
     */
    fun routeAnswerCall(callId: String): AnswerCallRoute

    fun getAll(): List<CallMetadata>

    fun getPendingCallIds(): Set<String>

    fun get(callId: String): CallMetadata?

    fun getState(callId: String): PCallkeepConnectionState?

    fun toPCallkeepConnection(callId: String): PCallkeepConnection?

    // -------------------------------------------------------------------------
    // State mutations
    // -------------------------------------------------------------------------

    /** Returns true if the callId was not already present (i.e. this call actually added it). */
    fun addPending(callId: String): Boolean

    fun removePending(callId: String)

    fun promote(
        callId: String,
        metadata: CallMetadata,
        state: PCallkeepConnectionState,
    )

    fun markAnswered(callId: String)

    /**
     * Mirror the authoritative connection [state] for [callId] (source of truth = the real
     * android.telecom.Connection state via PhoneConnection.onStateChanged, or the StandaloneCallService
     * transitions). Writes state UNCONDITIONALLY — it does NOT register the call and may be called
     * before promote (state persists across addPending, which the cold-start adoption relies on).
     * Ignores terminal DISCONNECTED (owned by [markTerminated]).
     */
    fun updateState(
        callId: String,
        state: CallConnectionState,
    )

    fun markTerminated(callId: String)

    /**
     * Clears all state for [callId] and records that [performEndCall] has been dispatched.
     *
     * Returns true if this is the first dispatch, false if already dispatched.
     */
    fun clearAndMarkEndCallDispatched(callId: String): Boolean

    /** Reserves a deferred answer for [callId] so it is applied when the connection is created. */
    fun reserveAnswer(callId: String)

    fun consumeAnswer(callId: String): Boolean

    /**
     * Returns pending call IDs that have no promoted connection yet, and removes them
     * from the pending set so they are not returned again.
     */
    fun drainUnconnectedPendingCallIds(): Set<String>

    fun clear()

    // -------------------------------------------------------------------------
    // Callback guards
    // -------------------------------------------------------------------------

    fun markDirectNotified(callId: String)

    fun consumeDirectNotified(callId: String): Boolean

    fun markEndCallDispatched(callId: String): Boolean

    /** See [ConnectionTracker.markEndedWithoutFlutterState]. */
    fun markEndedWithoutFlutterState(callId: String)

    /** See [ConnectionTracker.wasEndedWithoutFlutterState]. */
    fun wasEndedWithoutFlutterState(callId: String): Boolean

    /**
     * True while the live call [callId] is one the app reported itself through its foreground
     * bridge. The incoming-call service presents a call to a live app only when it is not.
     */
    fun isReportedByApp(callId: String): Boolean

    // -------------------------------------------------------------------------
    // Connection event receivers
    // -------------------------------------------------------------------------

    /**
     * Subscribes [listener] to receive connection events. Callers must balance every
     * [addConnectionEventListener] with a corresponding [removeConnectionEventListener].
     */
    fun addConnectionEventListener(listener: ConnectionEventListener)

    /**
     * Unsubscribes [listener]. When the last listener is removed the global [BroadcastReceiver]
     * is unregistered.
     */
    fun removeConnectionEventListener(listener: ConnectionEventListener)

    /**
     * Registers [receiver] to receive the given [events] from [ConnectionServicePerformBroadcaster].
     * Use this for temporary per-call receivers (e.g. waiting for one specific confirmation
     * broadcast). For persistent subscriptions prefer [addConnectionEventListener].
     */
    fun registerConnectionEvents(
        context: Context,
        events: List<ConnectionEvent>,
        receiver: BroadcastReceiver,
        exported: Boolean = false,
    ): IntentFilter

    /**
     * Unregisters a [receiver] previously registered via [registerConnectionEvents].
     */
    fun unregisterConnectionEvents(
        context: Context,
        receiver: BroadcastReceiver,
    )

    /**
     * Delivers [event] directly to all registered [ConnectionEventListener]s and any
     * per-call receivers registered via [registerConnectionEvents], without going through
     * [android.app.ActivityManager] broadcast dispatch.
     *
     * Used by [com.webtrit.callkeep.services.services.connection.StandaloneCallService],
     * which runs in the main process alongside [ForegroundService]. On certain OEM devices
     * (e.g. Lenovo TB300FU, Android 13) the system ActivityManager suppresses all
     * [android.content.Context.sendBroadcast] calls originating from the app, so
     * in-process delivery is required.
     */
    fun notifyConnectionEvent(
        event: ConnectionEvent,
        data: Bundle? = null,
    )

    // -------------------------------------------------------------------------
    // CS commands
    // -------------------------------------------------------------------------

    @RequiresPermission(Manifest.permission.CALL_PHONE)
    fun startOutgoingCall(metadata: CallMetadata)

    /**
     * The app reports that [metadata]'s call ended - the remote party hung up, nobody answered,
     * or the app never got to present it ([PEndCallReasonEnum.MISSED_WHILE_CONNECTING]). The
     * same fact from every engine: the foreground bridge, the push session and a hosted engine.
     *
     * The core marks the call terminated at once (a registration still waiting for Telecom is
     * rejected), remembers a never-presented end so that a replay or a late push cannot present
     * the call again, records that the app knows this end so nothing asks it to end the call a
     * second time, and ends the call in the backend. Ends the call only: whatever session
     * reported it keeps running.
     */
    fun reportCallEnded(
        metadata: CallMetadata,
        reason: PEndCallReasonEnum,
    )

    // -------------------------------------------------------------------------
    // Incoming registration: waiting for Telecom's answer
    // -------------------------------------------------------------------------

    /**
     * Registers once and waits for the backend's answer, joining an existing attempt for this id.
     * The core owns guards, dispatch, timeout, state promotion, and cleanup before returning.
     * Already-answered calls return CALL_ID_ALREADY_EXISTS_AND_ANSWERED so a UI adapter can
     * deliver its answer notification. A cancelled caller releases only its own waiter.
     */
    suspend fun registerIncomingCall(
        metadata: CallMetadata,
        client: Any,
    ): PIncomingCallError?

    /** The activity bridge is gone; other clients and their calls remain live. */
    fun detachIncomingClient(client: Any)

    /** The session is ending; reject all its pending registrations and cancel their timers. */
    fun endIncomingRegistrations()

    /** An explicit app end accepts its pending report; the normal end event must still follow. */
    fun appEndingCall(callId: String)

    fun startAnswerCall(metadata: CallMetadata)

    fun startDeclineCall(metadata: CallMetadata)

    fun startHungUpCall(metadata: CallMetadata)

    fun startEstablishCall(metadata: CallMetadata)

    fun startUpdateCall(metadata: CallMetadata)

    fun startSendDtmfCall(metadata: CallMetadata)

    fun startMutingCall(metadata: CallMetadata)

    fun startHoldingCall(metadata: CallMetadata)

    /**
     * Presents [callIds] to the operating system as the group [groupId], and records the
     * membership on acceptance; the [CallGroupOutcome] says why it was refused otherwise.
     */
    fun startSetCallGroup(
        groupId: String,
        callIds: List<String>,
    ): CallGroupOutcome

    /** Takes [callIds] out of their group; [CallGroupOutcome.NOT_SUPPORTED] when the backend cannot group calls. */
    fun startUnsetCallGroup(callIds: List<String>): CallGroupOutcome

    /** Whether the application has declared [callId] into a call group. */
    fun isGrouped(callId: String): Boolean

    /** Every call sharing a group with [callId], [callId] included; empty when it is in none. */
    fun groupMembersWith(callId: String): List<String>

    fun startSpeaker(metadata: CallMetadata)

    fun setAudioDevice(metadata: CallMetadata)

    /**
     * Sends the legacy [ServiceAction.TearDown] intent to [PhoneConnectionService].
     * This resets the service state for the next session without hanging up connections
     * (connections are expected to be already torn down via [sendTearDownConnections]).
     */
    fun tearDownService()

    /**
     * Sends [ServiceAction.TearDownConnections] to [PhoneConnectionService].
     * The service will hang up all active connections and reply with a TearDownComplete broadcast.
     */
    fun sendTearDownConnections()

    /**
     * Sends [ServiceAction.ReserveAnswer] with [callId] to [PhoneConnectionService].
     * The service will call [ConnectionManager.reserveAnswer] so the deferred answer is applied
     * when [PhoneConnectionService.onCreateIncomingConnection] fires.
     */
    fun sendReserveAnswer(callId: String)

    /**
     * Sends [ServiceAction.CleanConnections] to [PhoneConnectionService].
     * The service will clear all connections without hanging up individual ones.
     */
    fun sendCleanConnections()

    /**
     * Asks [PhoneConnectionService] to REPLAY the current audio state (device + mute) for all
     * active connections back to the main process via broadcasts -- a one-way pull, not a two-way
     * sync. Called from [ForegroundService.onDelegateSet] to restore the Flutter audio UI once a
     * freshly attached delegate is ready (cold start / hot restart / warm re-attach). The sibling
     * of [replayConnectionStates].
     */
    fun replayAudioState()

    /**
     * Asks [PhoneConnectionService] to REPLAY the current connection lifecycle back to the main
     * process, so a freshly (re)attached delegate is seeded with state it would otherwise have
     * missed. This is a one-way pull (main -> `:callkeep_core` -> re-fired broadcasts), NOT a
     * two-way sync: the live `:callkeep_core` connections are the source of truth and simply
     * re-announce themselves. The service re-fires [CallLifecycleEvent.AnswerCall] for every
     * connection whose [PhoneConnection.hasAnswered] flag is true. Called from
     * [ForegroundService.onCreate] so that connections answered before the main process started
     * are reflected in [MainProcessConnectionTracker.connectionStates] (cold-start race).
     */
    fun replayConnectionStates()

    companion object {
        /**
         * Process-wide singleton. Swap the implementation here to change IPC strategy
         * without touching any call site.
         */
        val instance: CallkeepCore get() = InProcessCallkeepCore.instance
    }
}
