package com.webtrit.callkeep.services.core

import android.content.Context
import android.os.Build
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.PEndCallReasonEnum
import com.webtrit.callkeep.PIncomingCallError
import com.webtrit.callkeep.PIncomingCallErrorEnum
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.common.PendingBroadcastQueue
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.broadcaster.ConnectionEvent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.ArgumentMatchers
import org.mockito.Mockito.mock
import org.mockito.Mockito.never
import org.mockito.Mockito.verify
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * The app reporting a call ended is one fact for every engine: the core ends the call in the
 * backend at once and makes sure nothing presents it again or asks the app to end it twice.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class ReportCallEndedTest {
    private lateinit var router: CallServiceRouter
    private lateinit var core: InProcessCallkeepCore
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
    private val delivered = mutableListOf<ConnectionEvent>()

    @Before
    fun setUp() {
        ContextHolder.init(ApplicationProvider.getApplicationContext<Context>())
        PendingBroadcastQueue.clear()
        router = mock(CallServiceRouter::class.java)
        core = InProcessCallkeepCore(tracker = MainProcessConnectionTracker(), routerInit = { router })
        core.addConnectionEventListener { event, _ -> delivered += event }
    }

    @After
    fun tearDown() {
        scope.cancel()
        core.endIncomingRegistrations()
        PendingBroadcastQueue.clear()
    }

    @Test
    fun `a reported end with no incoming-call service running leaves it a pending release`() {
        core.reportCallEnded(CallMetadata(callId = "c1"), PEndCallReasonEnum.REMOTE_ENDED)

        assertTrue(
            "a service started for this call afterwards must end it without showing it",
            PendingBroadcastQueue.consume(PendingBroadcastQueue.incomingReleaseKey("c1")),
        )
    }

    @Test
    fun `a reported end terminates the call and ends it in the backend`() {
        core.reportCallEnded(CallMetadata(callId = "c1"), PEndCallReasonEnum.REMOTE_ENDED)

        assertTrue(core.isTerminated("c1"))
        verify(router).startDeclineCall(anyArgument())
    }

    @Test
    fun `an end the app never presented keeps a replay from presenting the call`() {
        core.reportCallEnded(CallMetadata(callId = "c1"), PEndCallReasonEnum.MISSED_WHILE_CONNECTING)

        assertTrue(core.wasEndedWithoutFlutterState("c1"))
        event(CallLifecycleEvent.ReplayIncomingCall, "c1")
        assertFalse("the replay must not reach the bridge", CallLifecycleEvent.ReplayIncomingCall in delivered)
        verify(router).cancelIncomingCall("c1")
    }

    @Test
    fun `an end of a presented call leaves the id free for a new registration`() {
        core.reportCallEnded(CallMetadata(callId = "c1"), PEndCallReasonEnum.REMOTE_ENDED)

        assertFalse("a transfer-back reuses the id of a call the app knew", core.wasEndedWithoutFlutterState("c1"))
    }

    @Test
    fun `a reported end is remembered so nothing asks the app to end the call again`() {
        core.reportCallEnded(CallMetadata(callId = "c1"), PEndCallReasonEnum.MISSED_WHILE_CONNECTING)

        assertFalse("the end is already dispatched", core.markEndCallDispatched("c1"))
    }

    @Test
    fun `a reported end rejects a registration still waiting for Telecom`() {
        val waiting = report("c1")

        core.reportCallEnded(CallMetadata(callId = "c1"), PEndCallReasonEnum.MISSED_WHILE_CONNECTING)

        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, waiting.result()?.value)
        assertFalse(core.isPending("c1"))
    }

    @Test
    fun `a late push of a call the app reported ended is refused without a dispatch`() {
        core.reportCallEnded(CallMetadata(callId = "c1"), PEndCallReasonEnum.MISSED_WHILE_CONNECTING)

        val late = report("c1")

        assertEquals(PIncomingCallErrorEnum.CALL_ID_ALREADY_TERMINATED, late.result()?.value)
        verify(router, never()).startIncomingCall(anyArgument(), anyArgument(), anyArgument())
    }

    @Test
    fun `an end reported off the main looper is terminal at once and rejects the waiting registration there`() {
        val waiting = report("c1")

        offMain { core.reportCallEnded(CallMetadata(callId = "c1"), PEndCallReasonEnum.MISSED_WHILE_CONNECTING) }

        assertTrue("the terminal fact must not wait for the main looper", core.isTerminated("c1"))
        assertTrue(core.wasEndedWithoutFlutterState("c1"))
        verify(router).startDeclineCall(anyArgument())
        idle()
        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, waiting.result()?.value)
        assertFalse(core.isPending("c1"))
    }

    @Test
    fun `an end reported off the main looper leaves the pending release once the main looper has looked`() {
        offMain { core.reportCallEnded(CallMetadata(callId = "c1"), PEndCallReasonEnum.REMOTE_ENDED) }

        assertFalse(
            "whether a service is running is only known on the main looper",
            PendingBroadcastQueue.consume(PendingBroadcastQueue.incomingReleaseKey("c1")),
        )
        idle()
        assertTrue(PendingBroadcastQueue.consume(PendingBroadcastQueue.incomingReleaseKey("c1")))
    }

    private fun offMain(block: () -> Unit) {
        val worker = Executors.newSingleThreadExecutor()
        try {
            worker.submit(block).get(5, TimeUnit.SECONDS)
        } finally {
            worker.shutdownNow()
        }
    }

    private fun report(callId: String): Deferred<PIncomingCallError?> = scope.async { core.registerIncomingCall(CallMetadata(callId = callId), "push") }.also { idle() }

    private fun event(
        event: CallLifecycleEvent,
        callId: String,
    ) {
        core.notifyConnectionEvent(event, CallMetadata(callId = callId).toBundle())
        idle()
    }

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    private fun Deferred<PIncomingCallError?>.result(): PIncomingCallError? {
        assertTrue("the registration should already be answered", isCompleted)
        return runBlocking { withTimeout(1_000) { await() } }
    }

    // A generic return avoids Kotlin inserting a null check for Mockito's matcher placeholder.
    private fun <T> anyArgument(): T = ArgumentMatchers.any()
}
