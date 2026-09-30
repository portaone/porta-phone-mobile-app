package com.webtrit.callkeep

import android.content.Context
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.models.CallConnectionState
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.models.FailureMetadata
import com.webtrit.callkeep.services.broadcaster.CallCommandEvent
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.core.CallkeepCore
import com.webtrit.callkeep.services.services.foreground.ForegroundService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.Dispatchers
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
import org.mockito.Mockito.mock
import org.mockito.Mockito.mockingDetails
import org.mockito.Mockito.verifyNoInteractions
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.android.controller.ServiceController
import org.robolectric.annotation.Config
import java.util.concurrent.TimeUnit

/**
 * How a reportNewIncomingCall made through the foreground service ends.
 *
 * Both Pigeon entry points wait on the same core operation. Events enter through the core,
 * as they do from Telecom or the standalone backend, with the service attached as a listener.
 * The refusal itself is covered by [ForegroundServiceIncomingFailureTest].
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class ForegroundServiceIncomingRegistrationTest {
    private lateinit var controller: ServiceController<ForegroundService>
    private lateinit var service: ForegroundService
    private val core get() = CallkeepCore.instance

    // The suspended host calls run here, not under runBlocking: they only finish once the main
    // looper is driven, and runBlocking would wait for them first.
    private val scope = CoroutineScope(Dispatchers.Unconfined)

    @Before
    fun prepare() {
        ContextHolder.init(ApplicationProvider.getApplicationContext<Context>())
        controller = Robolectric.buildService(ForegroundService::class.java).create()
        service = controller.get()
    }

    @After
    fun tearDown() {
        scope.cancel()
        core.clear()
    }

    private fun report(callId: String): Deferred<PIncomingCallError?> =
        scope
            .async {
                service.reportNewIncomingCall(
                    callId = callId,
                    handle = PHandle(PHandleTypeEnum.NUMBER, "1002"),
                    displayName = null,
                    hasVideo = false,
                )
            }.also { idle() }

    private fun idle() = shadowOf(service.mainLooper).idle()

    // Each event in the shape :callkeep_core sends it: a refusal wraps its call in a FailureMetadata.
    private fun event(
        event: CallLifecycleEvent,
        callId: String,
    ) {
        val data =
            if (event == CallLifecycleEvent.IncomingFailure) {
                FailureMetadata(CallMetadata(callId = callId), "onCreateIncomingConnectionFailed: callId=$callId").toBundle()
            } else {
                CallMetadata(callId = callId).toBundle()
            }
        core.notifyConnectionEvent(event, data)
        idle()
    }

    // The timeout is five seconds; a second is enough for an answer that should be immediate
    // and too short for the timer to be what answered.
    private fun Deferred<PIncomingCallError?>.result(): PIncomingCallError? = runBlocking { withTimeout(1_000) { await() } }

    @Test
    fun `the registration waits for Telecom`() {
        val waiting = report("waits")

        assertFalse("nothing has answered yet", waiting.isCompleted)
        assertTrue(core.isPending("waits"))
    }

    @Test
    fun `Telecom reporting the connection succeeds it and tracks the call as ringing`() {
        val waiting = report("reported")

        event(CallLifecycleEvent.IncomingConnectionReported, "reported")

        assertNull(waiting.result())
        assertEquals(PCallkeepConnectionState.STATE_RINGING, core.getState("reported"))
        assertFalse(core.isPending("reported"))
    }

    @Test
    fun `a confirmed registration stays live after its former timeout without notifying Flutter`() {
        val delegate = mock(PDelegateFlutterApi::class.java)
        service.flutterDelegateApi = delegate
        val waiting = report("confirmed-before-timeout")

        shadowOf(service.mainLooper).idleFor(4, TimeUnit.SECONDS)
        event(CallLifecycleEvent.IncomingConnectionReported, "confirmed-before-timeout")
        assertNull(waiting.result())
        shadowOf(service.mainLooper).idleFor(2, TimeUnit.SECONDS)

        assertEquals(PCallkeepConnectionState.STATE_RINGING, core.getState("confirmed-before-timeout"))
        assertFalse(core.isTerminated("confirmed-before-timeout"))
        verifyNoInteractions(delegate)
    }

    @Test
    fun `a deferred answer confirms registration and notifies Flutter once`() {
        val delegate = mock(PDelegateFlutterApi::class.java)
        service.flutterDelegateApi = delegate
        val waiting = report("answered-before-confirmation")

        event(CallLifecycleEvent.AnswerCall, "answered-before-confirmation")

        assertNull(waiting.result())
        assertEquals(PCallkeepConnectionState.STATE_ACTIVE, core.getState("answered-before-confirmation"))
        shadowOf(service.mainLooper).idleFor(6, TimeUnit.SECONDS)

        val answers = mockingDetails(delegate).invocations.filter { it.method.name == "performAnswerCall" }
        assertEquals("registration completion must not also synthesize an answer", 1, answers.size)
        assertEquals("answered-before-confirmation", answers.single().arguments.first())
        assertFalse(mockingDetails(delegate).invocations.any { it.method.name == "performEndCall" })
        assertFalse(core.isTerminated("answered-before-confirmation"))
    }

    @Test
    fun `an active call replayed without metadata still answers Flutter once`() {
        val callId = "cold-active-replay"
        val delegate = mock(PDelegateFlutterApi::class.java)
        service.flutterDelegateApi = delegate

        core.notifyConnectionEvent(
            CallLifecycleEvent.ConnectionStateChanged,
            CallMetadata(callId = callId, connectionState = CallConnectionState.ACTIVE).toBundle(),
        )
        idle()
        assertEquals(PCallkeepConnectionState.STATE_ACTIVE, core.getState(callId))
        assertNull("cold replay has not restored call metadata yet", core.get(callId))

        event(CallLifecycleEvent.AnswerCall, callId)

        assertTrue(core.isAnswered(callId))
        val answers = mockingDetails(delegate).invocations.filter { it.method.name == "performAnswerCall" }
        assertEquals("a live backend call must still reach a freshly attached delegate", 1, answers.size)
        assertEquals(callId, answers.single().arguments.first())
    }

    @Test
    fun `an active state and answer arriving after registration refusal do not revive it`() {
        val callId = "refused-then-active-answer"
        val delegate = mock(PDelegateFlutterApi::class.java)
        service.flutterDelegateApi = delegate
        val waiting = report(callId)

        event(CallLifecycleEvent.IncomingFailure, callId)
        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, waiting.result()?.value)

        core.notifyConnectionEvent(
            CallLifecycleEvent.ConnectionStateChanged,
            CallMetadata(callId = callId, connectionState = CallConnectionState.ACTIVE).toBundle(),
        )
        event(CallLifecycleEvent.AnswerCall, callId)

        assertFalse(core.isAnswered(callId))
        assertTrue(core.isTerminated(callId))
        verifyNoInteractions(delegate)
    }

    @Test
    fun `an active state and answer after timeout stay rejected without notifying Flutter`() {
        val callId = "timed-out-then-active-answer"
        val delegate = mock(PDelegateFlutterApi::class.java)
        service.flutterDelegateApi = delegate
        val waiting = report(callId)
        shadowOf(service.mainLooper).idleFor(5, TimeUnit.SECONDS)
        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, waiting.result()?.value)

        core.notifyConnectionEvent(
            CallLifecycleEvent.ConnectionStateChanged,
            CallMetadata(callId = callId, connectionState = CallConnectionState.ACTIVE).toBundle(),
        )
        event(CallLifecycleEvent.AnswerCall, callId)

        assertFalse(core.isAnswered(callId))
        assertTrue(core.isTerminated(callId))
        assertEquals(PCallkeepConnectionState.STATE_DISCONNECTED, core.getState(callId))
        assertFalse(core.exists(callId))
        verifyNoInteractions(delegate)
    }

    @Test
    fun `a Telecom confirmation and replay after timeout cannot present the rejected call`() {
        val callId = "timed-out-then-confirmed"
        val delegate = mock(PDelegateFlutterApi::class.java)
        service.flutterDelegateApi = delegate
        val waiting = report(callId)
        shadowOf(service.mainLooper).idleFor(5, TimeUnit.SECONDS)
        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, waiting.result()?.value)

        event(CallLifecycleEvent.IncomingConnectionReported, callId)
        event(CallLifecycleEvent.ReplayIncomingCall, callId)

        assertEquals(PCallkeepConnectionState.STATE_DISCONNECTED, core.getState(callId))
        assertTrue(core.isTerminated(callId))
        assertFalse(core.exists(callId))
        verifyNoInteractions(delegate)
        assertEquals(PIncomingCallErrorEnum.CALL_ID_ALREADY_TERMINATED, report(callId).result()?.value)
    }

    @Test
    fun `no answer from Telecom within five seconds rejects it and ends the call`() {
        val waiting = report("timeout")

        shadowOf(service.mainLooper).idleFor(6, TimeUnit.SECONDS)

        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, waiting.result()?.value)
        assertFalse(core.isPending("timeout"))
        assertTrue(core.isTerminated("timeout"))
    }

    @Test
    fun `a late hangup after registration timeout does not end an unconfirmed call in Flutter`() {
        val delegate = mock(PDelegateFlutterApi::class.java)
        service.flutterDelegateApi = delegate
        val waiting = report("timeout-then-hangup")

        shadowOf(service.mainLooper).idleFor(6, TimeUnit.SECONDS)
        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, waiting.result()?.value)

        event(CallLifecycleEvent.HungUp, "timeout-then-hangup")

        assertFalse(core.isPending("timeout-then-hangup"))
        assertTrue(core.isTerminated("timeout-then-hangup"))
        verifyNoInteractions(delegate)
    }

    @Test
    fun `a late hangup after Telecom refusal does not end an unconfirmed call in Flutter`() {
        val delegate = mock(PDelegateFlutterApi::class.java)
        service.flutterDelegateApi = delegate
        val waiting = report("refusal-then-hangup")

        event(CallLifecycleEvent.IncomingFailure, "refusal-then-hangup")
        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, waiting.result()?.value)

        event(CallLifecycleEvent.HungUp, "refusal-then-hangup")

        assertFalse(core.isPending("refusal-then-hangup"))
        assertTrue(core.isTerminated("refusal-then-hangup"))
        verifyNoInteractions(delegate)
    }

    @Test
    fun `a decline before Telecom answered rejects it and ends the call`() {
        val delegate = mock(PDelegateFlutterApi::class.java)
        service.flutterDelegateApi = delegate
        val waiting = report("declined")

        event(CallLifecycleEvent.DeclineCall, "declined")

        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, waiting.result()?.value)
        assertFalse(core.isPending("declined"))
        assertTrue(core.isTerminated("declined"))
        verifyNoInteractions(delegate)
    }

    @Test
    fun `an endCall from the app before Telecom answered succeeds the registration`() {
        val waiting = report("ended")

        scope.launch { service.endCall("ended") }
        idle()

        assertNull(waiting.result())
    }

    @Test
    fun `a teardown while it waits rejects it and ends the call`() {
        val waiting = report("torn-down")

        scope.launch { service.tearDown() }
        idle()

        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, waiting.result()?.value)
        assertFalse(core.isPending("torn-down"))
        assertTrue(core.isTerminated("torn-down"))
        shadowOf(service.mainLooper).idleFor(4, TimeUnit.SECONDS)
    }

    @Test
    fun `the service going away while it waits rejects it and ends the call`() {
        val waiting = report("destroyed")

        controller.destroy()
        idle()

        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, waiting.result()?.value)
        assertFalse(core.isPending("destroyed"))
        assertTrue(core.isTerminated("destroyed"))
    }

    @Test
    fun `a call that ended before the app knew it is refused as terminated`() {
        core.markEndedWithoutFlutterState("ghost")

        val waiting = report("ghost")

        assertEquals(PIncomingCallErrorEnum.CALL_ID_ALREADY_TERMINATED, waiting.result()?.value)
        assertFalse(core.isPending("ghost"))
    }

    @Test
    fun `a second report of a call that is still registering waits for it and learns it exists`() {
        val first = report("twice")

        val second = report("twice")
        assertFalse("the second report joins instead of guessing an answer", second.isCompleted)

        event(CallLifecycleEvent.IncomingConnectionReported, "twice")

        assertNull(first.result())
        assertEquals(PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS, second.result()?.value)
    }

    // ---------------------------------------------------------------------------------------
    // The push path, registering through the same core while the foreground service is up
    // ---------------------------------------------------------------------------------------

    private val push by lazy { BackgroundPushNotificationIsolateBootstrapApi(ApplicationProvider.getApplicationContext()) }

    private fun pushReport(callId: String): Deferred<PIncomingCallError?> =
        scope
            .async { push.reportNewIncomingCall(callId, PHandle(PHandleTypeEnum.NUMBER, "1003"), null, false) }
            .also { idle() }

    @Test
    fun `a push refused by Telecom is told so and leaves no pending entry`() {
        val pushed = pushReport("push-refused")

        event(CallLifecycleEvent.IncomingFailure, "push-refused")

        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, pushed.result()?.value)
        assertFalse(core.isPending("push-refused"))
    }

    @Test
    fun `the app reporting a call the push is registering learns the refusal too`() {
        val pushed = pushReport("push-then-app")
        val reported = report("push-then-app")

        event(CallLifecycleEvent.IncomingFailure, "push-then-app")

        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, pushed.result()?.value)
        assertEquals(
            "the app must not be left with a call that rings nowhere",
            PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM,
            reported.result()?.value,
        )
    }

    @Test
    fun `the app reporting a call the push already had refused registers it anew`() {
        val pushed = pushReport("refused-then-app")
        event(CallLifecycleEvent.IncomingFailure, "refused-then-app")
        pushed.result()

        val reported = report("refused-then-app")

        assertFalse("the call goes to Telecom again instead of being taken as ringing", reported.isCompleted)
        assertTrue(core.isPending("refused-then-app"))
    }

    @Test
    fun `the service going away leaves a push registration waiting for Telecom`() {
        val pushed = pushReport("push-during-detach")

        controller.destroy()
        idle()
        assertFalse("the push is not answered for the service", pushed.isCompleted)
        assertFalse(core.isTerminated("push-during-detach"))

        core.notifyConnectionEvent(CallLifecycleEvent.IncomingConnectionReported, CallMetadata(callId = "push-during-detach").toBundle())
        idle()

        assertNull("Telecom took the call; the push learns so", pushed.result())
        assertFalse(core.isTerminated("push-during-detach"))
    }

    @Test
    fun `the service going away answers its own report of a call the push also registers`() {
        val pushed = pushReport("shared-detach")
        val reported = report("shared-detach")

        controller.destroy()
        idle()

        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, reported.result()?.value)
        assertFalse("the push keeps waiting for Telecom", pushed.isCompleted)
        assertFalse(core.isTerminated("shared-detach"))

        event(CallLifecycleEvent.IncomingConnectionReported, "shared-detach")

        assertNull(pushed.result())
        assertEquals(PCallkeepConnectionState.STATE_RINGING, core.getState("shared-detach"))
    }

    @Test
    fun `a push joining a foreground registration survives the foreground owner going away`() {
        val reported = report("foreground-owner-detach")
        val pushed = pushReport("foreground-owner-detach")

        controller.destroy()
        idle()

        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, reported.result()?.value)
        assertFalse("the joining push keeps the registration alive", pushed.isCompleted)
        assertTrue(core.isPending("foreground-owner-detach"))

        event(CallLifecycleEvent.IncomingConnectionReported, "foreground-owner-detach")

        assertEquals(PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS, pushed.result()?.value)
        assertEquals(PCallkeepConnectionState.STATE_RINGING, core.getState("foreground-owner-detach"))
    }

    @Test
    fun `a teardown ends a push registration with the rest of the session`() {
        val pushed = pushReport("push-session-end")

        scope.launch { service.tearDown() }
        idle()

        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, pushed.result()?.value)
        shadowOf(service.mainLooper).idleFor(4, TimeUnit.SECONDS)
    }

    @Test
    fun `a teardown rejects both clients of a shared registration without ending it in Flutter`() {
        val delegate = mock(PDelegateFlutterApi::class.java)
        service.flutterDelegateApi = delegate
        val pushed = pushReport("shared-session-end")
        val reported = report("shared-session-end")

        scope.launch { service.tearDown() }
        idle()

        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, pushed.result()?.value)
        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, reported.result()?.value)
        assertFalse(core.isPending("shared-session-end"))
        verifyNoInteractions(delegate)
        shadowOf(service.mainLooper).idleFor(4, TimeUnit.SECONDS)
    }

    @Test
    fun `after a teardown ack the same call registers anew, untouched by the old session's timer`() {
        pushReport("session-retry")
        val tearingDown = scope.async { service.tearDown() }
        core.notifyConnectionEvent(CallCommandEvent.TearDownComplete, null)
        idle()
        assertTrue("the backend acknowledgement finishes the old session", tearingDown.isCompleted)
        shadowOf(service.mainLooper).idleFor(4, TimeUnit.SECONDS)

        val retried = report("session-retry")
        shadowOf(service.mainLooper).idleFor(2, TimeUnit.SECONDS)

        assertFalse("the new registration waits for Telecom, the old timer is gone", retried.isCompleted)
        assertTrue(core.isPending("session-retry"))

        event(CallLifecycleEvent.IncomingConnectionReported, "session-retry")

        assertNull(retried.result())
        assertEquals(PCallkeepConnectionState.STATE_RINGING, core.getState("session-retry"))
    }

    @Test
    fun `a push of a call that ended before the app knew it is refused as terminated`() {
        core.markEndedWithoutFlutterState("push-ghost")

        val pushed = pushReport("push-ghost")

        assertEquals(PIncomingCallErrorEnum.CALL_ID_ALREADY_TERMINATED, pushed.result()?.value)
        assertFalse(core.isPending("push-ghost"))
    }
}
