package com.webtrit.callkeep.services.services.connection

import android.app.Application
import android.content.Intent
import android.os.Build
import android.telecom.DisconnectCause
import com.webtrit.callkeep.common.CallDataConst
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.broadcaster.ConnectionServicePerformBroadcaster
import com.webtrit.callkeep.services.services.incoming_call.IncomingCallRelease
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * Every sender of the incoming-call release names the call whose incoming phase ended, so the
 * incoming-call service can ignore a release that is not about the call it shows.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class IncomingReleaseSendersTest {
    private val app: Application = RuntimeEnvironment.getApplication()

    @Before
    fun setUp() {
        ContextHolder.init(app)
        shadowOf(app).clearBroadcastIntents()
    }

    private fun releases(): List<Pair<String, String?>> =
        shadowOf(app)
            .broadcastIntents
            .filter { intent -> IncomingCallRelease.entries.any { it.name == intent.action } }
            .map { it.action!! to it.getStringExtra(CallDataConst.CALL_ID) }

    private fun sent(action: String): List<Intent> = shadowOf(app).broadcastIntents.filter { it.action == action }

    @Test
    fun `a refused call that is not found releases only itself`() {
        ConnectionServicePerformBroadcaster.handle.dispatch(
            app,
            CallLifecycleEvent.ConnectionNotFound,
            CallMetadata(callId = "refused").toBundle(),
        )

        assertEquals(listOf(IncomingCallRelease.IC_RELEASE_HANDED_OVER.name to "refused"), releases())
        assertEquals(
            "the synthetic HungUp still goes out for the same call",
            listOf("refused"),
            sent(CallLifecycleEvent.HungUp.name).map { it.getStringExtra(CallDataConst.CALL_ID) },
        )
    }

    @Test
    fun `an unanswered incoming call that disconnects releases itself as ended`() {
        val connection =
            PhoneConnection.createIncomingPhoneConnection(
                context = app,
                dispatcher = { _, _ -> },
                metadata = CallMetadata(callId = "ringing"),
                onDisconnect = {},
                callGroup = TelecomCallGroup { emptyList() },
            )

        connection.terminateWithCause(DisconnectCause(DisconnectCause.REMOTE))

        val released = releases()
        assertTrue("a release was sent", released.isNotEmpty())
        assertEquals(listOf(IncomingCallRelease.IC_RELEASE_ENDED.name to "ringing"), released)
    }
}
