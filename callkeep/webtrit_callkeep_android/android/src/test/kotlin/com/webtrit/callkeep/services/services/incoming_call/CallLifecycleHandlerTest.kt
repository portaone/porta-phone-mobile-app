package com.webtrit.callkeep.services.services.incoming_call

import android.content.Context
import android.os.Build
import android.os.Looper
import com.webtrit.callkeep.PCallkeepIncomingCallData
import com.webtrit.callkeep.PEndCallReason
import com.webtrit.callkeep.PEndCallReasonEnum
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.core.CallkeepCore
import com.webtrit.callkeep.services.services.incoming_call.handlers.CallLifecycleHandler
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.ArgumentMatchers
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLooper

/**
 * Unit tests for [CallLifecycleHandler].
 *
 * Verifies the decline teardown ordering: performEndCall() must invoke the Flutter-side
 * BYE *before* release() stops the service. In the new design, releaseResources is no
 * longer part of FlutterIsolateCommunicator — the Dart isolate manages its own resource
 * cleanup. release() now calls stopServiceWithDelay() directly.
 *
 * Uses hand-written fakes for [FlutterIsolateCommunicator] to record call order without
 * requiring the mockito-kotlin extension library.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class CallLifecycleHandlerTest {
    // -------------------------------------------------------------------------
    // Fakes
    // -------------------------------------------------------------------------

    /**
     * Records every call made to [FlutterIsolateCommunicator] and lets tests
     * control whether [performEndCall] triggers onSuccess or onFailure.
     */
    private class FakeCommunicator(
        private val endCallResult: EndCallResult = EndCallResult.SUCCESS,
    ) : FlutterIsolateCommunicator {
        enum class EndCallResult { SUCCESS, FAILURE }

        val events = mutableListOf<String>()
        var lastPerformEndCallId: String? = null
        val handoffCallIds = mutableListOf<String>()

        override fun performAnswer(
            callId: String,
            onSuccess: () -> Unit,
            onFailure: (Throwable) -> Unit,
        ) {
            events.add("performAnswer")
            onSuccess()
        }

        override fun performEndCall(
            callId: String,
            onSuccess: () -> Unit,
            onFailure: (Throwable) -> Unit,
        ) {
            events.add("performEndCall")
            lastPerformEndCallId = callId
            when (endCallResult) {
                EndCallResult.SUCCESS -> onSuccess()
                EndCallResult.FAILURE -> onFailure(RuntimeException("BYE failed"))
            }
        }

        override fun performHandoff(
            callId: String,
            onSuccess: () -> Unit,
            onFailure: (Throwable) -> Unit,
        ) {
            events.add("performHandoff")
            handoffCallIds += callId
            onSuccess()
        }

        override fun syncPushIsolate(
            callData: com.webtrit.callkeep.PCallkeepIncomingCallData?,
            onSuccess: () -> Unit,
            onFailure: (Throwable) -> Unit,
        ) {
            events.add("syncPushIsolate")
            onSuccess()
        }
    }

    // -------------------------------------------------------------------------
    // Fakes (continued)
    // -------------------------------------------------------------------------

    /**
     * Records calls to [CallConnectionController] without Mockito argument matchers,
     * avoiding Kotlin non-null / Mockito.any() NPE issues.
     */
    private class FakeConnectionController : CallConnectionController {
        var answerCallCount = 0
        var tearDownCallCount = 0
        val declinedCallIds = mutableListOf<String>()

        override fun answer(metadata: CallMetadata) {
            answerCallCount++
        }

        override fun decline(metadata: CallMetadata) {
            declinedCallIds.add(metadata.callId)
        }

        override fun hangUp(metadata: CallMetadata) {}

        override fun tearDown() {
            tearDownCallCount++
        }
    }

    // -------------------------------------------------------------------------
    // Fixtures
    // -------------------------------------------------------------------------

    private val context: Context = RuntimeEnvironment.getApplication()

    private lateinit var handler: CallLifecycleHandler
    private lateinit var communicator: FakeCommunicator
    private lateinit var fakeController: FakeConnectionController
    private lateinit var core: CallkeepCore
    private val stopServiceCalls = mutableListOf<String>()

    @Before
    fun setUp() {
        communicator = FakeCommunicator()
        fakeController = FakeConnectionController()
        core = mock(CallkeepCore::class.java)
        handler =
            CallLifecycleHandler(
                connectionController = fakeController,
                stopService = { stopServiceCalls.add("stop") },
                isolateHandler = mock(com.webtrit.callkeep.services.services.incoming_call.handlers.FlutterIsolateHandler::class.java),
                core = core,
            )
        handler.flutterApi = communicator
        handler.currentCallData =
            PCallkeepIncomingCallData(
                callId = "call-1",
                handle = mock(com.webtrit.callkeep.PHandle::class.java),
                displayName = null,
                hasVideo = false,
            )
    }

    // -------------------------------------------------------------------------
    // performEndCall — ordering: BYE first, stopService after delay
    // -------------------------------------------------------------------------

    /**
     * The session ends the call on the server and then records it; its callback future, not the
     * answer to performEndCall, says when the service may stop.
     */
    @Test
    fun `performEndCall asks the session and leaves the service running`() {
        handler.performEndCall(CallMetadata(callId = "call-1"))
        ShadowLooper.runUiThreadTasksIncludingDelayedTasks()

        assertEquals(listOf("performEndCall"), communicator.events)
        assertEquals("call-99 style id must reach the session", "call-1", communicator.lastPerformEndCallId)
        assertTrue("the session's future stops the service, not this answer", stopServiceCalls.isEmpty())
    }

    @Test
    fun `performEndCall failing leaves the service to its budget`() {
        communicator = FakeCommunicator(FakeCommunicator.EndCallResult.FAILURE)
        handler.flutterApi = communicator

        handler.performEndCall(CallMetadata(callId = "call-1"))
        ShadowLooper.runUiThreadTasksIncludingDelayedTasks()

        assertTrue(communicator.events.contains("performEndCall"))
        assertTrue("a failed end does not stop the service here: the service's timeout does", stopServiceCalls.isEmpty())
    }

    @Test
    fun `performHandoff tells the session and leaves the service running`() {
        handler.performHandoff(CallMetadata(callId = "call-1"))
        ShadowLooper.runUiThreadTasksIncludingDelayedTasks()

        assertEquals(listOf("call-1"), communicator.handoffCallIds)
        assertTrue(stopServiceCalls.isEmpty())
    }

    @Test
    fun `performHandoff with null flutterApi stops the service`() {
        handler.flutterApi = null

        handler.performHandoff(CallMetadata(callId = "call-1"))
        ShadowLooper.runUiThreadTasksIncludingDelayedTasks()

        assertEquals("nobody to finish anything: stop at once", 1, stopServiceCalls.size)
    }

    // -------------------------------------------------------------------------
    // release — answered path: skips performEndCall, calls stopServiceWithDelay
    // -------------------------------------------------------------------------

    /**
     * release() is used for answered-call teardown (handleRelease(answered=true)).
     * It must NOT call performEndCall — the main process handles active-call signaling.
     * It goes directly to stopServiceWithDelay().
     */
    @Test
    fun `release does not call performEndCall`() {
        handler.release()

        assertFalse(
            "release() must not call performEndCall",
            communicator.events.contains("performEndCall"),
        )
    }

    @Test
    fun `release calls stopService after delay`() {
        handler.release()
        ShadowLooper.runUiThreadTasksIncludingDelayedTasks()

        assertEquals(
            "release() must call stopService via stopServiceWithDelay",
            1,
            stopServiceCalls.size,
        )
    }

    @Test
    fun `release calls stopService exactly once`() {
        handler.release()
        ShadowLooper.runUiThreadTasksIncludingDelayedTasks()

        assertEquals(1, stopServiceCalls.size)
    }

    // -------------------------------------------------------------------------
    // null flutterApi — graceful degradation (timeout path)
    // -------------------------------------------------------------------------

    @Test
    fun `performEndCall with null flutterApi calls stopService`() {
        handler.flutterApi = null

        handler.performEndCall(CallMetadata(callId = "call-1"))
        ShadowLooper.runUiThreadTasksIncludingDelayedTasks()

        assertEquals(1, stopServiceCalls.size)
    }

    @Test
    fun `release with null flutterApi calls stopService`() {
        handler.flutterApi = null

        handler.release()
        ShadowLooper.runUiThreadTasksIncludingDelayedTasks()

        assertEquals(1, stopServiceCalls.size)
    }

    // -------------------------------------------------------------------------
    // performAnswerCall -- no duplicate answer signal to Telecom
    // -------------------------------------------------------------------------

    /**
     * Regression: performAnswerCall must NOT call connectionController.answer() after
     * Flutter acknowledges the answer. Telecom already confirmed the call is being answered
     * by invoking performAnswerCall; a second answer() call would send a duplicate signal
     * and could trigger a double notification or double-answer state in the connection service.
     */
    @Test
    fun `performAnswerCall does not call connectionController answer on success`() {
        handler.performAnswerCall(CallMetadata(callId = "call-1"))

        assertTrue(
            "performAnswer must be forwarded to Flutter to confirm the background path ran",
            communicator.events.contains("performAnswer"),
        )
        assertEquals(
            "answer() must not be called -- Telecom already confirmed the answer",
            0,
            fakeController.answerCallCount,
        )
    }

    @Test
    fun `performAnswerCall notifies Flutter isolate via performAnswer`() {
        handler.performAnswerCall(CallMetadata(callId = "call-1"))

        assertTrue(
            "performAnswerCall must forward the event to Flutter",
            communicator.events.contains("performAnswer"),
        )
    }

    @Test
    fun `performAnswerCall tears down connection on Flutter answer failure`() {
        val failingCommunicator =
            object : FlutterIsolateCommunicator {
                override fun performAnswer(
                    callId: String,
                    onSuccess: () -> Unit,
                    onFailure: (Throwable) -> Unit,
                ) {
                    onFailure(RuntimeException("answer rejected"))
                }

                override fun performEndCall(
                    callId: String,
                    onSuccess: () -> Unit,
                    onFailure: (Throwable) -> Unit,
                ) {}

                override fun performHandoff(
                    callId: String,
                    onSuccess: () -> Unit,
                    onFailure: (Throwable) -> Unit,
                ) {}

                override fun syncPushIsolate(
                    callData: PCallkeepIncomingCallData?,
                    onSuccess: () -> Unit,
                    onFailure: (Throwable) -> Unit,
                ) {}
            }
        handler.flutterApi = failingCommunicator

        handler.performAnswerCall(CallMetadata(callId = "call-1"))

        assertEquals("tearDown() must be called once on answer failure", 1, fakeController.tearDownCallCount)
    }

    @Test
    fun `performAnswerCall with null flutterApi is a no-op and does not throw`() {
        handler.flutterApi = null

        handler.performAnswerCall(CallMetadata(callId = "call-1"))

        assertEquals(0, fakeController.answerCallCount)
        assertEquals(0, fakeController.tearDownCallCount)
    }

    // -------------------------------------------------------------------------
    // releaseCall / handoffCall - the service stops only for the call it shows
    // -------------------------------------------------------------------------

    @Test
    fun `releaseCall for the shown call ends it and stops the service`() {
        runBlocking { handler.releaseCall("call-1") }

        assertEquals(listOf("call-1"), fakeController.declinedCallIds)
        assertEquals(listOf("stop"), stopServiceCalls)
    }

    @Test
    fun `releaseCall for another call ends that call and keeps the service`() {
        // A second call on the same push session hangs up while call-1 still rings.
        runBlocking { handler.releaseCall("call-2") }

        assertEquals(listOf("call-2"), fakeController.declinedCallIds)
        assertTrue("call-1's service must keep running", stopServiceCalls.isEmpty())
    }

    @Test
    fun `reportEndCall hands the end to the core and keeps the service`() {
        runBlocking { handler.reportEndCall("call-1", PEndCallReason(value = PEndCallReasonEnum.MISSED_WHILE_CONNECTING)) }

        verify(core).reportCallEnded(metadataWithId("call-1"), reason(PEndCallReasonEnum.MISSED_WHILE_CONNECTING))
        assertTrue("the core ends the call; the handler must not decline it a second time", fakeController.declinedCallIds.isEmpty())
        assertTrue("ending the call does not end the session", stopServiceCalls.isEmpty())
    }

    @Test
    fun `handoffCall for the shown call stops the service`() {
        runBlocking { handler.handoffCall("call-1") }

        assertEquals(listOf("stop"), stopServiceCalls)
    }

    @Test
    fun `handoffCall for another call keeps the service`() {
        runBlocking { handler.handoffCall("call-2") }

        assertTrue(stopServiceCalls.isEmpty())
    }

    // Mockito matchers return null; routing them through a type-parameter helper keeps Kotlin from
    // inserting a null check where the value meets the mocked method's non-null parameter.
    @Suppress("UNCHECKED_CAST")
    private fun <T> uninitialized(): T = null as T

    private fun metadataWithId(callId: String): CallMetadata {
        ArgumentMatchers.argThat<CallMetadata> { it.callId == callId }
        return uninitialized()
    }

    private fun reason(value: PEndCallReasonEnum): PEndCallReasonEnum {
        ArgumentMatchers.eq(value)
        return uninitialized()
    }
}
