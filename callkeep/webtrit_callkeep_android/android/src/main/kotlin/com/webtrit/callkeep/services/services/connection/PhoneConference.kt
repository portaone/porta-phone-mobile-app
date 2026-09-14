package com.webtrit.callkeep.services.services.connection

import android.os.Build
import android.telecom.CallAudioState
import android.telecom.CallEndpoint
import android.telecom.Conference
import android.telecom.Connection
import android.telecom.DisconnectCause
import android.telecom.PhoneAccountHandle
import androidx.annotation.RequiresApi
import com.webtrit.callkeep.common.Log

/**
 * A group of calls as Telecom sees it.
 *
 * Telecom allows one call per application to be the foreground call, and holds the others on its
 * own initiative when a new one becomes active. A [Conference] is the sanctioned way to say that
 * several connections are one thing, so that the framework stops treating them as rivals.
 *
 * This carries no media: the calls were already independent and stay that way, and whoever mixes
 * their audio is no business of Telecom's. What the object buys is that the framework, the
 * notification shade and a headset all speak about the group rather than about whichever leg was
 * answered last.
 *
 * Every callback here is logged and forwarded to the same dispatcher the connections use, so the
 * application hears about a group the user acted on exactly as it hears about a call.
 */
class PhoneConference(
    phoneAccountHandle: PhoneAccountHandle,
) : Conference(phoneAccountHandle) {
    private val logger = Log(TAG)

    init {
        // Without this Telecom files the group as an ordinary managed call: it arrives with no
        // self-managed property, the system dialer is bound to it and puts our conference in the
        // platform in-call screen, which is the one thing a self-managed application owns itself.
        // The property does not travel from the connections; the conference has to claim it.
        connectionProperties = Connection.PROPERTY_SELF_MANAGED
        connectionCapabilities =
            Connection.CAPABILITY_SUPPORT_HOLD or
            Connection.CAPABILITY_HOLD or
            Connection.CAPABILITY_MUTE or
            Connection.CAPABILITY_MANAGE_CONFERENCE
        // A group exists because calls in it are already up, so it is active from the start.
        // Telecom otherwise leaves it in NEW and never routes audio to it.
        setActive()
    }

    override fun onDisconnect() {
        logger.i("onDisconnect: ending every call in the group")
        connections.toList().forEach { it.onDisconnect() }
        setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
        destroy()
    }

    override fun onSeparate(connection: Connection) {
        logger.i("onSeparate: taking one call out of the group")
        removeConnection(connection)
    }

    override fun onMerge(connection: Connection) {
        logger.i("onMerge: adding one call to the group")
        addConnection(connection)
    }

    /**
     * Takes the group apart once fewer than two calls are left in it.
     *
     * A group of one is not a group, and Telecom keeps an emptied conference alive as a managed
     * call of its own - with a chip in the status bar - until the process dies. So the last call
     * is let go, made active if Telecom had held it as a child, and the conference is ended.
     *
     * Returns true when the conference was taken apart.
     */
    fun dissolveIfLonely(): Boolean {
        if (connections.size >= 2) return false
        dissolve()
        return true
    }

    /** Takes the group apart whatever its size: every call leaves, held ones made active. */
    fun dissolve() {
        val left = connections.toList()
        logger.i("dissolveIfLonely: ${left.size} call(s) left, ending the group")
        left.forEach { removeConnection(it) }
        setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
        destroy()
        left.filter { it.state == Connection.STATE_HOLDING }.forEach { it.setActive() }
    }

    // Once the group is the foreground call, Telecom addresses the audio route, the endpoint
    // list and the microphone state to the conference, not to its calls - measured on a Pixel:
    // the route change after a speaker tap arrived here with the conference id. Each call keeps
    // reporting to the application under its own id, so the group hands them on.

    private inline fun eachCall(block: (PhoneConnection) -> Unit) = connections.filterIsInstance<PhoneConnection>().forEach(block)

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    override fun onCallEndpointChanged(callEndpoint: CallEndpoint) {
        super.onCallEndpointChanged(callEndpoint)
        logger.d("onCallEndpointChanged: $callEndpoint, handing on to ${connections.size} calls")
        eachCall { it.onCallEndpointChanged(callEndpoint) }
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    override fun onAvailableCallEndpointsChanged(callEndpoints: List<CallEndpoint>) {
        super.onAvailableCallEndpointsChanged(callEndpoints)
        eachCall { it.onAvailableCallEndpointsChanged(callEndpoints) }
    }

    @RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    override fun onMuteStateChanged(isMuted: Boolean) {
        super.onMuteStateChanged(isMuted)
        eachCall { it.onMuteStateChanged(isMuted) }
    }

    @Suppress("DEPRECATION")
    override fun onCallAudioStateChanged(state: CallAudioState?) {
        super.onCallAudioStateChanged(state)
        eachCall { it.onCallAudioStateChanged(state) }
    }

    override fun onHold() {
        logger.i("onHold: the group was held")
        setOnHold()
    }

    override fun onUnhold() {
        logger.i("onUnhold: the group was resumed")
        setActive()
    }

    companion object {
        private const val TAG = "PhoneConference"
    }
}
