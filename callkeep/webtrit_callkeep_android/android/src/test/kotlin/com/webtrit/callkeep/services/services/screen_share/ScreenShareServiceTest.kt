package com.webtrit.callkeep.services.services.screen_share

import android.app.Notification
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.ExperimentalCoroutinesApi
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements
import org.robolectric.shadows.ShadowService

/**
 * The foreground service a screen share runs under: the type Android 14 asks of a screen capture,
 * the answer the waiting request gets, and the ends of the share the app did not ask for.
 */
@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE], shadows = [ShadowProjectionRefusingService::class])
class ScreenShareServiceTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private var ended = 0

    @Before
    fun setUp() {
        ShadowProjectionRefusingService.refuse = false
        ScreenShareSession.onEnded = { ended++ }
    }

    @After
    fun tearDown() {
        ShadowProjectionRefusingService.refuse = false
        ScreenShareSession.onEnded = null
    }

    private fun service(): ScreenShareService =
        Robolectric
            .buildService(ScreenShareService::class.java)
            .create()
            .get()

    @Test
    fun `a start runs in the foreground with the media projection type and answers the request`() {
        val promotion = ScreenShareSession.expectPromotion()
        val service = service()

        service.onStartCommand(Intent(context, ScreenShareService::class.java), 0, 1)

        assertEquals(ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION, (service as Service).foregroundServiceType)
        assertTrue("the request is answered", promotion.isCompleted)
        assertFalse(promotion.isCancelled)
        assertEquals(0, ended)
    }

    @Test
    fun `a refused type fails the request and stops the service`() {
        ShadowProjectionRefusingService.refuse = true
        val promotion = ScreenShareSession.expectPromotion()
        val service = service()

        service.onStartCommand(Intent(context, ScreenShareService::class.java), 0, 1)

        assertTrue("the request is answered", promotion.isCompleted)
        assertTrue("with a failure", promotion.getCompletionExceptionOrNull() is SecurityException)
        assertTrue("the service goes", shadowOf(service).isStoppedBySelf)
    }

    @Test
    fun `a stop asked for before the promotion is carried out once the service is in the foreground`() {
        val promotion = ScreenShareSession.expectPromotion()
        // The app gave up waiting and stops the service the system has not started yet: stopping
        // it now would end the app, so the stop waits for the promotion.
        assertFalse(ScreenShareSession.mayStopNow())
        val service = service()

        service.onStartCommand(Intent(context, ScreenShareService::class.java), 0, 1)

        assertTrue("the service goes", shadowOf(service).isStoppedBySelf)
        assertTrue(shadowOf(service).isForegroundStopped)
        assertTrue("nobody waits on a success", promotion.isCompleted && promotion.getCompletionExceptionOrNull() != null)
        assertEquals("the app asked for the stop, it is not told of an end", 0, ended)
        assertTrue("a later stop is not held back", ScreenShareSession.mayStopNow())
    }

    @Test
    fun `a stop once the service is in the foreground goes at once`() {
        ScreenShareSession.expectPromotion()
        service().onStartCommand(Intent(context, ScreenShareService::class.java), 0, 1)

        assertTrue(ScreenShareSession.mayStopNow())
    }

    @Test
    fun `the Stop of the notification tells the app and stops the service`() {
        val service = service()
        service.onStartCommand(Intent(context, ScreenShareService::class.java), 0, 1)

        service.onStartCommand(
            Intent(context, ScreenShareService::class.java).setAction(ScreenShareService.ACTION_STOP),
            0,
            2,
        )

        assertEquals(1, ended)
        assertTrue(shadowOf(service).isStoppedBySelf)
        assertTrue(shadowOf(service).isForegroundStopped)
    }
}

/** Plays the system refusing the media projection type to a service the person granted nothing to. */
@Implements(Service::class)
class ShadowProjectionRefusingService : ShadowService() {
    @Implementation
    override fun startForeground(
        id: Int,
        notification: Notification,
        foregroundServiceType: Int,
    ) {
        if (refuse && foregroundServiceType and ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION != 0) {
            throw SecurityException("Starting FGS with type mediaProjection requires the capture to be granted")
        }
        super.startForeground(id, notification, foregroundServiceType)
    }

    companion object {
        @JvmStatic
        var refuse = false
    }
}
