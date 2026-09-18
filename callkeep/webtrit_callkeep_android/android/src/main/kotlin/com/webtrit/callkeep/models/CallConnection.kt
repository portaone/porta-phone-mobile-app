package com.webtrit.callkeep.models

/**
 * Callkeep-owned state of one call, shared by the Telecom and standalone adapters.
 *
 * Contains no Telecom objects or side effects. The owning backend serializes mutations and
 * performs audio, notification and IPC work after updating this object. A Telecom connection's
 * framework state is separate: a platform-only hold must not change this call's logical state.
 * Metadata remains the existing IPC payload; this object never crosses a process boundary.
 */
class CallConnection(
    metadata: CallMetadata,
    initialState: CallConnectionState = CallConnectionState.NEW,
    initiallyMuted: Boolean = metadata.hasMute ?: false,
) {
    val callId: String = metadata.callId

    var metadata: CallMetadata = metadata
        private set

    var state: CallConnectionState = initialState
        private set

    var hasAnswered: Boolean = false
        private set

    var hasMute: Boolean = initiallyMuted
        private set

    /** A partial update cannot replace the identity or implicitly answer a call. */
    fun updateMetadata(update: CallMetadata) {
        require(update.callId == callId) { "Cannot change a connection's call id" }
        metadata = metadata.mergeWith(update)
    }

    /** Records an explicit answer; outgoing activation alone is not an incoming answer. */
    fun answer(acceptedTime: Long? = null) {
        if (state == CallConnectionState.DISCONNECTED) return
        hasAnswered = true
        state = CallConnectionState.ACTIVE
        if (acceptedTime != null) metadata = metadata.copy(acceptedTime = acceptedTime)
    }

    /** Observes a logical transition, leaving terminal connections terminal. */
    fun transitionTo(next: CallConnectionState) {
        if (state == CallConnectionState.DISCONNECTED) return
        state = next
    }

    fun setHeld(held: Boolean) {
        if (state == CallConnectionState.DISCONNECTED) return
        metadata = metadata.copy(hasHold = held)
        state = if (held) CallConnectionState.HOLDING else CallConnectionState.ACTIVE
    }

    fun setMuted(muted: Boolean) {
        if (state == CallConnectionState.DISCONNECTED) return
        hasMute = muted
        metadata = metadata.copy(hasMute = muted)
    }
}
