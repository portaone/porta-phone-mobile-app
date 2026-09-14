package com.webtrit.callkeep.services.services.connection

import android.app.Notification
import android.os.Build
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
 * Service-level tests for the standalone foreground notification across call end.
 *
 * There is one notification id on this path, so the incoming and ongoing variants overwrite
 * each other. These cases pin down that ending the call the notification was built from hands
 * it to a surviving call rebuilt from what is actually left, and that an ordinary call end never
 * takes Answer and Decline away from a ringing call.
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
        StandaloneCallService.callMetadataMap.clear()
        StandaloneCallService.answeredCallIds.clear()
        StandaloneCallService.ringingIncomingCallIds.clear()
        StandaloneCallService.pendingAnswers.clear()
        service = Robolectric.buildService(StandaloneCallService::class.java).create().get()
        listOf(alice, bob).forEach {
            StandaloneCallService.callMetadataMap[it.callId] = it
            StandaloneCallService.answeredCallIds.add(it.callId)
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

    private fun notification(): Notification = shadowOf(service).lastForegroundNotification

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

    @Test
    fun `ordinary call end must preserve another ringing call`() {
        invokeMetadata("showActiveCallNotification", alice)
        StandaloneCallService.callMetadataMap[carol.callId] = carol
        StandaloneCallService.ringingIncomingCallIds.add(carol.callId)
        invokeMetadata("showIncomingCallNotification", carol)
        assertEquals(1, notification().extras.getInt("android.callType"))
        invokeMetadata("endCall", bob)
        assertEquals("A ringing call keeps Answer and Decline", 1, notification().extras.getInt("android.callType"))
    }
}
