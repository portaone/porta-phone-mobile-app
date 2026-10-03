package com.webtrit.callkeep.services.core

import android.content.Context
import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.PEndCallReasonEnum
import com.webtrit.callkeep.PIncomingCallError
import com.webtrit.callkeep.PIncomingCallErrorEnum
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.models.FailureMetadata
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
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
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.ArgumentMatchers
import org.mockito.Mockito.doThrow
import org.mockito.Mockito.mock
import org.mockito.Mockito.never
import org.mockito.Mockito.times
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * Telecom lets one self-managed incoming call ring at a time. A call reported while another one
 * rings is not declined: the core holds it in its queue, with a notification, and puts it
 * through when the ringing call ends (the oldest first) or is answered.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class CallQueueTest {
    private lateinit var router: CallServiceRouter
    private lateinit var core: InProcessCallkeepCore
    private val notifier = FakeNotifier()
    private val heardEnded = mutableListOf<String>()
    private val endListener =
        ConnectionEventListener { event, data ->
            if (event == CallLifecycleEvent.HungUp) heardEnded += CallMetadata.fromBundle(data!!).callId
        }
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)

    @Before
    fun setUp() {
        ContextHolder.init(ApplicationProvider.getApplicationContext<Context>())
        ContextHolder.context.applicationInfo.apply {
            flags = flags and ApplicationInfo.FLAG_DEBUGGABLE.inv()
        }
        router = mock(CallServiceRouter::class.java)
        `when`(router.isTelecomSupported).thenReturn(true)
        core = InProcessCallkeepCore(tracker = MainProcessConnectionTracker(), routerInit = { router }, queueNotifier = notifier)
        core.addConnectionEventListener(endListener)
    }

    @After
    fun tearDown() {
        scope.cancel()
        core.endIncomingRegistrations()
    }

    @Test
    fun `a call reported while another one registers waits instead of reaching Telecom`() {
        report("push", "A")

        val b = report("app", "B")

        assertNull("the reporter holds it as an ordinary incoming call", b.result())
        assertTrue(core.isQueued("B"))
        assertEquals(listOf("B"), notifier.shown)
        verifyDispatched("A")
        verifyNotDispatched("B")
    }

    @Test
    fun `a call reported while another one rings waits`() {
        ringing("A")

        assertNull(report("app", "B").result())
        assertTrue(core.isQueued("B"))
        verifyNotDispatched("B")
    }

    @Test
    fun `a second report of a waiting call joins it`() {
        ringing("A")
        report("app", "B")

        assertNull(report("push", "B").result())
        assertEquals("one notification for one call", listOf("B"), notifier.shown)
    }

    @Test
    fun `the oldest waiting call is put through when the ringing call ends`() {
        ringing("A")
        report("app", "B")
        report("app", "C")

        event(CallLifecycleEvent.HungUp, "A")

        verifyDispatched("B")
        verifyNotDispatched("C")
        assertFalse(core.isQueued("B"))
        assertTrue(core.isQueued("C"))
        assertEquals(listOf("B"), notifier.cancelled)
    }

    @Test
    fun `a waiting call is put through when the ringing call is answered`() {
        ringing("A")
        report("app", "B")

        event(CallLifecycleEvent.AnswerCall, "A")

        verifyDispatched("B")
    }

    @Test
    fun `a waiting call Telecom refuses beside an active call waits for the end of all calls`() {
        // Some vendors (Huawei) refuse an incoming call beside an active one, not only beside a
        // ringing one. Putting the call through again on every event would only be refused again.
        ringing("A")
        report("app", "B")
        event(CallLifecycleEvent.AnswerCall, "A")
        verifyDispatched("B")

        failure("B")

        assertTrue("B waits again", core.isQueued("B"))
        event(CallLifecycleEvent.ConnectionStateChanged, "A")
        verify(router, times(1)).startIncomingCall(withCallId("B"), anyArgument(), anyArgument())

        event(CallLifecycleEvent.HungUp, "A")
        verify(router, times(2)).startIncomingCall(withCallId("B"), anyArgument(), anyArgument())
    }

    @Test
    fun `a waiting call the app reported stays the app's once it rings`() {
        ringing("A")
        report(mock(CallEndListener::class.java), "B")

        event(CallLifecycleEvent.HungUp, "A")

        // The app holds B as an ordinary incoming call: it is not presented to it a second time.
        verifyDispatched("B")
        assertTrue(core.isReportedByApp("B"))
    }

    @Test
    fun `a waiting call that ends leaves the queue and never reaches the backend`() {
        ringing("A")
        report("app", "B")

        core.reportCallEnded(CallMetadata(callId = "B"), PEndCallReasonEnum.UNANSWERED)
        idle()

        assertFalse(core.isQueued("B"))
        assertEquals(listOf("B"), notifier.cancelled)
        verify(router, never()).startDeclineCall(withCallId("B"))
        event(CallLifecycleEvent.HungUp, "A")
        verifyNotDispatched("B")
    }

    @Test
    fun `answering a waiting call declines the ringing one and answers it once it rings`() {
        ringing("A")
        report("app", "B")
        report("app", "C")

        assertTrue(core.answerQueuedCall("C"))
        verify(router).startDeclineCall(withCallId("A"))

        event(CallLifecycleEvent.HungUp, "A")
        verifyDispatched("C")
        verifyNotDispatched("B")

        event(CallLifecycleEvent.IncomingConnectionReported, "C")
        verify(router).startAnswerCall(withCallId("C"))
    }

    @Test
    fun `a call that is not waiting cannot be answered from the queue`() {
        assertFalse(core.answerQueuedCall("X"))
        assertFalse(core.dropQueuedCall("X"))
    }

    @Test
    fun `declining the ringing call puts the oldest waiting call through`() {
        ringing("A")
        report("app", "B")

        core.declineRingingCalls()
        verify(router).startDeclineCall(withCallId("A"))
        event(CallLifecycleEvent.DeclineCall, "A")

        verifyDispatched("B")
    }

    @Test
    fun `the standalone backend rings several calls itself and never queues`() {
        `when`(router.isTelecomSupported).thenReturn(false)
        ringing("A")

        report("app", "B")

        verifyDispatched("B")
        assertFalse(core.isQueued("B"))
    }

    @Test
    fun `the end of the session empties the queue and puts nothing through`() {
        report("push", "A")
        report("app", "B")

        core.endIncomingRegistrations()
        idle()

        assertFalse(core.isQueued("B"))
        assertEquals(listOf("B"), notifier.cancelled)
        verifyNotDispatched("B")
    }

    @Test
    fun `a call ended by the app while it is put through does not wait again`() {
        ringing("A")
        report("app", "B")
        event(CallLifecycleEvent.AnswerCall, "A")
        verifyDispatched("B")

        core.reportCallEnded(CallMetadata(callId = "B"), PEndCallReasonEnum.UNANSWERED)
        idle()

        assertFalse("its caller is gone; it must not ring later", core.isQueued("B"))
        assertEquals(listOf("B"), notifier.shown)
        assertFalse("the app ended it itself", "B" in heardEnded)
    }

    @Test
    fun `a waiting call Telecom refuses with no other call is ended for the app`() {
        ringing("A")
        report("app", "B")
        event(CallLifecycleEvent.HungUp, "A")
        verifyDispatched("B")

        failure("B")

        assertFalse(core.isQueued("B"))
        assertEquals("the app holds B as ringing and must decline it", listOf("B"), heardEnded.filter { it == "B" })
    }

    @Test
    fun `a waiting call whose dispatch throws is ended for the app instead of crashing`() {
        doThrow(IllegalStateException("start not allowed")).`when`(router).startIncomingCall(withCallId("B"), anyArgument(), anyArgument())
        ringing("A")
        report("app", "B")

        event(CallLifecycleEvent.HungUp, "A")

        assertEquals(listOf("B"), heardEnded.filter { it == "B" })
    }

    @Test
    fun `a waiting call that fails beside a live call for another reason than a refusal does not wait again`() {
        // Only Telecom refusing it beside the live call (IncomingFailure) means it can ring later;
        // any other failure (a dispatch that throws, a lost confirmation) would ring a dead call.
        doThrow(IllegalStateException("start not allowed")).`when`(router).startIncomingCall(withCallId("B"), anyArgument(), anyArgument())
        ringing("A")
        report("app", "B")

        event(CallLifecycleEvent.AnswerCall, "A")

        assertFalse(core.isQueued("B"))
        assertEquals(listOf("B"), heardEnded.filter { it == "B" })
    }

    @Test
    fun `a waiting call ended as never presented is not registered by a late report`() {
        ringing("A")
        report("app", "B")

        core.reportCallEnded(CallMetadata(callId = "B"), PEndCallReasonEnum.MISSED_WHILE_CONNECTING)
        idle()

        assertEquals(PIncomingCallError(PIncomingCallErrorEnum.CALL_ID_ALREADY_TERMINATED), report("push", "B").result())
        assertFalse(core.isQueued("B"))
    }

    @Test
    fun `the push session ending a waiting call takes it out of the queue`() {
        ringing("A")
        report("app", "B")
        report("app", "C")

        core.startDeclineCall(CallMetadata(callId = "B"))
        core.startHungUpCall(CallMetadata(callId = "C"))

        assertFalse(core.isQueued("B"))
        assertFalse(core.isQueued("C"))
        verify(router, never()).startDeclineCall(withCallId("B"))
        verify(router, never()).startHungUpCall(withCallId("C"))
        event(CallLifecycleEvent.HungUp, "A")
        verifyNotDispatched("B")
        verifyNotDispatched("C")
    }

    @Test
    fun `answering a call that waits for no call at all ends the live call`() {
        ringing("A")
        report("app", "B")
        event(CallLifecycleEvent.AnswerCall, "A")
        failure("B")
        assertTrue(core.isQueued("B"))

        assertTrue(core.answerQueuedCall("B"))

        verify(router).startHungUpCall(withCallId("A"))
    }

    @Test
    fun `the waiting calls are listed oldest first`() {
        ringing("A")
        report("app", "B")
        report("app", "C")

        assertEquals(listOf("B", "C"), core.queuedCallIds())
    }

    // A ringing call: registered and confirmed by Telecom.
    private fun ringing(callId: String) {
        val result = report("push", callId)
        event(CallLifecycleEvent.IncomingConnectionReported, callId)
        assertNull(result.result())
    }

    private fun report(
        client: Any,
        callId: String,
    ): Deferred<PIncomingCallError?> =
        scope.async(start = CoroutineStart.UNDISPATCHED) {
            core.registerIncomingCall(CallMetadata(callId = callId), client)
        }

    private fun event(
        event: CallLifecycleEvent,
        callId: String,
    ) {
        core.notifyConnectionEvent(event, CallMetadata(callId = callId).toBundle())
        idle()
    }

    private fun failure(callId: String) {
        core.notifyConnectionEvent(
            CallLifecycleEvent.IncomingFailure,
            FailureMetadata(CallMetadata(callId = callId), "onCreateIncomingConnectionFailed: callId=$callId").toBundle(),
        )
        idle()
    }

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    private fun Deferred<PIncomingCallError?>.result(): PIncomingCallError? {
        idle()
        assertTrue("the registration should already be answered", isCompleted)
        return runBlocking { withTimeout(1_000) { await() } }
    }

    private fun verifyDispatched(callId: String) {
        verify(router).startIncomingCall(withCallId(callId), anyArgument(), anyArgument())
    }

    private fun verifyNotDispatched(callId: String) {
        verify(router, never()).startIncomingCall(withCallId(callId), anyArgument(), anyArgument())
    }

    private fun withCallId(callId: String): CallMetadata {
        ArgumentMatchers.argThat<CallMetadata> { it?.callId == callId }
        return CallMetadata(callId = callId)
    }

    // A generic return avoids Kotlin inserting a null check for Mockito's matcher placeholder.
    private fun <T> anyArgument(): T = ArgumentMatchers.any()

    private class FakeNotifier : QueuedCallNotifier {
        val shown = mutableListOf<String>()
        val cancelled = mutableListOf<String>()

        override fun show(metadata: CallMetadata) {
            shown += metadata.callId
        }

        override fun cancel(callId: String) {
            cancelled += callId
        }
    }
}
