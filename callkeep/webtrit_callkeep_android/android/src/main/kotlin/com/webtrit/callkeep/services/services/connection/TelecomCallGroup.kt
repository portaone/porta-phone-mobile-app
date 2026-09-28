package com.webtrit.callkeep.services.services.connection

import android.os.Handler
import android.os.Looper
import android.telecom.Connection
import com.webtrit.callkeep.common.Log
import com.webtrit.callkeep.models.CallGroup

/**
 * The one call group of this process, kept on the connections that carry it, and the hold the
 * group shares with the calls outside it.
 *
 * Telecom is never told about the group (see [PhoneConnection.isGrouped]); what this class
 * manages is how the members stand in Telecom's books around calls that are not in the group, so
 * that Telecom's arbitration never finds a member to end. [ConnectionManager] owns the instance,
 * so the group and any activation still waiting for Telecom's focus live exactly as long as the
 * connections they are about.
 */
class TelecomCallGroup internal constructor(
    private val connections: () -> Collection<PhoneConnection>,
) {
    private val handler by lazy { Handler(Looper.getMainLooper()) }

    /** Calls outside the group waiting to go active; the group is not resumed meanwhile. */
    private val pendingActivations = mutableMapOf<PhoneConnection, Runnable>()

    /** The calls that stand as the one group, read off the connections that carry it. */
    fun members(): Set<String> =
        connections()
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
     * here - it can end a call. `CallsManager.holdActiveCallForNewCall` holds the active call
     * of ours to make room, and where it cannot (the connections advertised
     * CAPABILITY_SUPPORT_HOLD without CAPABILITY_HOLD until 7d8caafbdf7) or on builds that
     * ignore the capability (EMUI 12) it disconnects the held call of this account outright -
     * measured, a leg of a room gone 20 ms after `setActive()`. Membership does not need it
     * either way: a held member carries the room like any other, because the room is mixed
     * off the device. The group's hold is managed around the calls outside it instead - see
     * [hold] and [resumeLater].
     *
     * A call on the way out is left held as well, even though the application believes it is
     * speaking. Asking "is anything else active" first is not enough: a call whose connection
     * has reached DISCONNECTED is still ACTIVE for Telecom for a few more milliseconds, and
     * that window is exactly when the last member leaves a room - measured, the survivor was
     * disconnected 12 ms after being made active. The disagreement is Telecom's bookkeeping
     * only; who is held is the application's to publish, and it publishes it when the room
     * ends.
     */
    fun apply(members: Set<String>) {
        // Normalize membership only; the placeholder id has no identity semantics here.
        val settled = CallGroup.of("telecom", members).members
        connections().forEach { connection ->
            val belongs = connection.callId in settled
            if (connection.isGrouped == belongs) return@forEach
            Log.i(TAG, "apply: ${connection.callId} ${if (belongs) "joins" else "leaves"} the group")
            connection.isGrouped = belongs
        }
    }

    /**
     * Takes [connection] out of the group, taking the group apart if one call is left in it.
     *
     * The flag is cleared on the connection itself rather than through [apply], because the one
     * caller is a connection that has just reached DISCONNECTED and a disconnected connection is
     * no longer among the connections this group reads.
     */
    fun release(connection: PhoneConnection) {
        connection.isGrouped = false
        apply(members())
    }

    /**
     * Holds every active member of the group in Telecom's books, before a call outside the
     * group goes active - see [PhoneConnection.activate]. Returns whether any member was held.
     *
     * The members' own hold means nothing beyond Telecom (see [PhoneConnection.isGrouped]): the
     * room keeps its audio, and the application is not told.
     */
    fun hold(): Boolean {
        val active = connections().filter { it.isGrouped && it.state == Connection.STATE_ACTIVE }
        active.forEach {
            Log.i(TAG, "hold: ${it.callId} held for a call outside the group")
            it.setOnHold()
        }
        return active.isNotEmpty()
    }

    /**
     * Makes [connection] active once Telecom's focus has left the members just held for it.
     *
     * A resume scheduled by the hold of this same call a moment ago (a quick tap back to it)
     * would otherwise raise a member first, and the call would then go active against it.
     * The wait can be called off - see [cancelActivation] - and a new request replaces one
     * still waiting.
     */
    fun activateAfterFocusSettles(connection: PhoneConnection) {
        cancelActivation(connection)
        val activation =
            Runnable {
                pendingActivations.remove(connection)
                if (connection.state == Connection.STATE_DISCONNECTED) return@Runnable
                if (hold()) {
                    // A member went active in between: hold it and give the focus the time again.
                    activateAfterFocusSettles(connection)
                } else {
                    connection.setActive()
                }
            }
        pendingActivations[connection] = activation
        handler.postDelayed(activation, FOCUS_SETTLE_MS)
    }

    /**
     * Calls off an activation of [connection] still waiting for the focus, because the call
     * was held or ended before it got the place. Its state says nothing about that - a call
     * resumed from hold is still HOLDING while it waits, and held again it stays HOLDING - so
     * the request is dropped by name, and the place goes back to the group.
     */
    fun cancelActivation(connection: PhoneConnection) {
        val activation = pendingActivations.remove(connection) ?: return
        handler.removeCallbacks(activation)
        resumeLater()
    }

    /**
     * Gives the active place back to the group once every call outside it is held or gone.
     *
     * One member is made active, not all: two calls of ours are never both active for
     * Telecom, and raising a second member would make it hold the first again - with the
     * call outside on hold that is two held calls when the arbitration runs, and one of them
     * goes. Waiting [FOCUS_SETTLE_MS] lets Telecom's focus leave the call that just gave the
     * place up, so the member goes active with nothing of ours to arbitrate with.
     */
    fun resumeLater() {
        handler.postDelayed(::resumeIfIdle, FOCUS_SETTLE_MS)
    }

    private fun resumeIfIdle() {
        val connections = connections()
        val members = connections.filter { it.isGrouped }
        if (pendingActivations.isNotEmpty()) return
        if (members.isEmpty() || members.any { it.state == Connection.STATE_ACTIVE }) return
        if (connections.any { !it.isGrouped && it.state != Connection.STATE_HOLDING }) return
        val member = members.first()
        Log.i(TAG, "resumeIfIdle: ${member.callId} made active, nothing outside the group is")
        member.setActive()
    }

    companion object {
        private const val TAG = "TelecomCallGroup"

        /**
         * How long Telecom's focus takes to leave a call it has just seen go on hold or end.
         *
         * Telecom moves its focus on its own handler, after the state change, and a call that
         * reached DISCONNECTED is still active for it for a few milliseconds more (a survivor made
         * active in that window was disconnected 12 ms later). A call made active before the focus
         * has moved is arbitrated against the old focus as if nothing had changed.
         */
        internal const val FOCUS_SETTLE_MS = 300L
    }
}
