package com.webtrit.callkeep.services.receivers

import android.content.Context
import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.PCallkeepConnectionState
import com.webtrit.callkeep.PIncomingCallError
import com.webtrit.callkeep.PIncomingCallErrorEnum
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.models.FailureMetadata
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.core.CallServiceRouter
import com.webtrit.callkeep.services.core.InProcessCallkeepCore
import com.webtrit.callkeep.services.core.MainProcessConnectionTracker
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.ArgumentMatchers
import org.mockito.Mockito.mock
import org.mockito.Mockito.never
import org.mockito.Mockito.times
import org.mockito.Mockito.verify
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.util.concurrent.TimeUnit

/** An SMS-triggered call goes through the same registration as push and signaling reports. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class IncomingCallSmsTriggerReceiverTest {
    private lateinit var router: CallServiceRouter
    private lateinit var core: InProcessCallkeepCore
    private val receiver = IncomingCallSmsTriggerReceiver()

    // Host calls finish only once the main looper is driven, so they run outside runBlocking.
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)

    @Before
    fun setUp() {
        ContextHolder.init(ApplicationProvider.getApplicationContext<Context>())
        // Robolectric runs the plugin as a debuggable app; these deadlines are the release ones.
        // ContextHolder keeps the first test's context for the whole JVM, so flag that one.
        ContextHolder.context.applicationInfo.apply {
            flags = flags and ApplicationInfo.FLAG_DEBUGGABLE.inv()
        }
        router = mock(CallServiceRouter::class.java)
        core = InProcessCallkeepCore(tracker = MainProcessConnectionTracker(), routerInit = { router })
    }

    @After
    fun tearDown() {
        scope.cancel()
        core.endIncomingRegistrations()
    }

    @Test
    fun `an SMS call stays registering until Telecom confirms it`() {
        val sms = sms("s1")

        assertFalse("dispatch alone does not finish the registration", sms.isCompleted)
        assertTrue(core.isPending("s1"))

        event(CallLifecycleEvent.IncomingConnectionReported, "s1")

        assertTrue(sms.isCompleted)
        assertEquals(PCallkeepConnectionState.STATE_RINGING, core.getState("s1"))
        assertFalse(core.isPending("s1"))
    }

    @Test
    fun `an SMS for a call a push is registering joins it instead of dispatching again`() {
        val push = push("s2")
        val sms = sms("s2")
        assertFalse("the SMS waits for the push's outcome instead of guessing one", sms.isCompleted)

        event(CallLifecycleEvent.IncomingConnectionReported, "s2")

        verify(router, times(1)).startIncomingCall(anyArgument(), anyArgument(), anyArgument())
        assertNull(push.result())
        assertTrue(sms.isCompleted)
    }

    @Test
    fun `a push for a call the SMS is registering joins it and learns it exists`() {
        val sms = sms("s3")
        val push = push("s3")
        assertFalse("the push waits for the SMS registration instead of taking it as ringing", push.isCompleted)
        assertFalse(core.exists("s3"))

        event(CallLifecycleEvent.IncomingConnectionReported, "s3")

        verify(router, times(1)).startIncomingCall(anyArgument(), anyArgument(), anyArgument())
        assertTrue(sms.isCompleted)
        assertEquals(PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS, push.result()?.value)
    }

    @Test
    fun `an SMS for a call that already ended without the app is not registered again`() {
        core.markEndedWithoutFlutterState("s4")

        val sms = sms("s4")

        assertTrue(sms.isCompleted)
        verify(router, never()).startIncomingCall(anyArgument(), anyArgument(), anyArgument())
        assertFalse(core.isPending("s4"))
    }

    @Test
    fun `a Telecom refusal of an SMS call reaches a push waiting on the same call`() {
        sms("s5")
        val push = push("s5")

        event(CallLifecycleEvent.IncomingFailure, "s5")

        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, push.result()?.value)
        assertFalse(core.isPending("s5"))
    }

    @Test
    fun `an SMS call Telecom never confirms is cancelled at the deadline`() {
        val sms = sms("s6")

        shadowOf(Looper.getMainLooper()).idleFor(6, TimeUnit.SECONDS)

        assertTrue(sms.isCompleted)
        verify(router).cancelIncomingCall("s6")
        assertTrue(core.wasEndedWithoutFlutterState("s6"))
    }

    private fun sms(callId: String): Job = scope.launch { receiver.registerCall(CallMetadata(callId = callId), core) }.also { idle() }

    private fun push(callId: String) = scope.async { core.registerIncomingCall(CallMetadata(callId = callId), "push") }.also { idle() }

    private fun event(
        event: CallLifecycleEvent,
        callId: String,
    ) {
        val data =
            if (event == CallLifecycleEvent.IncomingFailure) {
                FailureMetadata(CallMetadata(callId = callId), "refused: $callId").toBundle()
            } else {
                CallMetadata(callId = callId).toBundle()
            }
        core.notifyConnectionEvent(event, data)
        idle()
    }

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    private fun kotlinx.coroutines.Deferred<PIncomingCallError?>.result(): PIncomingCallError? {
        assertTrue("the registration should already be answered", isCompleted)
        return runBlocking { withTimeout(1_000) { await() } }
    }

    // A generic return avoids Kotlin inserting a null check for Mockito's matcher placeholder.
    private fun <T> anyArgument(): T = ArgumentMatchers.any()
}
