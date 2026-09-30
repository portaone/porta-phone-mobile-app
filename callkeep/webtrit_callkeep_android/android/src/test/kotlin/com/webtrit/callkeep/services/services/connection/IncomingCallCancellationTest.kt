package com.webtrit.callkeep.services.services.connection

import android.app.Application
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Looper
import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.PhoneAccountHandle
import com.webtrit.callkeep.models.CallGroup
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.models.FailureMetadata
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.core.CallkeepCore
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.LooperMode

/** A final registration rejection must cancel native creation as well as an existing call. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
@LooperMode(LooperMode.Mode.PAUSED)
class IncomingCallCancellationTest {
    private lateinit var service: PhoneConnectionService
    private val app: Application = RuntimeEnvironment.getApplication()
    private lateinit var account: PhoneAccountHandle
    private val metadata = CallMetadata(callId = "cancelled-incoming", displayName = "Caller")

    @Before
    fun setUp() {
        ConnectionManager.instance = ConnectionManager()
        service = Robolectric.buildService(PhoneConnectionService::class.java).create().get()
        account = PhoneAccountHandle(ComponentName(service, PhoneConnectionService::class.java), "test")
        clearStandalone()
        shadowOf(app).clearBroadcastIntents()
    }

    @After
    fun tearDown() {
        ConnectionManager.instance.cleanConnections()
        CallkeepCore.instance.clear()
        clearStandalone()
    }

    private fun clearStandalone() {
        StandaloneCallService.connections.clear()
        StandaloneCallService.pendingAnswers.clear()
        StandaloneCallService.ringingIncomingCallIds.clear()
        StandaloneCallService.cancelledIncomingCallIds.clear()
        StandaloneCallService.callGroup = CallGroup.empty
    }

    private fun send(action: ServiceAction) {
        service.onStartCommand(
            Intent(service, PhoneConnectionService::class.java).apply {
                this.action = action.action
                putExtras(metadata.toBundle())
            },
            0,
            1,
        )
    }

    private fun createIncoming(): Connection = service.onCreateIncomingConnection(account, ConnectionRequest(account, Uri.EMPTY, metadata.toBundle()))

    @Test
    fun `cancellation before Telecom creation rejects the late callback without a pending slot`() {
        assertFalse(ConnectionManager.instance.isPending(metadata.callId))
        send(ServiceAction.CancelIncomingCall)

        val connection = createIncoming()

        assertEquals(Connection.STATE_DISCONNECTED, connection.state)
        assertNull(ConnectionManager.instance.getConnection(metadata.callId))
        assertFalse(ConnectionManager.instance.isPending(metadata.callId))
    }

    @Test
    fun `rejecting a cancelled Telecom callback reports failure to the main process`() {
        send(ServiceAction.CancelIncomingCall)

        createIncoming()

        val failure = shadowOf(app).broadcastIntents.single { it.action == CallLifecycleEvent.IncomingFailure.name }
        assertEquals(metadata.callId, FailureMetadata.fromBundle(failure.extras!!).callMetadata?.callId)
    }

    @Test
    fun `cancelled creation stays rejected after repeated backend cleanup`() {
        send(ServiceAction.CancelIncomingCall)
        repeat(2) { send(ServiceAction.CleanConnections) }

        assertEquals(Connection.STATE_DISCONNECTED, createIncoming().state)
        assertTrue(ConnectionManager.instance.isIncomingCallCancelled(metadata.callId))
    }

    @Test
    fun `cancellation disconnects an already created ringing connection`() {
        val connection = createIncoming()
        assertEquals(Connection.STATE_RINGING, connection.state)

        send(ServiceAction.CancelIncomingCall)

        assertEquals(Connection.STATE_DISCONNECTED, connection.state)
        assertFalse(ConnectionManager.instance.isPending(metadata.callId))
    }

    @Test
    fun `cancellation drains deferred answers and ignores a later reservation`() {
        send(ServiceAction.ReserveAnswer)
        send(ServiceAction.CancelIncomingCall)
        send(ServiceAction.ReserveAnswer)

        assertFalse(ConnectionManager.instance.consumeAnswer(metadata.callId))
        assertEquals(Connection.STATE_DISCONNECTED, createIncoming().state)
    }

    @Test
    fun `cancellation before the posted deferred answer keeps the connection disconnected`() {
        send(ServiceAction.ReserveAnswer)
        val connection = createIncoming() as PhoneConnection
        assertFalse(connection.hasAnswered)
        send(ServiceAction.CancelIncomingCall)

        shadowOf(Looper.getMainLooper()).idle()

        assertEquals(Connection.STATE_DISCONNECTED, connection.state)
        assertFalse(connection.hasAnswered)
    }

    @Test
    fun `a late native answer after cancellation cannot reactivate the connection`() {
        val connection = createIncoming() as PhoneConnection
        send(ServiceAction.CancelIncomingCall)

        connection.onAnswer()

        assertEquals(Connection.STATE_DISCONNECTED, connection.state)
        assertFalse(connection.hasAnswered)
    }

    @Test
    fun `ordinary hangup does not permanently cancel a presented call UUID`() {
        val connection = createIncoming()
        send(ServiceAction.HungUpCall)
        assertEquals(Connection.STATE_DISCONNECTED, connection.state)
        send(ServiceAction.CleanConnections)

        assertEquals(Connection.STATE_RINGING, createIncoming().state)
        assertFalse(ConnectionManager.instance.isIncomingCallCancelled(metadata.callId))
    }

    private fun standalone(): StandaloneCallService = Robolectric.buildService(StandaloneCallService::class.java).create().get()

    private fun sendStandalone(
        service: StandaloneCallService,
        action: StandaloneServiceAction,
    ) {
        service.onStartCommand(
            Intent(service, StandaloneCallService::class.java).apply {
                this.action = action.action
                putExtras(metadata.toBundle())
            },
            0,
            1,
        )
    }

    @Test
    fun `standalone cancellation before queued setup prevents ringing and answering`() {
        val standalone = standalone()
        sendStandalone(standalone, StandaloneServiceAction.CancelIncomingCall)
        sendStandalone(standalone, StandaloneServiceAction.IncomingCall)
        sendStandalone(standalone, StandaloneServiceAction.ReserveAnswer)
        sendStandalone(standalone, StandaloneServiceAction.AnswerCall)

        assertFalse(StandaloneCallService.connections.containsKey(metadata.callId))
        assertFalse(metadata.callId in StandaloneCallService.ringingIncomingCallIds)
        assertFalse(metadata.callId in StandaloneCallService.pendingAnswers)
    }

    @Test
    fun `standalone cancellation ends an already ringing connection`() {
        val standalone = standalone()
        sendStandalone(standalone, StandaloneServiceAction.IncomingCall)
        assertTrue(metadata.callId in StandaloneCallService.ringingIncomingCallIds)

        sendStandalone(standalone, StandaloneServiceAction.CancelIncomingCall)

        assertFalse(StandaloneCallService.connections.containsKey(metadata.callId))
        assertFalse(metadata.callId in StandaloneCallService.ringingIncomingCallIds)
    }

    @Test
    fun `standalone cancellation survives session cleanup and a service restart`() {
        val standalone = standalone()
        sendStandalone(standalone, StandaloneServiceAction.CancelIncomingCall)
        sendStandalone(standalone, StandaloneServiceAction.CleanConnections)

        sendStandalone(standalone(), StandaloneServiceAction.IncomingCall)

        assertFalse(StandaloneCallService.connections.containsKey(metadata.callId))
        assertFalse(metadata.callId in StandaloneCallService.ringingIncomingCallIds)
    }
}
