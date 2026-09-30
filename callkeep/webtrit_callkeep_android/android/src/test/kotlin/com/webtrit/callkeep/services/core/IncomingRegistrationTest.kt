package com.webtrit.callkeep.services.core

import android.content.Context
import android.os.Build
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.PCallkeepConnectionState
import com.webtrit.callkeep.PIncomingCallError
import com.webtrit.callkeep.PIncomingCallErrorEnum
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.common.Log
import com.webtrit.callkeep.models.CallConnectionState
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.models.FailureMetadata
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.broadcaster.ConnectionServicePerformBroadcaster
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
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.ArgumentMatchers
import org.mockito.Mockito.doAnswer
import org.mockito.Mockito.mock
import org.mockito.Mockito.spy
import org.mockito.Mockito.times
import org.mockito.Mockito.verify
import org.mockito.Mockito.verifyNoInteractions
import org.mockito.Mockito.verifyNoMoreInteractions
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLog
import java.util.concurrent.TimeUnit

/** Registration owns dispatch, confirmation and cleanup, whether an activity bridge exists or not. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class IncomingRegistrationTest {
    private lateinit var router: CallServiceRouter
    private lateinit var core: InProcessCallkeepCore
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)

    @Before
    fun setUp() {
        ContextHolder.init(ApplicationProvider.getApplicationContext<Context>())
        router = mock(CallServiceRouter::class.java)
        core = InProcessCallkeepCore(tracker = MainProcessConnectionTracker(), routerInit = { router })
    }

    @After
    fun tearDown() {
        scope.cancel()
        core.endIncomingRegistrations()
    }

    @Test
    fun `dispatch success still waits for Telecom confirmation`() {
        stubRouter { _, onSuccess, _ -> onSuccess() }

        val waiting = report("push", "c1")

        assertFalse(waiting.isCompleted)
        assertTrue(core.isPending("c1"))
        assertFalse(core.exists("c1"))
    }

    @Test
    fun `without a foreground service confirmation promotes before answering the caller`() {
        var stateWhenAnswered: PCallkeepConnectionState? = null
        val waiting =
            scope.async(start = CoroutineStart.UNDISPATCHED) {
                core.registerIncomingCall(CallMetadata(callId = "c1"), "push").also {
                    stateWhenAnswered = core.getState("c1")
                }
            }

        event(CallLifecycleEvent.IncomingConnectionReported, "c1")

        assertNull(waiting.result())
        assertEquals(PCallkeepConnectionState.STATE_RINGING, stateWhenAnswered)
        assertFalse(core.isPending("c1"))
        assertTrue(core.exists("c1"))
    }

    @Test
    fun `a foreground listener does not take over confirmation`() {
        core.addConnectionEventListener(mock(CallEndListener::class.java))
        val waiting = report("push", "c1")

        event(CallLifecycleEvent.IncomingConnectionReported, "c1")

        assertNull(waiting.result())
        assertEquals(PCallkeepConnectionState.STATE_RINGING, core.getState("c1"))
        assertFalse(core.isPending("c1"))
    }

    @Test
    fun `a registration made before anything listens still hears Telecom broadcast`() {
        val waiting = report("push", "c1")

        ConnectionServicePerformBroadcaster.handle.dispatch(
            ApplicationProvider.getApplicationContext(),
            CallLifecycleEvent.IncomingConnectionReported,
            CallMetadata(callId = "c1").toBundle(),
        )
        shadowOf(Looper.getMainLooper()).idle()

        assertNull(waiting.result())
        assertEquals(PCallkeepConnectionState.STATE_RINGING, core.getState("c1"))
    }

    @Test
    fun `confirmation delivered synchronously during dispatch is not lost`() {
        stubRouter { metadata, _, _ -> event(CallLifecycleEvent.IncomingConnectionReported, metadata.callId) }

        val waiting = report("push", "c1")

        assertNull(waiting.result())
        advanceSeconds(6)
        assertEquals(PCallkeepConnectionState.STATE_RINGING, core.getState("c1"))
        assertFalse(core.isTerminated("c1"))
    }

    @Test
    fun `a deferred answer confirms registration with metadata before reaching the listener`() {
        val listener = mock(CallEndListener::class.java)
        core.addConnectionEventListener(listener)
        val metadata = CallMetadata(callId = "c1", displayName = "Alice", hasVideo = true)
        var stateWhenAnswered: PCallkeepConnectionState? = null
        val waiting =
            scope.async(start = CoroutineStart.UNDISPATCHED) {
                core.registerIncomingCall(metadata, "push").also {
                    stateWhenAnswered = core.getState("c1")
                }
            }
        val answer = CallMetadata(callId = "c1").toBundle()

        core.notifyConnectionEvent(CallLifecycleEvent.AnswerCall, answer)

        assertNull(waiting.result())
        assertEquals(PCallkeepConnectionState.STATE_ACTIVE, stateWhenAnswered)
        assertEquals("Alice", core.get("c1")?.displayName)
        assertEquals(true, core.get("c1")?.hasVideo)
        assertFalse(core.isPending("c1"))
        verify(listener).onConnectionEvent(CallLifecycleEvent.AnswerCall, answer)
        verifyNoMoreInteractions(listener)
        advanceSeconds(6)
        assertFalse(core.isTerminated("c1"))
    }

    @Test
    fun `a confirmed push answer is tracked without a foreground listener`() {
        val waiting = report("push", "c1")
        event(CallLifecycleEvent.IncomingConnectionReported, "c1")
        assertNull(waiting.result())

        event(CallLifecycleEvent.AnswerCall, "c1")

        assertTrue(core.isAnswered("c1"))
        assertEquals(PCallkeepConnectionState.STATE_ACTIVE, core.getState("c1"))
    }

    @Test
    fun `a reported end before timeout cannot become provisional when the deadline passes`() {
        val waiting = report("push", "c1")
        core.markTerminated("c1")
        assertEquals(rejected(), waiting.result())
        advanceSeconds(5)
        core.updateState("c1", CallConnectionState.ACTIVE)

        event(CallLifecycleEvent.AnswerCall, "c1")
        event(CallLifecycleEvent.IncomingConnectionReported, "c1")

        assertFalse(core.exists("c1"))
        assertFalse(core.isAnswered("c1"))
    }

    @Test
    fun `a reported end after timeout is final even before the terminal broadcast`() {
        val waiting = report("push", "c1")
        advanceSeconds(5)
        assertEquals(rejected(), waiting.result())
        core.markTerminated("c1")

        event(CallLifecycleEvent.IncomingConnectionReported, "c1")
        event(CallLifecycleEvent.AnswerCall, "c1")

        assertTrue(core.isTerminated("c1"))
        assertFalse(core.isAnswered("c1"))
    }

    @Test
    fun `a duplicate confirmation does not downgrade an active call`() {
        val metadata = CallMetadata(callId = "c1", displayName = "Alice")
        core.promote("c1", metadata, PCallkeepConnectionState.STATE_ACTIVE)
        core.markAnswered("c1")

        event(CallLifecycleEvent.IncomingConnectionReported, "c1")

        assertEquals(PCallkeepConnectionState.STATE_ACTIVE, core.getState("c1"))
        assertEquals("Alice", core.get("c1")?.displayName)
        assertTrue(core.isAnswered("c1"))
    }

    @Test
    fun `a confirmation after timeout cannot revive a rejected call and cancels it again`() {
        assertLateTimeoutEventCancelled(CallLifecycleEvent.IncomingConnectionReported)
    }

    @Test
    fun `an answer after timeout cannot reach Flutter and cancels the native call again`() {
        assertLateTimeoutEventCancelled(CallLifecycleEvent.AnswerCall)
    }

    @Test
    fun `a replay after timeout cannot present the rejected call and cancels it again`() {
        assertLateTimeoutEventCancelled(CallLifecycleEvent.ReplayIncomingCall)
    }

    @Test
    fun `an active state after timeout cannot change the rejected call or reach a listener`() {
        val waiting = report("push", "c1")
        advanceSeconds(5)
        assertEquals(rejected(), waiting.result())
        val listener = mock(CallEndListener::class.java)
        core.addConnectionEventListener(listener)

        core.notifyConnectionEvent(
            CallLifecycleEvent.ConnectionStateChanged,
            CallMetadata(callId = "c1", connectionState = CallConnectionState.ACTIVE).toBundle(),
        )

        assertEquals(PCallkeepConnectionState.STATE_DISCONNECTED, core.getState("c1"))
        assertFalse(core.exists("c1"))
        assertFalse(core.isAnswered("c1"))
        verifyNoInteractions(listener)
    }

    @Test
    fun `an answer after timeout stays rejected after its client detaches without a listener`() {
        val waiting = report("app", CallMetadata(callId = "c1", displayName = "Alice"))
        advanceSeconds(5)
        assertEquals(rejected(), waiting.result())
        core.detachIncomingClient("app")

        event(CallLifecycleEvent.AnswerCall, "c1")

        assertEquals(PCallkeepConnectionState.STATE_DISCONNECTED, core.getState("c1"))
        assertNull(core.get("c1"))
        assertFalse(core.isAnswered("c1"))
        assertTrue(core.isTerminated("c1"))
        verify(router, times(2)).cancelIncomingCall(anyArgument())
    }

    @Test
    fun `a Telecom refusal after timeout prevents later confirmation or answer`() {
        assertTimeoutFinalized { event(CallLifecycleEvent.IncomingFailure, "c1") }
    }

    @Test
    fun `a terminal event after timeout prevents later confirmation or answer`() {
        assertTimeoutFinalized { event(CallLifecycleEvent.HungUp, "c1") }
    }

    @Test
    fun `an app ending its timed out call prevents later confirmation or answer`() {
        assertTimeoutFinalized { core.appEndingCall("c1") }
    }

    @Test
    fun `ending the session after timeout prevents later confirmation or answer`() {
        assertTimeoutFinalized { core.endIncomingRegistrations() }
    }

    @Test
    fun `concurrent reports dispatch once and the joiner learns the call exists`() {
        val push = report("push", "c1")
        val signaling = report("signaling", "c1")
        assertFalse(push.isCompleted)
        assertFalse(signaling.isCompleted)
        verifyDispatches(1)

        event(CallLifecycleEvent.IncomingConnectionReported, "c1")

        assertNull(push.result())
        assertEquals(alreadyExists(), signaling.result())
    }

    @Test
    fun `a refusal rejects every report and drains pending state`() {
        val push = report("push", "c1")
        val signaling = report("signaling", "c1")

        event(CallLifecycleEvent.IncomingFailure, "c1")

        assertEquals(rejected(), push.result())
        assertEquals(rejected(), signaling.result())
        assertFalse(core.isPending("c1"))
        assertTrue(core.isTerminated("c1"))
    }

    @Test
    fun `a foreground listener does not take over a refusal`() {
        core.addConnectionEventListener(mock(CallEndListener::class.java))
        val waiting = report("push", "c1")

        event(CallLifecycleEvent.IncomingFailure, "c1")

        assertEquals(rejected(), waiting.result())
        assertFalse(core.isPending("c1"))
        assertTrue(core.isTerminated("c1"))
    }

    @Test
    fun `a hangup before confirmation rejects without a foreground service`() {
        val waiting = report("push", "c1")

        event(CallLifecycleEvent.HungUp, "c1")

        assertEquals(rejected(), waiting.result())
        assertFalse(core.isPending("c1"))
        assertTrue(core.isTerminated("c1"))
    }

    @Test
    fun `a hangup rejecting registration is consumed before the foreground listener`() {
        val listener = mock(CallEndListener::class.java)
        core.addConnectionEventListener(listener)
        val waiting = report("push", "c1")

        event(CallLifecycleEvent.HungUp, "c1")

        assertEquals(rejected(), waiting.result())
        assertTrue(core.isTerminated("c1"))
        verifyNoInteractions(listener)
    }

    @Test
    fun `an app ending its pending call succeeds registration and preserves the normal end event`() {
        val listener = mock(CallEndListener::class.java)
        core.addConnectionEventListener(listener)
        val waiting = report("app", "c1")

        core.appEndingCall("c1")

        assertNull(waiting.result())
        assertTrue("the regular end handler still owns its notification", core.markEndCallDispatched("c1"))
        val metadata = CallMetadata(callId = "c1").toBundle()
        core.notifyConnectionEvent(CallLifecycleEvent.HungUp, metadata)
        verify(listener).onConnectionEvent(CallLifecycleEvent.HungUp, metadata)
    }

    @Test
    fun `dispatch rejection reaches every joined caller and permits a fresh attempt`() {
        val error = PIncomingCallError(PIncomingCallErrorEnum.UNKNOWN)
        lateinit var joined: Deferred<PIncomingCallError?>
        stubRouter { _, _, onError ->
            joined = report("signaling", "c1")
            onError(error)
        }

        val owner = report("push", "c1")

        assertEquals(error, owner.result())
        assertEquals(error, joined.result())
        assertFalse(core.isPending("c1"))
        stubRouter { _, _, _ -> }
        val retried = report("retry", "c1")
        assertFalse(retried.isCompleted)
        verifyDispatches(2)
        event(CallLifecycleEvent.IncomingConnectionReported, "c1")
        assertNull(retried.result())
    }

    @Test
    fun `a backend answering one dispatch twice drains pending once`() {
        val tracker = spy(MainProcessConnectionTracker())
        core = InProcessCallkeepCore(tracker = tracker, routerInit = { router })
        val error = PIncomingCallError(PIncomingCallErrorEnum.INTERNAL)
        stubRouter { _, _, onError ->
            onError(error)
            onError(error)
        }

        val owner = report("push", "c1")

        assertEquals(error, owner.result())
        verify(tracker, times(1)).removePending("c1")
    }

    @Test
    fun `dispatch throw reaches all joined callers unchanged and permits a fresh attempt`() {
        val failure = SecurityException("Telecom denied access")
        lateinit var joined: Deferred<PIncomingCallError?>
        stubRouter { _, _, _ ->
            joined = report("signaling", "c1")
            throw failure
        }

        val owner = report("push", "c1")

        assertDispatchFailure(failure, owner)
        assertDispatchFailure(failure, joined)
        assertFalse(core.isPending("c1"))
        stubRouter { _, _, _ -> }
        val retried = report("retry", "c1")
        assertFalse(retried.isCompleted)
        verifyDispatches(2)
        event(CallLifecycleEvent.IncomingConnectionReported, "c1")
        assertNull(retried.result())
    }

    @Test
    fun `an existing active call is adopted as answered without another dispatch`() {
        core.promote("c1", CallMetadata(callId = "c1"), PCallkeepConnectionState.STATE_ACTIVE)

        val waiting = report("app", "c1")

        assertEquals(PIncomingCallError(PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS_AND_ANSWERED), waiting.result())
        assertTrue(core.isAnswered("c1"))
        assertEquals(PCallkeepConnectionState.STATE_ACTIVE, core.getState("c1"))
        assertFalse(core.isPending("c1"))
        verifyNoInteractions(router)
    }

    @Test
    fun `a backend duplicate adopts a cold active connection as answered`() {
        core.updateState("c1", CallConnectionState.ACTIVE)
        stubRouter { _, _, onError -> onError(alreadyExists()) }

        val waiting = report("app", "c1")

        assertEquals(PIncomingCallError(PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS_AND_ANSWERED), waiting.result())
        assertTrue(core.isAnswered("c1"))
        assertTrue(core.exists("c1"))
        assertEquals(PCallkeepConnectionState.STATE_ACTIVE, core.getState("c1"))
        assertFalse(core.isPending("c1"))
        advanceSeconds(6)
        assertFalse(core.isTerminated("c1"))
    }

    @Test
    fun `the ghost guard rejects a late presentation without dispatch`() {
        core.markEndedWithoutFlutterState("c1")

        val waiting = report("push", "c1")

        assertEquals(PIncomingCallError(PIncomingCallErrorEnum.CALL_ID_ALREADY_TERMINATED), waiting.result())
        assertFalse(core.isPending("c1"))
        assertFalse(core.exists("c1"))
        verifyNoInteractions(router)
    }

    @Test
    fun `a client going away rejects a registration only it awaited`() {
        val waiting = report("app", "c1")

        core.detachIncomingClient("app")

        assertEquals(rejected(), waiting.result())
        assertFalse(core.isPending("c1"))
        assertTrue(core.isTerminated("c1"))
    }

    @Test
    fun `detaching a joined app client keeps the original push registration alive`() {
        val push = report("push", "c1")
        val app = report("app", "c1")

        core.detachIncomingClient("app")

        assertEquals(rejected(), app.result())
        assertFalse(push.isCompleted)
        assertTrue(core.isPending("c1"))
        event(CallLifecycleEvent.IncomingConnectionReported, "c1")
        assertNull(push.result())
    }

    @Test
    fun `detaching the dispatching app client keeps a joined push registration alive`() {
        val app = report("app", "c1")
        val push = report("push", "c1")

        core.detachIncomingClient("app")

        assertEquals(rejected(), app.result())
        assertFalse(push.isCompleted)
        assertTrue(core.isPending("c1"))
        event(CallLifecycleEvent.IncomingConnectionReported, "c1")
        assertEquals(alreadyExists(), push.result())
        assertFalse(core.isTerminated("c1"))
    }

    @Test
    fun `cancelling one caller leaves the joined caller and backend operation alive`() {
        val owner = report("app", "c1")
        val joined = report("push", "c1")

        owner.cancel()

        assertTrue(owner.isCancelled)
        assertFalse(joined.isCompleted)
        assertTrue(core.isPending("c1"))
        event(CallLifecycleEvent.IncomingConnectionReported, "c1")
        assertEquals(alreadyExists(), joined.result())
        verifyDispatches(1)
        assertFalse(core.isTerminated("c1"))
    }

    @Test
    fun `cancelling the sole caller does not abort an already dispatched backend operation`() {
        val cancelled = report("push", "c1")

        cancelled.cancel()

        assertTrue(core.isPending("c1"))
        val joined = report("app", "c1")
        event(CallLifecycleEvent.IncomingConnectionReported, "c1")
        assertEquals(alreadyExists(), joined.result())
        verifyDispatches(1)
        assertTrue(core.exists("c1"))
    }

    @Test
    fun `timeout cancels the native call before rejecting each joined caller once`() {
        val metadata = CallMetadata(callId = "c1", displayName = "Alice", hasVideo = true)
        val completions = mutableListOf<String>()
        var cancellations = 0
        doAnswer {
            assertTrue("the call must already be final before native cancellation", core.wasEndedWithoutFlutterState("c1"))
            assertFalse(core.isPending("c1"))
            assertTrue(core.isTerminated("c1"))
            cancellations++
            null
        }.`when`(router).cancelIncomingCall(metadata.callId)

        fun waiting(client: String) =
            scope.async(start = CoroutineStart.UNDISPATCHED) {
                core.registerIncomingCall(metadata, client).also {
                    assertEquals("native cancellation must precede the result that declines on the server", 1, cancellations)
                    completions += client
                }
            }
        val push = waiting("push")
        val app = waiting("app")

        advanceSeconds(5)

        assertEquals(rejected(), push.result())
        assertEquals(rejected(), app.result())
        assertEquals(listOf("app", "push"), completions.sorted())
        verifyDispatches(1)
        verify(router).cancelIncomingCall(metadata.callId)
        advanceSeconds(6)
        assertEquals("each joined host call completes only once", listOf("app", "push"), completions.sorted())
        verify(router).cancelIncomingCall(metadata.callId)
    }

    @Test
    fun `a failed native cancellation is logged and does not strand the rejected callers`() {
        Log.clearLogFilePath()
        val failure = IllegalStateException("Cannot dispatch native cancellation")
        doAnswer { throw failure }.`when`(router).cancelIncomingCall(anyArgument())
        val push = report("push", "c1")
        val app = report("app", "c1")

        advanceSeconds(5)

        assertEquals(rejected(), push.result())
        assertEquals(rejected(), app.result())
        assertTrue(core.wasEndedWithoutFlutterState("c1"))
        assertFalse(core.isPending("c1"))
        assertTrue(core.isTerminated("c1"))
        assertTrue(ShadowLog.getLogs().any { it.throwable === failure && it.msg.contains("c1") })
        verify(router).cancelIncomingCall(anyArgument())

        event(CallLifecycleEvent.AnswerCall, "c1")

        assertFalse(core.isAnswered("c1"))
        assertFalse(core.exists("c1"))
        verify(router, times(2)).cancelIncomingCall(anyArgument())
    }

    @Test
    fun `ending the session rejects all clients and removes timers from a retry`() {
        val push = report("push", "c1")
        val app = report("app", "c1")
        val other = report("another-push", "c2")
        advanceSeconds(4)

        core.endIncomingRegistrations()

        assertEquals(rejected(), push.result())
        assertEquals(rejected(), app.result())
        assertEquals(rejected(), other.result())
        assertTrue(core.getPendingCallIds().isEmpty())
        assertTrue(core.isTerminated("c1"))
        assertTrue(core.isTerminated("c2"))
        assertTrue(core.consumeDirectNotified("c1"))
        assertTrue(core.consumeDirectNotified("c2"))
        val retried = report("new-session", "c1")
        advanceSeconds(2)
        assertFalse("the previous operation timer cannot reject this attempt", retried.isCompleted)
        assertTrue(core.isPending("c1"))
        verifyDispatches(3)
        event(CallLifecycleEvent.IncomingConnectionReported, "c1")
        assertNull(retried.result())
    }

    @Test
    fun `a late dispatch rejection cannot remove a confirmed call`() {
        lateinit var rejectDispatch: (PIncomingCallError?) -> Unit
        stubRouter { _, _, onError -> rejectDispatch = onError }
        val waiting = report("push", "c1")
        event(CallLifecycleEvent.IncomingConnectionReported, "c1")
        assertNull(waiting.result())

        rejectDispatch(PIncomingCallError(PIncomingCallErrorEnum.UNKNOWN))

        assertTrue(core.exists("c1"))
        assertEquals(PCallkeepConnectionState.STATE_RINGING, core.getState("c1"))
        assertFalse(core.isTerminated("c1"))
    }

    @Test
    fun `a late dispatch rejection cannot drain a replacement with the same call id`() {
        lateinit var rejectOldDispatch: (PIncomingCallError?) -> Unit
        stubRouter { _, _, onError -> rejectOldDispatch = onError }
        val previous = report("old-push", "c1")
        core.endIncomingRegistrations()
        assertEquals(rejected(), previous.result())
        stubRouter { _, _, _ -> }
        val current = report("new-push", "c1")

        rejectOldDispatch(PIncomingCallError(PIncomingCallErrorEnum.UNKNOWN))

        assertFalse(current.isCompleted)
        assertTrue(core.isPending("c1"))
        event(CallLifecycleEvent.IncomingConnectionReported, "c1")
        assertNull(current.result())
        verifyDispatches(2)
    }

    @Test
    fun `timeout blocks the same call id while a different call gets its own deadline`() {
        lateinit var rejectOldDispatch: (PIncomingCallError?) -> Unit
        stubRouter { _, _, onError -> rejectOldDispatch = onError }
        val previous = report("old-push", "c1")
        advanceSeconds(5)
        assertEquals(rejected(), previous.result())
        stubRouter { _, _, _ -> }

        val retried = report("retry", "c1")
        val current = report("new-push", "c2")
        advanceSeconds(4)
        rejectOldDispatch(PIncomingCallError(PIncomingCallErrorEnum.UNKNOWN))

        assertEquals(PIncomingCallError(PIncomingCallErrorEnum.CALL_ID_ALREADY_TERMINATED), retried.result())
        assertFalse(core.isPending("c1"))
        assertFalse(current.isCompleted)
        assertTrue(core.isPending("c2"))
        verifyDispatches(2)
        advanceSeconds(1)
        assertEquals(rejected(), current.result())
        assertFalse(core.isPending("c2"))
    }

    private fun assertLateTimeoutEventCancelled(lateEvent: CallLifecycleEvent) {
        val metadata = CallMetadata(callId = "c1", displayName = "Alice", hasVideo = true)
        val cancelledCallIds = mutableListOf<String>()
        doAnswer {
            cancelledCallIds += it.getArgument<String>(0)
            null
        }.`when`(router).cancelIncomingCall(anyArgument())
        val waiting = report("push", metadata)
        advanceSeconds(5)
        assertEquals(rejected(), waiting.result())
        verify(router).cancelIncomingCall(metadata.callId)
        val listener = mock(CallEndListener::class.java)
        core.addConnectionEventListener(listener)

        event(lateEvent, "c1")

        assertEquals(PCallkeepConnectionState.STATE_DISCONNECTED, core.getState("c1"))
        assertNull(core.get("c1"))
        assertTrue(core.wasEndedWithoutFlutterState("c1"))
        assertTrue(core.isTerminated("c1"))
        assertFalse(core.isPending("c1"))
        assertFalse(core.exists("c1"))
        assertFalse(core.isAnswered("c1"))
        verifyNoInteractions(listener)
        verify(router, times(2)).cancelIncomingCall(anyArgument())
        assertEquals(listOf("c1", "c1"), cancelledCallIds)
        assertEquals(rejected(), waiting.result())
    }

    private fun assertTimeoutFinalized(finalize: () -> Unit) {
        val waiting = report("push", "c1")
        advanceSeconds(5)
        assertEquals(rejected(), waiting.result())

        finalize()
        val listener = mock(CallEndListener::class.java)
        core.addConnectionEventListener(listener)
        event(CallLifecycleEvent.IncomingConnectionReported, "c1")
        event(CallLifecycleEvent.AnswerCall, "c1")

        assertFalse(core.exists("c1"))
        assertFalse(core.isAnswered("c1"))
        assertTrue(core.isTerminated("c1"))
        verifyNoInteractions(listener)
    }

    private fun report(
        client: Any,
        callId: String,
    ): Deferred<PIncomingCallError?> = report(client, CallMetadata(callId = callId))

    private fun report(
        client: Any,
        metadata: CallMetadata,
    ): Deferred<PIncomingCallError?> =
        scope.async(start = CoroutineStart.UNDISPATCHED) {
            core.registerIncomingCall(metadata, client)
        }

    // Each event has the actual IPC shape: a refusal wraps its call in FailureMetadata.
    private fun event(
        event: CallLifecycleEvent,
        callId: String,
    ) = core.notifyConnectionEvent(
        event,
        if (event == CallLifecycleEvent.IncomingFailure) {
            FailureMetadata(CallMetadata(callId = callId), "onCreateIncomingConnectionFailed: callId=$callId").toBundle()
        } else {
            CallMetadata(callId = callId).toBundle()
        },
    )

    private fun rejected() = PIncomingCallError(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM)

    private fun alreadyExists() = PIncomingCallError(PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS)

    private fun advanceSeconds(seconds: Long) = shadowOf(Looper.getMainLooper()).idleFor(seconds, TimeUnit.SECONDS)

    private fun Deferred<PIncomingCallError?>.result(): PIncomingCallError? {
        assertTrue("the registration should already be answered", isCompleted)
        return runBlocking { withTimeout(1_000) { await() } }
    }

    private fun Deferred<PIncomingCallError?>.failure(): Throwable? {
        assertTrue("the registration should already have failed", isCompleted)
        return runBlocking { withTimeout(1_000) { runCatching { await() }.exceptionOrNull() } }
    }

    private fun assertDispatchFailure(
        expected: Throwable,
        result: Deferred<PIncomingCallError?>,
    ) {
        val actual = result.failure()
        assertEquals(expected.javaClass, actual?.javaClass)
        assertEquals(expected.message, actual?.message)
        // Coroutine stack recovery may copy the exception while retaining its original cause.
        assertSame(expected, generateSequence(actual) { it.cause }.last())
    }

    private fun verifyDispatches(count: Int) {
        verify(router, times(count)).startIncomingCall(anyArgument(), anyArgument(), anyArgument())
    }

    private fun stubRouter(handler: (CallMetadata, () -> Unit, (PIncomingCallError?) -> Unit) -> Unit) {
        doAnswer { invocation ->
            handler(invocation.getArgument(0), invocation.getArgument(1), invocation.getArgument(2))
            null
        }.`when`(router).startIncomingCall(anyArgument(), anyArgument(), anyArgument())
    }

    // A generic return avoids Kotlin inserting a null check for Mockito's matcher placeholder.
    private fun <T> anyArgument(): T = ArgumentMatchers.any()
}
