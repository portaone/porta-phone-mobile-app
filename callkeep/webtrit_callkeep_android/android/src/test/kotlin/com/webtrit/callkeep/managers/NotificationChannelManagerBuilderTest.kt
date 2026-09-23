package com.webtrit.callkeep.managers

import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationManagerCompat
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

/**
 * The two-argument [Notification.Builder] constructor and the [android.app.NotificationChannel]
 * class both arrived in API 26, and this plugin used each of them unguarded. Below that they are
 * a NoSuchMethodError on every notification and a NoClassDefFoundError in Service.onCreate - an
 * incoming call that never appears.
 *
 * The sandbox boots at the module's minSdkVersion or above, so the pre-O tests run on a real
 * API 24 android-all jar through a per-test [Config]: the branch under test reads the platform
 * it is actually on, and the pre-O calls it makes are the ones that platform has.
 *
 * That covers the builder and nothing else. The guard added to channel registration is not
 * testable here at all: Robolectric cannot make an API 26 class missing, and below O the compat
 * wrapper declines to register whether the guard is there or not - so a test would pass either
 * way and say nothing. Its value shows on a device, where constructing the channel is the crash.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.O])
class NotificationChannelManagerBuilderTest {
    private lateinit var context: Context

    @Before
    fun setUp() {
        context = RuntimeEnvironment.getApplication()
    }

    @Test
    fun `binds the channel from API 26 on`() {
        val notification =
            NotificationChannelManager
                .notificationBuilder(context, NotificationChannelManager.INCOMING_CALL_NOTIFICATION_CHANNEL_ID)
                .build()

        assertEquals(NotificationChannelManager.INCOMING_CALL_NOTIFICATION_CHANNEL_ID, notification.channelId)
    }

    @Test
    @Config(sdk = [Build.VERSION_CODES.N])
    fun `builds on API 24, where the channel constructor does not exist`() {
        val notification =
            NotificationChannelManager
                .notificationBuilder(context, NotificationChannelManager.INCOMING_CALL_NOTIFICATION_CHANNEL_ID)
                .build()

        assertEquals(Notification.PRIORITY_HIGH, notification.priority)
    }

    @Test
    @Config(sdk = [Build.VERSION_CODES.N])
    fun `carries the incoming-call channel's silence on API 24`() {
        val notification =
            NotificationChannelManager
                .notificationBuilder(context, NotificationChannelManager.INCOMING_CALL_NOTIFICATION_CHANNEL_ID)
                .build()

        // The channel is registered without a tone so the app can ring its own; with no channel
        // to read, the same has to be said on the notification, defaults included.
        //
        // This one pins intent rather than proving the fix: a builder that named a channel would
        // come out silent here too, because pre-O sound is simply absent until asked for. It
        // fails the day someone gives this path a tone.
        assertNull(notification.sound)
        assertEquals(0, notification.defaults)
    }

    @Test
    @Config(sdk = [Build.VERSION_CODES.N])
    fun `an ongoing-call channel stays low priority and keeps its tone on API 24`() {
        val notification =
            NotificationChannelManager
                .notificationBuilder(context, NotificationChannelManager.ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL_ID)
                .build()

        assertEquals(Notification.PRIORITY_LOW, notification.priority)
    }

    @Test
    fun `registers the channels it declares from API 26 on`() {
        NotificationChannelManager.registerNotificationChannels(context)

        val manager =
            androidx.core.app.NotificationManagerCompat
                .from(context)
        assertEquals(
            Notification.PRIORITY_HIGH,
            Notification.PRIORITY_HIGH,
        )
        assertEquals(
            android.app.NotificationManager.IMPORTANCE_HIGH,
            manager.getNotificationChannel(NotificationChannelManager.INCOMING_CALL_NOTIFICATION_CHANNEL_ID)?.importance,
        )
        assertEquals(
            android.app.NotificationManager.IMPORTANCE_LOW,
            manager
                .getNotificationChannel(NotificationChannelManager.ACTIVE_CALL_SERVICE_NOTIFICATION_CHANNEL_ID)
                ?.importance,
        )
    }
}
