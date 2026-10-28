package com.webtrit.callkeep.services.services.connection

import android.content.Context
import android.os.Build
import android.telecom.DisconnectCause
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.models.CallEndedBy
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.services.connection.models.PerformDispatchHandle
import com.webtrit.callkeep.services.services.incoming_call.IncomingCallRelease
import com.webtrit.callkeep.services.services.incoming_call.IncomingCallService
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * The end event a [PhoneConnection] dispatches names who ended the call, so performEndCall in
 * the app and in the push session does not have to guess a decline from the call's absence.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class PhoneConnectionEndedByTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private val ends = mutableListOf<CallMetadata?>()
    private val dispatcher: PerformDispatchHandle = { event, data ->
        if (event == CallLifecycleEvent.HungUp || event == CallLifecycleEvent.DeclineCall) ends.add(data)
    }

    @Before
    fun setUp() {
        ContextHolder.init(context)
        ends.clear()
    }

    private fun ringing(callId: String = "call") =
        PhoneConnection.createIncomingPhoneConnection(
            context = context,
            dispatcher = dispatcher,
            metadata = CallMetadata(callId = callId),
            onDisconnect = {},
            callGroup = TelecomCallGroup { emptyList() },
        )

    private fun endedBy() = ends.single()?.endedBy

    @Test
    fun `a reject from the system call UI is the user's end`() {
        ringing().onReject()

        assertEquals(CallEndedBy.USER, endedBy())
    }

    @Test
    fun `the ring timeout is the system's end`() {
        val connection = ringing()

        // The timer's own callback, which the connection runs when the ring timeout elapses.
        PhoneConnection::class.java
            .getDeclaredMethod("onTimeoutTriggered")
            .apply { isAccessible = true }
            .invoke(connection)

        assertEquals(DisconnectCause.CANCELED, connection.disconnectCause.code)
        assertEquals(CallEndedBy.SYSTEM, endedBy())
    }

    @Test
    fun `a hang-up Telecom delivers with no cause (headset, system UI) is the user's end`() {
        ringing().onDisconnect()

        assertEquals(CallEndedBy.USER, endedBy())
    }

    @Test
    fun `an end the app asked for on the user's behalf is the user's`() {
        ringing().hungUp(CallEndedBy.USER)

        assertEquals(CallEndedBy.USER, endedBy())
    }

    @Test
    fun `an end the app asked for on its own is the app's`() {
        ringing().hungUp()

        assertEquals(CallEndedBy.APP, endedBy())
    }

    @Test
    fun `the notification's Decline is the user's end`() {
        ringing().declineCall(CallEndedBy.USER)

        assertEquals(CallEndedBy.USER, endedBy())
    }

    @Test
    fun `a remote disconnect nobody requested is the system's`() {
        // REMOTE comes only with declineCall, which names who asked; without a request nothing
        // says who it was.
        ringing().terminateWithCause(DisconnectCause(DisconnectCause.REMOTE))

        assertEquals(CallEndedBy.SYSTEM, endedBy())
    }

    @Test
    fun `any other cause without a request is the system's`() {
        ringing().terminateWithCause(DisconnectCause(DisconnectCause.ERROR))

        assertEquals(CallEndedBy.SYSTEM, endedBy())
    }

    @Test
    fun `a re-dispatched end repeats the initiator`() {
        val connection = ringing()
        connection.declineCall(CallEndedBy.USER)

        connection.hungUp(CallEndedBy.APP)

        assertEquals(listOf(CallEndedBy.USER, CallEndedBy.USER), ends.map { it?.endedBy })
    }

    @Test
    fun `the release to the push session carries the initiator`() {
        ringing("released").onReject()

        val release =
            shadowOf(ApplicationProvider.getApplicationContext<android.app.Application>())
                .broadcastIntents
                .last { it.action == IncomingCallRelease.IC_RELEASE_ENDED.name }
        assertEquals(CallEndedBy.USER, IncomingCallService.releaseEndedBy(release.extras))
    }
}
