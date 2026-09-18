package com.webtrit.callkeep.services.services.connection

import android.app.Notification
import android.content.Intent
import android.os.Build
import com.webtrit.callkeep.common.CallDataConst
import com.webtrit.callkeep.models.CallConnection
import com.webtrit.callkeep.models.CallGroup
import com.webtrit.callkeep.models.CallMetadata
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * Service-level tests for the standalone foreground notification across grouping and call end.
 *
 * There is one notification id on this path, so the incoming and ongoing variants overwrite
 * each other. These cases pin down that a refresh never takes Answer and Decline away from a
 * ringing call, and that ending the call the notification was built from hands it to a
 * surviving call rebuilt from what is actually left.
 *
 * The two grouping scenarios were written by the branch review that found the defects; the
 * group-free ones came with the hand-off itself.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class StandaloneCallServiceNotificationLifecycleTest {
    private lateinit var service: StandaloneCallService
    private val alice = CallMetadata(callId = "A", displayName = "Alice")
    private val bob = CallMetadata(callId = "B", displayName = "Bob")
    private val carol = CallMetadata(callId = "C", displayName = "Carol")

    @Before
    fun setUp() {
        StandaloneCallService.connections.clear()
        StandaloneCallService.callGroup = CallGroup.empty
        StandaloneCallService.ringingIncomingCallIds.clear()
        StandaloneCallService.pendingAnswers.clear()
        service = Robolectric.buildService(StandaloneCallService::class.java).create().get()
        listOf(alice, bob).forEach {
            StandaloneCallService.connections[it.callId] = CallConnection(it)
            StandaloneCallService.connections.getValue(it.callId).answer()
        }
        invokeMetadata("showActiveCallNotification", bob)
    }

    private fun invokeMetadata(
        name: String,
        metadata: CallMetadata,
    ) {
        StandaloneCallService::class.java
            .getDeclaredMethod(name, CallMetadata::class.java)
            .apply {
                isAccessible = true
            }.invoke(service, metadata)
    }

    private fun group(vararg ids: String) {
        service.onStartCommand(
            Intent(service, StandaloneCallService::class.java).apply {
                action = StandaloneServiceAction.SetCallGroup.action
                putExtra(CallDataConst.CALL_IDS, ids)
            },
            0,
            1,
        )
    }

    private fun notification(): Notification = shadowOf(service).lastForegroundNotification

    @Test
    fun `ending notification anchor must refresh surviving group and later members`() {
        group("A", "B")
        assertEquals("Alice, Bob", notification().extras.getCharSequence(Notification.EXTRA_TEXT).toString())
        invokeMetadata("endCall", bob)
        assertEquals("Alice", notification().extras.getCharSequence(Notification.EXTRA_TEXT).toString())
        StandaloneCallService.connections[carol.callId] = CallConnection(carol)
        StandaloneCallService.connections.getValue(carol.callId).answer()
        group("A", "C")
        assertEquals("Alice, Carol", notification().extras.getCharSequence(Notification.EXTRA_TEXT).toString())
    }

    @Test
    fun `group reconciliation must preserve a ringing incoming notification`() {
        group("A", "B")
        StandaloneCallService.connections[carol.callId] = CallConnection(carol)
        StandaloneCallService.ringingIncomingCallIds.add(carol.callId)
        invokeMetadata("showIncomingCallNotification", carol)
        val incoming = notification()
        assertEquals(1, incoming.extras.getInt("android.callType"))
        group("A", "B")
        assertEquals("Incoming call must keep Answer and Decline", 1, notification().extras.getInt("android.callType"))
    }

    @Test
    fun `ordinary call end without grouping must preserve another ringing call`() {
        invokeMetadata("showActiveCallNotification", alice)
        StandaloneCallService.connections[carol.callId] = CallConnection(carol)
        StandaloneCallService.ringingIncomingCallIds.add(carol.callId)
        invokeMetadata("showIncomingCallNotification", carol)
        assertEquals(1, notification().extras.getInt("android.callType"))
        invokeMetadata("endCall", bob)
        assertEquals("No grouping API was called", 1, notification().extras.getInt("android.callType"))
    }

    @Test
    fun `ending the call the notification stands for hands it to the surviving call`() {
        assertEquals("Bob", notification().extras.getCharSequence(Notification.EXTRA_TEXT).toString())
        invokeMetadata("endCall", bob)
        assertEquals("Alice", notification().extras.getCharSequence(Notification.EXTRA_TEXT).toString())
    }

    @Test
    fun `ending another call leaves the notification alone`() {
        invokeMetadata("endCall", alice)
        assertEquals("Bob", notification().extras.getCharSequence(Notification.EXTRA_TEXT).toString())
    }
}
