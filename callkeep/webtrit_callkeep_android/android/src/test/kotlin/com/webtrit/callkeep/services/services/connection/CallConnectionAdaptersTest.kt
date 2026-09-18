package com.webtrit.callkeep.services.services.connection

import android.os.Build
import android.telecom.Connection
import android.telecom.DisconnectCause
import com.webtrit.callkeep.models.CallConnectionState
import com.webtrit.callkeep.models.CallGroup
import com.webtrit.callkeep.models.CallMetadata
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class CallConnectionAdaptersTest {
    private lateinit var service: StandaloneCallService

    @Before
    fun setUp() {
        StandaloneCallService.connections.clear()
        StandaloneCallService.ringingIncomingCallIds.clear()
        StandaloneCallService.pendingAnswers.clear()
        StandaloneCallService.callGroup = CallGroup.empty
        PhoneConnectionService.connectionManager = ConnectionManager()
        service = Robolectric.buildService(StandaloneCallService::class.java).create().get()
    }

    @After
    fun tearDown() {
        StandaloneCallService::class.java
            .getDeclaredMethod("handleCleanConnections")
            .apply {
                isAccessible = true
            }.invoke(service)
    }

    private fun invoke(
        name: String,
        metadata: CallMetadata,
    ) {
        StandaloneCallService::class.java
            .getDeclaredMethod(name, CallMetadata::class.java)
            .apply {
                isAccessible = true
            }.invoke(service, metadata)
    }

    @Test
    fun `Telecom lifecycle and media callbacks update the shared connection`() {
        val phone = PhoneConnection(service, { _, _ -> }, CallMetadata(callId = "a"), {})
        phone.setRinging()
        assertEquals(CallConnectionState.RINGING, phone.callConnection.state)
        phone.onAnswer()
        phone.onHold()
        phone.changeMuteState(true)
        phone.updateData(CallMetadata(callId = "a", displayName = "Alice"))
        assertTrue(phone.hasAnswered)
        assertEquals("Alice", phone.callConnection.metadata.displayName)
        assertTrue(phone.callConnection.hasMute)
        assertEquals(CallConnectionState.HOLDING, phone.callConnection.state)
        phone.onUnhold()
        assertEquals(CallConnectionState.ACTIVE, phone.callConnection.state)
        phone.setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
        assertEquals(CallConnectionState.DISCONNECTED, phone.callConnection.state)
    }

    @Test
    fun `Telecom-only hold stays separate from logical call state`() {
        val phone = PhoneConnection(service, { _, _ -> }, CallMetadata(callId = "a"), {})
        phone.setActive()
        val other = PhoneConnection(service, { _, _ -> }, CallMetadata(callId = "b"), {})
        other.setActive()
        PhoneConnectionService.connectionManager.addConnection("a", phone)
        PhoneConnectionService.connectionManager.addConnection("b", other)
        PhoneConnectionService.applyCallGroup(setOf("a", "b"))
        phone.onHold()
        assertEquals(Connection.STATE_HOLDING, phone.state)
        assertEquals(CallConnectionState.ACTIVE, phone.callConnection.state)
        PhoneConnectionService.applyCallGroup(emptySet())
        assertEquals(Connection.STATE_HOLDING, phone.state)
        assertEquals(CallConnectionState.ACTIVE, phone.callConnection.state)
        phone.onHold()
        assertEquals(CallConnectionState.HOLDING, phone.callConnection.state)
    }

    @Test
    fun `standalone commands retain one shared connection until hangup`() {
        val metadata = CallMetadata(callId = "a", displayName = "Alice")
        invoke("handleOutgoingCall", metadata)
        val call = StandaloneCallService.connections.getValue("a")
        assertEquals(CallConnectionState.DIALING, call.state)
        invoke("handleEstablishCall", CallMetadata(callId = "a"))
        invoke("handleHolding", CallMetadata(callId = "a", hasHold = true))
        invoke("handleMuting", CallMetadata(callId = "a", hasMute = true))
        invoke("handleUpdateCall", CallMetadata(callId = "a", hasVideo = true))
        assertSame(call, StandaloneCallService.connections.getValue("a"))
        assertTrue(call.hasAnswered)
        assertEquals(setOf("a"), StandaloneCallService.answeredCallIds)
        assertEquals("Alice", call.metadata.displayName)
        assertEquals(true, call.metadata.hasVideo)
        assertTrue(call.hasMute)
        assertEquals(CallConnectionState.HOLDING, call.state)
        invoke("handleHolding", CallMetadata(callId = "a", hasHold = false))
        assertEquals(CallConnectionState.ACTIVE, call.state)
        invoke("handleHungUpCall", CallMetadata(callId = "a"))
        assertEquals(CallConnectionState.DISCONNECTED, call.state)
        assertTrue(StandaloneCallService.connections.isEmpty())
        assertTrue(StandaloneCallService.answeredCallIds.isEmpty())
    }

    @Test
    fun `incoming registration resets a reused id without leaking the old answer`() {
        val metadata = CallMetadata(callId = "a", displayName = "Alice")
        invoke("handleIncomingCall", metadata)
        val old = StandaloneCallService.connections.getValue("a")
        assertEquals(CallConnectionState.RINGING, old.state)
        invoke("handleAnswerCall", metadata)
        assertTrue(old.hasAnswered)
        invoke("handleHungUpCall", metadata)
        invoke("handleIncomingCall", metadata.copy(displayName = "Bob"))
        val fresh = StandaloneCallService.connections.getValue("a")
        assertNotSame(old, fresh)
        assertFalse(fresh.hasAnswered)
        assertEquals(CallConnectionState.RINGING, fresh.state)
        assertEquals("Bob", fresh.metadata.displayName)
    }

    @Test
    fun `Telecom state conversion covers known states and ignores unknown ones`() {
        assertEquals(CallConnectionState.INITIALIZING, telecomConnectionState(Connection.STATE_INITIALIZING))
        assertEquals(CallConnectionState.NEW, telecomConnectionState(Connection.STATE_NEW))
        assertEquals(CallConnectionState.RINGING, telecomConnectionState(Connection.STATE_RINGING))
        assertEquals(CallConnectionState.DIALING, telecomConnectionState(Connection.STATE_DIALING))
        assertEquals(CallConnectionState.ACTIVE, telecomConnectionState(Connection.STATE_ACTIVE))
        assertEquals(CallConnectionState.HOLDING, telecomConnectionState(Connection.STATE_HOLDING))
        assertEquals(CallConnectionState.DISCONNECTED, telecomConnectionState(Connection.STATE_DISCONNECTED))
        assertNull(telecomConnectionState(-1))
    }

    private fun invokeGroup(
        name: String,
        ids: List<String>,
    ) {
        StandaloneCallService::class.java
            .getDeclaredMethod(name, List::class.java)
            .apply {
                isAccessible = true
            }.invoke(service, ids)
    }

    @Test
    fun `standalone membership follows declaration withdrawal and call end`() {
        listOf("a", "b", "c").forEach {
            invoke("handleOutgoingCall", CallMetadata(callId = it))
        }
        invokeGroup("handleSetCallGroup", listOf("a", "b", "c"))
        assertEquals(setOf("a", "b", "c"), StandaloneCallService.callGroup.members)
        invokeGroup("handleUnsetCallGroup", listOf("c"))
        assertEquals(setOf("a", "b"), StandaloneCallService.callGroup.members)
        invoke("handleHungUpCall", CallMetadata(callId = "a"))
        assertTrue(StandaloneCallService.callGroup.isEmpty)
        assertEquals(setOf("b", "c"), StandaloneCallService.connections.keys)
    }

    @Test
    fun `clean ends owned connections and clears membership and answer facts`() {
        listOf("a", "b").forEach {
            invoke("handleOutgoingCall", CallMetadata(callId = it))
            invoke("handleEstablishCall", CallMetadata(callId = it))
        }
        val calls = StandaloneCallService.connections.values.toList()
        invokeGroup("handleSetCallGroup", listOf("a", "b"))
        tearDown()
        assertTrue(calls.all { it.state == CallConnectionState.DISCONNECTED })
        assertTrue(StandaloneCallService.callGroup.isEmpty)
        assertTrue(StandaloneCallService.connections.isEmpty())
        assertTrue(StandaloneCallService.answeredCallIds.isEmpty())
    }
}
