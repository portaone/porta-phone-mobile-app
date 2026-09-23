package com.webtrit.callkeep.managers

import android.app.Notification
import android.content.Context
import android.os.Build
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Ignore
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

/**
 * The two-argument [Notification.Builder] constructor arrived with channels in API 26, so
 * calling it below that throws NoSuchMethodError - for every notification this plugin posts,
 * which on the standalone path is an incoming call that never appears.
 *
 * Only half of that line can be tested from here. Robolectric parses the merged manifest
 * before it runs anything, and this module declares minSdkVersion 26, so asking for an older
 * SDK fails in setup with "Requires newer sdk version #26": the pre-O branch is unreachable
 * from a test until the floor moves. The tests that cover it are written and ignored rather
 * than left unwritten - they state the contract now and start running the day minSdk drops
 * to 24, which is where they belong.
 */
@RunWith(RobolectricTestRunner::class)
class NotificationChannelManagerBuilderTest {
    private lateinit var context: Context

    @Before
    fun setUp() {
        context = RuntimeEnvironment.getApplication()
    }

    @Config(sdk = [Build.VERSION_CODES.O])
    @Test
    fun `binds the channel from API 26 on`() {
        val notification =
            NotificationChannelManager
                .notificationBuilder(context, NotificationChannelManager.INCOMING_CALL_NOTIFICATION_CHANNEL_ID)
                .build()

        assertEquals(NotificationChannelManager.INCOMING_CALL_NOTIFICATION_CHANNEL_ID, notification.channelId)
    }

    @Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
    @Test
    fun `binds the channel on a current release too`() {
        val notification =
            NotificationChannelManager
                .notificationBuilder(context, NotificationChannelManager.ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL_ID)
                .build()

        assertEquals(NotificationChannelManager.ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL_ID, notification.channelId)
    }

    @Config(sdk = [Build.VERSION_CODES.N])
    @Ignore("Robolectric refuses an SDK below the module's minSdkVersion 26; enable with the drop to 24")
    @Test
    fun `builds on API 24, where the channel constructor does not exist`() {
        val notification =
            NotificationChannelManager
                .notificationBuilder(context, NotificationChannelManager.INCOMING_CALL_NOTIFICATION_CHANNEL_ID)
                .build()

        assertEquals(Notification.PRIORITY_HIGH, notification.priority)
    }

    @Config(sdk = [Build.VERSION_CODES.N])
    @Ignore("Robolectric refuses an SDK below the module's minSdkVersion 26; enable with the drop to 24")
    @Test
    fun `carries the incoming-call channel's silence on API 24`() {
        val notification =
            NotificationChannelManager
                .notificationBuilder(context, NotificationChannelManager.INCOMING_CALL_NOTIFICATION_CHANNEL_ID)
                .build()

        // The channel is registered with setSound(null, null) so the app can ring itself; with
        // no channel to read, the same has to be said on the notification, defaults included.
        assertEquals(null, notification.sound)
        assertEquals(0, notification.defaults)
    }

    @Config(sdk = [Build.VERSION_CODES.N])
    @Ignore("Robolectric refuses an SDK below the module's minSdkVersion 26; enable with the drop to 24")
    @Test
    fun `an ongoing-call channel stays low priority on API 24`() {
        val notification =
            NotificationChannelManager
                .notificationBuilder(context, NotificationChannelManager.ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL_ID)
                .build()

        assertEquals(Notification.PRIORITY_LOW, notification.priority)
    }
}
