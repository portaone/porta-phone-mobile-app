package com.webtrit.callkeep.services.core

import com.webtrit.callkeep.models.CallMetadata

/**
 * Incoming calls the core holds back from Telecom while another incoming call rings.
 *
 * Telecom lets one self-managed incoming call ring at a time and refuses the next one; the app
 * would then have to decline it on the server. Instead the core keeps it here, in arrival order,
 * and puts it through when the ringing call is over: the oldest waiting call goes first, unless
 * the user chose one to answer, which then goes first and is answered as soon as it rings.
 *
 * Thread-safe: the push session reports a call's end from a Pigeon background thread.
 */
internal class IncomingCallQueue {
    /**
     * A waiting call; [answerOnRaise] when the user chose to answer it once it is put through,
     * [waitForIdle] when Telecom refused it beside a live call and it waits for no call at all.
     */
    data class Entry(
        val metadata: CallMetadata,
        val answerOnRaise: Boolean = false,
        val waitForIdle: Boolean = false,
    ) {
        val callId: String get() = metadata.callId
    }

    private val entries = LinkedHashMap<String, Entry>()

    @Synchronized
    fun contains(callId: String): Boolean = callId in entries

    @Synchronized
    fun isEmpty(): Boolean = entries.isEmpty()

    /** Call ids in arrival order. */
    @Synchronized
    fun callIds(): List<String> = entries.keys.toList()

    /**
     * Adds [metadata] at the end, or merges it into the entry already waiting with that id (a
     * second report of the same call, say the push after the signaling) without moving it.
     * True when the call was not waiting before.
     */
    @Synchronized
    fun add(
        metadata: CallMetadata,
        waitForIdle: Boolean = false,
    ): Boolean {
        val existing = entries[metadata.callId]
        if (existing != null) {
            entries[metadata.callId] =
                existing.copy(metadata = existing.metadata.mergeWith(metadata), waitForIdle = existing.waitForIdle || waitForIdle)
            return false
        }
        entries[metadata.callId] = Entry(metadata, waitForIdle = waitForIdle)
        return true
    }

    /** Takes [callId] out of the queue; the entry, or null when it was not waiting. */
    @Synchronized
    fun remove(callId: String): Entry? = entries.remove(callId)

    /** Marks [callId] to be answered once it is put through; the entry, or null when it is not waiting. */
    @Synchronized
    fun markAnswerOnRaise(callId: String): Entry? {
        val existing = entries[callId] ?: return null
        return existing.copy(answerOnRaise = true).also { entries[callId] = it }
    }

    /**
     * Takes out the call to put through next: one chosen to be answered, else the oldest. While
     * another call is live ([idle] false) a call that waits for no call at all stays.
     */
    @Synchronized
    fun pollNext(idle: Boolean = true): Entry? {
        val ready = entries.values.filter { idle || !it.waitForIdle }
        val next = ready.firstOrNull { it.answerOnRaise } ?: ready.firstOrNull() ?: return null
        entries.remove(next.callId)
        return next
    }

    /** Empties the queue; the call ids that were waiting. */
    @Synchronized
    fun clear(): List<String> {
        val ids = entries.keys.toList()
        entries.clear()
        return ids
    }
}
