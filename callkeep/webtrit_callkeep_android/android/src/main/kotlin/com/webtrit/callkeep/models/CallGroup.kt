package com.webtrit.callkeep.models

/**
 * Immutable membership of the one group owned by a call backend.
 *
 * Membership is independent of Telecom, notifications and media. Adapters apply the resulting
 * snapshot to their presentation. A single member is never a group; an empty declaration is
 * deliberately a no-op, whereas removing all members ends the group.
 */
class CallGroup private constructor(
    val id: String?,
    val members: Set<String>,
) {
    val isEmpty: Boolean get() = members.isEmpty()

    operator fun contains(callId: String): Boolean = callId in members

    /** Declares the whole membership, retaining identity while any member survives. */
    fun declare(
        callIds: Collection<String>,
        newId: () -> String,
    ): CallGroup {
        if (callIds.isEmpty()) return this
        val next = callIds.toSet()
        if (next.size < 2) return empty
        val nextId = id?.takeIf { next.any { it in members } } ?: newId()
        return of(nextId, next)
    }

    /** Also used for a call that ended, so all exit paths dissolve a lone survivor. */
    fun without(callIds: Collection<String>): CallGroup = if (id == null || callIds.isEmpty()) this else of(id, members - callIds.toSet())

    override fun equals(other: Any?): Boolean = other is CallGroup && id == other.id && members == other.members

    override fun hashCode(): Int = 31 * (id?.hashCode() ?: 0) + members.hashCode()

    companion object {
        val empty = CallGroup(null, emptySet())

        /** Takes an owned snapshot; duplicate ids do not count as separate participants. */
        fun of(
            id: String,
            callIds: Collection<String>,
        ): CallGroup {
            val members = callIds.toSet()
            return if (members.size < 2) empty else CallGroup(id, java.util.Collections.unmodifiableSet(members))
        }
    }
}
