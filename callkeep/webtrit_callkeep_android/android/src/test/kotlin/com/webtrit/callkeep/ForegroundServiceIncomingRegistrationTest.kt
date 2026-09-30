package com.webtrit.callkeep

import android.content.Context
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.models.CallMetadata
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
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.android.controller.ServiceController
import org.robolectric.annotation.Config
import java.util.concurrent.TimeUnit

/**
 * How a reportNewIncomingCall made through the foreground service ends.
 *
 * The call is registered with Telecom and the host call stays suspended until something says
 * how the registration went. These tests pin down each of those endings as the service
 * behaves today, so the registration can be moved out of the service with proof that none of
 * them changed. The refusal itself is covered by [ForegroundServiceIncomingFailureTest].
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

    private fun event(
        event: CallLifecycleEvent,
        callId: String,
    ) {
        service.onConnectionEvent(event, CallMetadata(callId = callId).toBundle())
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
    fun `no answer from Telecom within five seconds rejects it and ends the call`() {
        val waiting = report("timeout")

        shadowOf(service.mainLooper).idleFor(6, TimeUnit.SECONDS)

        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, waiting.result()?.value)
        assertFalse(core.isPending("timeout"))
        assertTrue(core.isTerminated("timeout"))
    }

    @Test
    fun `a decline before Telecom answered rejects it and ends the call`() {
        val waiting = report("declined")

        event(CallLifecycleEvent.DeclineCall, "declined")

        assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, waiting.result()?.value)
        assertFalse(core.isPending("declined"))
        assertTrue(core.isTerminated("declined"))
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
    fun `a second report of a call that is still registering is told it exists, the first keeps waiting`() {
        val first = report("twice")

        val second = report("twice")

        assertEquals(PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS, second.result()?.value)
        assertFalse("the first registration is not answered by the second", first.isCompleted)

        event(CallLifecycleEvent.IncomingConnectionReported, "twice")
        assertNull(first.result())
    }
}
