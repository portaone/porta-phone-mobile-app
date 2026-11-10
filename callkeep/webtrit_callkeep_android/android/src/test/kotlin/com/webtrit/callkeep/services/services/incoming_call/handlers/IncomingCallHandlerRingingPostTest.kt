package com.webtrit.callkeep.services.services.incoming_call.handlers

import android.app.Notification
import android.app.Service
import android.content.Context
import android.content.pm.ServiceInfo
import android.os.Build
import androidx.core.app.NotificationManagerCompat
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.notifications.IncomingCallNotificationBuilder
import com.webtrit.callkeep.services.core.CallkeepCore
import com.webtrit.callkeep.services.services.foreground.ForegroundService
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.ArgumentMatchers.any
import org.mockito.ArgumentMatchers.anyInt
import org.mockito.ArgumentMatchers.eq
import org.mockito.ArgumentMatchers.same
import org.mockito.Mockito.doThrow
import org.mockito.Mockito.inOrder
import org.mockito.Mockito.mock
import org.mockito.Mockito.never
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * The ringing notification is posted under its own id right after the service took it into the
 * foreground. With the app's background usage restricted the system drops the foreground start
 * and the notification handed to it, and the post is what shows the call; in the foreground it
 * replaces the service's notification in place.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class IncomingCallHandlerRingingPostTest {
    private val service = mock(Service::class.java)
    private val notificationBuilder = mock(IncomingCallNotificationBuilder::class.java)
    private val isolateInitializer = mock(IsolateInitializer::class.java)
    private val notifier = mock(NotificationManagerCompat::class.java)
    private val ringing = mock(Notification::class.java)

    private val handler = IncomingCallHandler(service, notificationBuilder, isolateInitializer, notifier)
    private val notificationId = IncomingCallNotificationBuilder.notificationId("call-1")

    @Before
    fun setUp() {
        ContextHolder.init(ApplicationProvider.getApplicationContext<Context>())
        `when`(notificationBuilder.build()).thenReturn(ringing)
    }

    @After
    fun tearDown() {
        CallkeepCore.instance.clear()
        ForegroundService.isDelegateReady = false
    }

    @Test
    fun `the ringing notification is posted after the service enters the foreground with it`() {
        handler.handle(CallMetadata(callId = "call-1", displayName = "Caller"))

        val order = inOrder(service, notifier)
        order.verify(service).startForeground(
            eq(notificationId),
            same(ringing),
            eq(ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL),
        )
        order.verify(notifier).notify(eq(notificationId), same(ringing))
    }

    @Test
    fun `a call released before it is shown gets the foreground start only`() {
        // The call is over: restricted, where the start shows nothing, a post would put a
        // ringing call with its full-screen intent on the screen for it.
        handler.show(CallMetadata(callId = "call-1", displayName = "Caller"))

        verify(service).startForeground(
            eq(notificationId),
            same(ringing),
            eq(ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL),
        )
        verify(notifier, never()).notify(anyInt(), any(Notification::class.java))
    }

    @Test
    fun `a refused post leaves the call to be handled`() {
        // Restricted and without the full-screen permission the system refuses a CallStyle
        // notification outside the foreground; the call is still handed on.
        doThrow(IllegalArgumentException("CallStyle notifications must be for a foreground service"))
            .`when`(notifier)
            .notify(anyInt(), same(ringing))

        handler.handle(CallMetadata(callId = "call-1", displayName = "Caller"))

        verify(isolateInitializer).start()
    }
}
