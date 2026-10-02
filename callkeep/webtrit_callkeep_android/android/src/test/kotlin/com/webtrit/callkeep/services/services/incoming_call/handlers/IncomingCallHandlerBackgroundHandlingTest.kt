package com.webtrit.callkeep.services.services.incoming_call.handlers

import android.app.Notification
import android.app.Service
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationManagerCompat
import androidx.lifecycle.Lifecycle
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.notifications.IncomingCallNotificationBuilder
import com.webtrit.callkeep.services.broadcaster.ActivityLifecycleState
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.core.CallkeepCore
import com.webtrit.callkeep.services.core.ConnectionEventListener
import com.webtrit.callkeep.services.core.MainProcessConnectionTracker
import com.webtrit.callkeep.services.services.foreground.ForegroundService
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.mock
import org.mockito.Mockito.never
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Who takes a push-registered incoming call: the app's delegate when one is ready, a push
 * session (the isolate) otherwise. Whether an Activity is visible plays no part - an app alive
 * in the background may have closed its socket when the previous call ended, and skipping the
 * isolate without giving the app the call left one nobody owned, ringing on after the caller
 * hung up.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class IncomingCallHandlerBackgroundHandlingTest {
    private val service = mock(Service::class.java)
    private val notificationBuilder = mock(IncomingCallNotificationBuilder::class.java)
    private val isolateInitializer = mock(IsolateInitializer::class.java)
    private val notifier = mock(NotificationManagerCompat::class.java)
    private val presented = mutableListOf<String>()
    private val listener =
        ConnectionEventListener { event, data ->
            if (event == CallLifecycleEvent.ReplayIncomingCall) presented += CallMetadata.fromBundle(data!!).callId
        }

    private val handler = IncomingCallHandler(service, notificationBuilder, isolateInitializer, notifier)

    @Before
    fun setUp() {
        ContextHolder.init(ApplicationProvider.getApplicationContext<Context>())
        `when`(notificationBuilder.build()).thenReturn(mock(Notification::class.java))
        CallkeepCore.instance.addConnectionEventListener(listener)
    }

    @After
    fun tearDown() {
        CallkeepCore.instance.removeConnectionEventListener(listener)
        CallkeepCore.instance.clear()
        ForegroundService.isDelegateReady = false
        ActivityLifecycleState.setValue(Lifecycle.Event.ON_DESTROY)
    }

    @Test
    fun `a call is given to a ready delegate, not to an isolate`() {
        ForegroundService.isDelegateReady = true

        handler.handle(CallMetadata(callId = "call-1", displayName = "Caller"))

        assertEquals(listOf("call-1"), presented)
        verify(isolateInitializer, never()).start()
    }

    @Test
    fun `the Activity lifecycle does not decide`() {
        // The delegate lives with the engine, not with the Activity: an app whose Activity is
        // gone but whose engine and delegate are up still takes the call; one on screen whose
        // delegate is not set yet does not.
        ForegroundService.isDelegateReady = true
        ActivityLifecycleState.setValue(Lifecycle.Event.ON_DESTROY)
        handler.handle(CallMetadata(callId = "call-1", displayName = "Caller"))

        ForegroundService.isDelegateReady = false
        ActivityLifecycleState.setValue(Lifecycle.Event.ON_RESUME)
        handler.handle(CallMetadata(callId = "call-2", displayName = "Caller"))

        assertEquals(listOf("call-1"), presented)
        verify(isolateInitializer).start()
    }

    @Test
    fun `with no delegate ready the call goes to a push session`() {
        // A killed app, or one whose call handling is not built yet or was torn down: presenting
        // would reach nobody, so the call goes to a push session and the app takes it over once
        // its delegate attaches.
        handler.handle(CallMetadata(callId = "call-1", displayName = "Caller"))

        verify(isolateInitializer).start()
        assertTrue(presented.isEmpty())
    }

    @Test
    fun `a call the app reported itself is neither presented back nor given an isolate`() {
        ForegroundService.isDelegateReady = true
        MainProcessConnectionTracker.instance.markReportedByApp("call-1")

        handler.handle(CallMetadata(callId = "call-1", displayName = "Caller"))

        assertTrue("the app holds this call already", presented.isEmpty())
        verify(isolateInitializer, never()).start()
    }

    @Test
    fun `showing a call gives it to nobody`() {
        ForegroundService.isDelegateReady = true

        handler.show(CallMetadata(callId = "call-1", displayName = "Caller"))

        assertTrue(presented.isEmpty())
        verify(isolateInitializer, never()).start()
    }
}
