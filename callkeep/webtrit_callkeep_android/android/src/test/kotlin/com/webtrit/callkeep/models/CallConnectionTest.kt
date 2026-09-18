package com.webtrit.callkeep.models

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

class CallConnectionTest {
    @Test
    fun `partial metadata preserves identity and other fields`() {
        val call = CallConnection(CallMetadata(callId = "a", displayName = "Alice", hasVideo = true))
        call.updateMetadata(CallMetadata(callId = "a", hasVideo = false))
        assertEquals("Alice", call.metadata.displayName)
        assertEquals(false, call.metadata.hasVideo)
        assertFalse(call.hasAnswered)
    }

    @Test
    fun `another call cannot overwrite this connection`() {
        val call = CallConnection(CallMetadata(callId = "a"))
        assertThrows(IllegalArgumentException::class.java) { call.updateMetadata(CallMetadata(callId = "b")) }
        assertEquals("a", call.metadata.callId)
    }

    @Test
    fun `incoming answer survives hold unhold mute and metadata changes`() {
        val call = CallConnection(CallMetadata(callId = "a"), CallConnectionState.RINGING)
        call.answer(123L)
        call.setHeld(true)
        call.setMuted(true)
        call.updateMetadata(CallMetadata(callId = "a", displayName = "Alice"))
        assertTrue(call.hasAnswered)
        assertTrue(call.hasMute)
        assertEquals(123L, call.metadata.acceptedTime)
        assertEquals(CallConnectionState.HOLDING, call.state)
        call.setHeld(false)
        assertEquals(CallConnectionState.ACTIVE, call.state)
        assertEquals(false, call.metadata.hasHold)
        call.setMuted(false)
        assertFalse(call.hasMute)
    }

    @Test
    fun `activation does not invent an incoming answer`() {
        val call = CallConnection(CallMetadata(callId = "a"), CallConnectionState.DIALING)
        call.transitionTo(CallConnectionState.ACTIVE)
        assertFalse(call.hasAnswered)
        assertNull(call.metadata.acceptedTime)
    }

    @Test
    fun `connection state in an IPC payload does not drive the lifecycle`() {
        val call = CallConnection(CallMetadata(callId = "a"), CallConnectionState.RINGING)
        call.updateMetadata(CallMetadata(callId = "a", connectionState = CallConnectionState.ACTIVE))
        assertEquals(CallConnectionState.RINGING, call.state)
        assertFalse(call.hasAnswered)
    }

    @Test
    fun `terminal connection cannot be reopened by a late answer or media command`() {
        val call = CallConnection(CallMetadata(callId = "a"))
        call.transitionTo(CallConnectionState.DISCONNECTED)
        call.answer(123L)
        call.transitionTo(CallConnectionState.ACTIVE)
        call.setHeld(false)
        call.setMuted(true)
        assertEquals(CallConnectionState.DISCONNECTED, call.state)
        assertFalse(call.hasAnswered)
        assertFalse(call.hasMute)
        assertNull(call.metadata.acceptedTime)
    }

    @Test
    fun `connections own independent lifecycle and media state`() {
        val a = CallConnection(CallMetadata(callId = "a"))
        val b = CallConnection(CallMetadata(callId = "b"))
        a.answer()
        a.setMuted(true)
        a.setHeld(true)
        assertEquals(CallConnectionState.NEW, b.state)
        assertFalse(b.hasAnswered)
        assertFalse(b.hasMute)
    }
}
