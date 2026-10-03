package com.webtrit.callkeep.services.core

import com.webtrit.callkeep.models.CallMetadata
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class IncomingCallQueueTest {
    private val queue = IncomingCallQueue()

    @Test
    fun `calls come out oldest first`() {
        queue.add(CallMetadata(callId = "b"))
        queue.add(CallMetadata(callId = "c"))

        assertEquals("b", queue.pollNext()?.callId)
        assertEquals("c", queue.pollNext()?.callId)
        assertNull(queue.pollNext())
    }

    @Test
    fun `a call chosen to be answered comes out first`() {
        queue.add(CallMetadata(callId = "b"))
        queue.add(CallMetadata(callId = "c"))

        assertTrue(queue.markAnswerOnRaise("c")!!.answerOnRaise)

        val next = queue.pollNext()
        assertEquals("c", next?.callId)
        assertTrue(next!!.answerOnRaise)
        assertEquals("b", queue.pollNext()?.callId)
    }

    @Test
    fun `a second report merges into the waiting call without moving it`() {
        queue.add(CallMetadata(callId = "b"))
        queue.add(CallMetadata(callId = "c"))

        assertFalse(queue.add(CallMetadata(callId = "b", displayName = "Bob")))

        val first = queue.pollNext()
        assertEquals("b", first?.callId)
        assertEquals("Bob", first?.metadata?.displayName)
    }

    @Test
    fun `a call that waits for no call at all stays while another call is live`() {
        queue.add(CallMetadata(callId = "b"), waitForIdle = true)
        queue.add(CallMetadata(callId = "c"))

        assertEquals("c", queue.pollNext(idle = false)?.callId)
        assertNull(queue.pollNext(idle = false))
        assertEquals("b", queue.pollNext(idle = true)?.callId)
    }

    @Test
    fun `remove and clear take calls out`() {
        queue.add(CallMetadata(callId = "b"))
        queue.add(CallMetadata(callId = "c"))

        assertEquals("b", queue.remove("b")?.callId)
        assertNull(queue.remove("b"))
        assertNull(queue.markAnswerOnRaise("b"))
        assertEquals(listOf("c"), queue.clear())
        assertTrue(queue.isEmpty())
    }
}
