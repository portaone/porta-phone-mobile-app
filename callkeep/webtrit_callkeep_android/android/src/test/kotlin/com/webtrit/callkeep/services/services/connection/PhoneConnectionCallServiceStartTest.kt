package com.webtrit.callkeep.services.services.connection

import android.app.Application
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Looper
import android.telecom.ConnectionRequest
import android.telecom.DisconnectCause
import android.telecom.PhoneAccountHandle
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.managers.NotificationManager
import com.webtrit.callkeep.models.CallConnectionState
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.services.active_call.ActiveCallService
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.mock
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * When the call service of the Telecom path starts for a call.
 *
 * The call service holds the microphone foreground type that lets the app keep recording in the
 * background. Since Android 14 the system grants that type only to a service started while the
 * app is visible. An outgoing call is placed from the app, so its service starts as soon as
 * Telecom has taken the connection - before the other side answers, while the user can still be
 * looking at the app - and its notification says the call is outgoing until the answer. An
 * incoming call may arrive while the app is in the background; its service starts only when it is
 * answered, as before.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class PhoneConnectionCallServiceStartTest {
    private val app: Application = RuntimeEnvironment.getApplication()

    @Before
    fun setUp() {
        ContextHolder.init(app)
        clearShownCalls()
        drainServiceIntents()
    }

    @After
    fun tearDown() {
        ConnectionManager.instance.cleanConnections()
        clearShownCalls()
        drainServiceIntents()
    }

    /**
     * The notification manager keeps the calls it shows in a static list, and other tests that
     * activate a connection leave theirs there. Every start of the call service carries that whole
     * list, so the list must begin empty for the assertions below to see only this test's call.
     */
    private fun clearShownCalls() {
        NotificationManager::class.java.getDeclaredField("activeCalls").apply {
            isAccessible = true
            (get(null) as MutableList<*>).clear()
        }
    }

    private fun outgoing(callId: String): PhoneConnection =
        PhoneConnection.createOutgoingPhoneConnection(
            app,
            mock(),
            CallMetadata(callId = callId, displayName = "Peer"),
            {},
            TelecomCallGroup { emptyList() },
        )

    private fun incoming(callId: String): PhoneConnection =
        PhoneConnection.createIncomingPhoneConnection(
            app,
            mock(),
            CallMetadata(callId = callId, displayName = "Peer"),
            {},
            TelecomCallGroup { emptyList() },
        )

    /** An outgoing call the way Telecom asks the connection service for it. */
    private fun telecomCreatesOutgoing(callId: String): PhoneConnectionService {
        val service = Robolectric.buildService(PhoneConnectionService::class.java).create().get()
        val account = PhoneAccountHandle(ComponentName(app, PhoneConnectionService::class.java), "test")
        service.onCreateOutgoingConnection(
            account,
            ConnectionRequest(account, Uri.parse("sip:peer"), CallMetadata(callId = callId, displayName = "Peer").toBundle()),
        )
        return service
    }

    private fun drainServiceIntents() {
        val shadow = shadowOf(app)
        while (shadow.nextStartedService != null) Unit
        while (shadow.nextStoppedService != null) Unit
    }

    /** The calls the call service was last started with, or null when it was not started. */
    private fun lastCallServiceStart(): List<CallMetadata>? {
        var last: Intent? = null
        while (true) {
            val next = shadowOf(app).nextStartedService ?: break
            if (next.component?.className == ActiveCallService::class.java.name) last = next
        }
        return last
            ?.getParcelableArrayListExtra(ActiveCallService.EXTRA_CALLS_METADATA, Bundle::class.java)
            ?.map { CallMetadata.fromBundle(it) }
    }

    private fun callServiceStopped(): Boolean {
        while (true) {
            val next = shadowOf(app).nextStoppedService ?: return false
            if (next.component?.className == ActiveCallService::class.java.name) return true
        }
    }

    @Test
    fun `outgoing call starts the call service as dialing once Telecom takes it`() {
        val connection = outgoing("out")
        assertNull("nothing before Telecom has the connection", lastCallServiceStart())

        connection.onAcceptedByTelecom()

        val calls = lastCallServiceStart()
        assertEquals(listOf("out"), calls?.map { it.callId })
        assertEquals(CallConnectionState.DIALING, calls?.single()?.connectionState)
    }

    @Test
    fun `answer of the outgoing call switches the call service to active`() {
        val connection = outgoing("out")
        connection.onAcceptedByTelecom()
        lastCallServiceStart()

        connection.setActive()

        assertEquals(CallConnectionState.ACTIVE, lastCallServiceStart()?.single()?.connectionState)
    }

    @Test
    fun `outgoing call ended before Telecom took it does not start the call service`() {
        val connection = outgoing("out")
        connection.setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
        lastCallServiceStart()

        connection.onAcceptedByTelecom()

        assertNull(lastCallServiceStart())
    }

    @Test
    fun `outgoing call that ends unanswered stops the call service`() {
        val connection = outgoing("out")
        connection.onAcceptedByTelecom()
        lastCallServiceStart()

        connection.onDisconnect()

        assertEquals(true, callServiceStopped())
    }

    @Test
    fun `connection service tells the connection once Telecom has taken it, not before`() {
        telecomCreatesOutgoing("out")
        assertNull("not while the connection is still being returned", lastCallServiceStart())

        shadowOf(Looper.getMainLooper()).idle()

        assertEquals(CallConnectionState.DIALING, lastCallServiceStart()?.single()?.connectionState)
    }

    @Test
    fun `connection dropped before Telecom took it starts no call service`() {
        telecomCreatesOutgoing("out")
        ConnectionManager.instance.cleanConnections()

        shadowOf(Looper.getMainLooper()).idle()

        assertNull(lastCallServiceStart())
    }

    @Test
    fun `incoming call starts the call service only when answered`() {
        val connection = incoming("in")
        assertNull("not while ringing", lastCallServiceStart())

        connection.setActive()

        assertEquals(CallConnectionState.ACTIVE, lastCallServiceStart()?.single()?.connectionState)
    }
}
