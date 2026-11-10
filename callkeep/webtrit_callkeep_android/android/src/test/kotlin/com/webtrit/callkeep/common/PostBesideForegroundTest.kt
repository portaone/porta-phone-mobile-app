package com.webtrit.callkeep.common

import android.app.Notification
import android.os.Build
import androidx.core.app.NotificationManagerCompat
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.ArgumentMatchers.anyInt
import org.mockito.ArgumentMatchers.eq
import org.mockito.ArgumentMatchers.same
import org.mockito.Mockito.doThrow
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * The post that follows a call service's `startForeground()`: the same notification under the
 * same id, and a refusal of it - a CallStyle notification with neither a foreground service nor
 * a full-screen intent - ends in the log, never in the caller.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class PostBesideForegroundTest {
    private val notifier = mock(NotificationManagerCompat::class.java)
    private val notification = mock(Notification::class.java)

    @Test
    fun `posts the notification under the id it was given`() {
        notifier.postBesideForeground("test", 42, notification)

        verify(notifier).notify(eq(42), same(notification))
    }

    @Test
    fun `a notification the system refuses is not thrown to the caller`() {
        doThrow(IllegalArgumentException("CallStyle notifications must be for a foreground service"))
            .`when`(notifier)
            .notify(anyInt(), same(notification))

        notifier.postBesideForeground("test", 42, notification)
    }

    @Test
    fun `a post the system forbids is not thrown to the caller`() {
        doThrow(SecurityException("no permission")).`when`(notifier).notify(anyInt(), same(notification))

        notifier.postBesideForeground("test", 42, notification)
    }
}
