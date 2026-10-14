package com.webtrit.callkeep.notifications

import android.app.Notification
import android.content.Context
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.R
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.models.CallConnectionState
import com.webtrit.callkeep.models.CallMetadata
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * The title of the ongoing call notification of the Telecom path.
 *
 * The notification is posted for an answered call, and can also be posted for an outgoing call
 * the other side has not answered yet. That call must not be announced as an active one: its
 * metadata says DIALING and the title says "Outgoing call". Every other single call - answered,
 * on hold, or with no state in its metadata - keeps "Active call"; several calls are "Active
 * calls" whatever their states.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class ActiveCallNotificationTitleTest {
    private val app get() = ApplicationProvider.getApplicationContext<Context>()

    private fun call(
        callId: String,
        state: CallConnectionState?,
    ) = CallMetadata(callId = callId, displayName = "Peer $callId", connectionState = state)

    @Before
    fun setUp() {
        ContextHolder.init(app)
    }

    @Test
    fun `a single call with no state in its metadata is an active call`() {
        assertEquals(
            R.string.push_notification_active_call_channel_title,
            ActiveCallNotificationBuilder.titleResource(listOf(call("a", null))),
        )
    }

    @Test
    fun `a single answered or held call is an active call`() {
        listOf(CallConnectionState.ACTIVE, CallConnectionState.HOLDING).forEach { state ->
            assertEquals(
                "state $state",
                R.string.push_notification_active_call_channel_title,
                ActiveCallNotificationBuilder.titleResource(listOf(call("a", state))),
            )
        }
    }

    @Test
    fun `a single dialing call is an outgoing call`() {
        assertEquals(
            R.string.push_notification_outgoing_call_title,
            ActiveCallNotificationBuilder.titleResource(listOf(call("a", CallConnectionState.DIALING))),
        )
    }

    @Test
    fun `several calls are active calls even when one of them is dialing`() {
        assertEquals(
            R.string.push_notification_active_calls_channel_title,
            ActiveCallNotificationBuilder.titleResource(
                listOf(call("a", CallConnectionState.ACTIVE), call("b", CallConnectionState.DIALING)),
            ),
        )
    }

    @Test
    fun `a call dialed while another is on hold makes active calls`() {
        // The notification manager puts the newest call first, so the dialing one leads the list.
        assertEquals(
            R.string.push_notification_active_calls_channel_title,
            ActiveCallNotificationBuilder.titleResource(
                listOf(call("b", CallConnectionState.DIALING), call("a", CallConnectionState.HOLDING)),
            ),
        )
    }

    @Test
    fun `the built notification carries that title`() {
        val outgoing =
            ActiveCallNotificationBuilder()
                .apply { setCallsMetaData(listOf(call("a", CallConnectionState.DIALING))) }
                .build()
        val active =
            ActiveCallNotificationBuilder()
                .apply { setCallsMetaData(listOf(call("a", CallConnectionState.ACTIVE))) }
                .build()

        assertEquals("Outgoing call", outgoing.extras.getCharSequence(Notification.EXTRA_TITLE).toString())
        assertEquals("Active call", active.extras.getCharSequence(Notification.EXTRA_TITLE).toString())
    }
}
