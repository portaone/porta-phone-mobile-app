package com.webtrit.callkeep.services.core

import java.util.UUID

/**
 * Role: the one owner of call attempts in the main process. The server reuses a SIP Call-ID
 * (a transfer back, a retried transfer, the legs of a forked call), so the call id names a
 * conversation, not a call on this phone. Each offer of an incoming call is resolved here to an
 * attempt with an [Attempt.instanceId] of its own, and every store that has to remember a call
 * after it ended keys that memory by the attempt, never by the call id: a new attempt of the same
 * id is then never refused by what an earlier one left behind.
 *
 * Callers: the incoming registration of [InProcessCallkeepCore] (each report of an incoming call,
 * from the app's signaling, a push or a handshake replay, goes through [resolve]) and the end of
 * a call ([end]).
 *
 * Steps of [resolve]: a live attempt of the call id is the same call (the push and the socket of
 * one offer join); with no live attempt, the last ended attempt of the id decides whether the
 * offer is a late copy of it (a ghost) or a new attempt; with neither, it is new.
 *
 * Not here: Telecom, the queue of waiting calls, registration timeouts - [InProcessCallkeepCore];
 * per-call connection state - [MainProcessConnectionTracker].
 *
 * Thread-safety: every public method is synchronized on this instance.
 */
internal class CallAttempts(
    private val now: () -> Long = System::currentTimeMillis,
    private val newInstanceId: () -> String = { UUID.randomUUID().toString() },
    private val endedLimit: Int = ENDED_LIMIT,
    private val endedTtlMs: Long = ENDED_TTL_MS,
) {
    /**
     * Where the time of an offer comes from.
     *
     * TEMPORARY(old Core without offered_at): [FCM] and [DEVICE] exist only while the app supports
     * a Core that does not send `offered_at` (the incoming_call event, `offeredAt` of the push).
     * Remove them, and the branches of [resolve] that use them, once the app's minimum supported
     * Core (WEBTRIT_APP_CORE_VERSION_CONSTRAINT) sends it.
     */
    enum class OfferTimeSource {
        /** Core's `offered_at`: taken once per offer, the same value on every path. Compared by equality. */
        CORE,

        /** TEMPORARY(old Core without offered_at): the FCM message's sentTime. */
        FCM,

        /** TEMPORARY(old Core without offered_at): when this phone received the offer. */
        DEVICE,
    }

    data class OfferTime(
        val ms: Long,
        val source: OfferTimeSource,
    )

    /** How the offer reached the app. A socket delivers in order, so an offer on it after a hangup is new. */
    enum class Via { SOCKET, PUSH, HANDSHAKE, OTHER }

    data class Attempt(
        val instanceId: String,
        val callId: String,
        val offeredAt: OfferTime?,
        val endedAtMs: Long? = null,
    ) {
        val ended: Boolean get() = endedAtMs != null
    }

    sealed interface Decision {
        val attempt: Attempt

        /** The live attempt of this call id: another delivery of the same offer. */
        data class Same(
            override val attempt: Attempt,
        ) : Decision

        /** A new attempt, live from now on. */
        data class New(
            override val attempt: Attempt,
        ) : Decision

        /** A late copy of the ended [attempt]: not to be presented. */
        data class Ghost(
            override val attempt: Attempt,
        ) : Decision

        /**
         * TEMPORARY(old Core without offered_at): a new attempt that may be a ghost, since the offer
         * carries no time to tell. It is live and is presented, as an offer was before this registry:
         * nothing here confirms it later.
         */
        data class Unconfirmed(
            override val attempt: Attempt,
        ) : Decision
    }

    private val live = HashMap<String, Attempt>()
    private val lastEnded = LinkedHashMap<String, Attempt>()
    private val byInstance = HashMap<String, Attempt>()

    @Synchronized
    fun resolve(
        callId: String,
        offeredAt: OfferTime?,
        via: Via,
    ): Decision {
        dropExpired()
        live[callId]?.let { current ->
            // A copy of the offer on a stronger clock (Core's) replaces the weaker one, so a later
            // late push of this attempt compares by equality.
            val upgraded =
                if (offeredAt?.source == OfferTimeSource.CORE && current.offeredAt?.source != OfferTimeSource.CORE) {
                    current.copy(offeredAt = offeredAt).also(::store)
                } else {
                    current
                }
            return Decision.Same(upgraded)
        }
        val ended = lastEnded[callId] ?: return Decision.New(start(callId, offeredAt))
        if (via == Via.SOCKET) return Decision.New(start(callId, offeredAt))
        if (offeredAt != null && offeredAt.source == OfferTimeSource.CORE && ended.offeredAt?.source == OfferTimeSource.CORE) {
            return if (offeredAt.ms == ended.offeredAt.ms) Decision.Ghost(ended) else Decision.New(start(callId, offeredAt))
        }
        // TEMPORARY(old Core without offered_at): no equality to go by. An offer with a server-side
        // time (Core's or FCM's) after the end is new, at or before it a ghost; the end is this
        // phone's time, so a clock that is off moves the line.
        if (offeredAt != null && offeredAt.source != OfferTimeSource.DEVICE) {
            val endedAt = ended.endedAtMs ?: return Decision.New(start(callId, offeredAt))
            return if (offeredAt.ms > endedAt) Decision.New(start(callId, offeredAt)) else Decision.Ghost(ended)
        }
        return Decision.Unconfirmed(start(callId, offeredAt))
    }

    /** The attempt [instanceId] ended at [atMs]; a second end of it changes nothing. */
    @Synchronized
    fun end(
        instanceId: String,
        atMs: Long = now(),
    ): Attempt? {
        val attempt = byInstance[instanceId] ?: return null
        if (attempt.ended) return attempt
        val ended = attempt.copy(endedAtMs = atMs)
        if (live[attempt.callId]?.instanceId == instanceId) live.remove(attempt.callId)
        // Only the last ended attempt of a call id is kept: the one it supersedes is forgotten.
        lastEnded.remove(attempt.callId)?.let { superseded -> byInstance.remove(superseded.instanceId) }
        lastEnded[attempt.callId] = ended
        byInstance[instanceId] = ended
        dropExpired()
        return ended
    }

    @Synchronized
    fun get(instanceId: String): Attempt? = byInstance[instanceId]

    @Synchronized
    fun liveFor(callId: String): Attempt? = live[callId]

    /** The session ends (tearDown): every attempt is forgotten. */
    @Synchronized
    fun clear() {
        live.clear()
        lastEnded.clear()
        byInstance.clear()
    }

    private fun start(
        callId: String,
        offeredAt: OfferTime?,
    ): Attempt = Attempt(instanceId = newInstanceId(), callId = callId, offeredAt = offeredAt).also(::store)

    private fun store(attempt: Attempt) {
        byInstance[attempt.instanceId] = attempt
        if (!attempt.ended) live[attempt.callId] = attempt
    }

    private fun dropExpired() {
        val oldest = now() - endedTtlMs
        val iterator = lastEnded.entries.iterator()
        while (iterator.hasNext()) {
            val (_, attempt) = iterator.next()
            val tooMany = lastEnded.size > endedLimit
            if (!tooMany && (attempt.endedAtMs ?: Long.MAX_VALUE) >= oldest) break
            iterator.remove()
            byInstance.remove(attempt.instanceId)
        }
    }

    companion object {
        /** Ended attempts kept to tell a late copy from a new offer; a late push comes within seconds. */
        const val ENDED_LIMIT = 64
        const val ENDED_TTL_MS = 10 * 60 * 1000L
    }
}
