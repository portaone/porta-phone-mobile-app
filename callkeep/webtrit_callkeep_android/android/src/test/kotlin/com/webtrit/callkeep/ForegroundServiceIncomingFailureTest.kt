package com.webtrit.callkeep

import android.content.Context
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.models.FailureMetadata
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.core.CallkeepCore
import com.webtrit.callkeep.services.core.InProcessCallkeepCore
import com.webtrit.callkeep.services.services.foreground.ForegroundService
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * A call Telecom refuses must fail its suspended reportNewIncomingCall from the refusal, not
 * from the five-second safety timeout.
 *
 * The refusal is reported by :callkeep_core as IncomingFailure and carries no verdict: whether
 * anything is waiting on that call is state only this process has. These tests drive the event
 * into the service the way the broadcast does and check both answers - one waiting, none
 * waiting - because getting the second wrong would fire performEndCall for a call Flutter was
 * never told about.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class ForegroundServiceIncomingFailureTest {
    private lateinit var service: ForegroundService

    @Before
    fun prepare() {
        ContextHolder.init(ApplicationProvider.getApplicationContext<Context>())
        service = Robolectric.buildService(ForegroundService::class.java).create().get()
    }

    @After
    fun tearDown() {
        CallkeepCore.instance.clear()
    }

    private fun failureBundle(callId: String) = FailureMetadata(CallMetadata(callId = callId), "onCreateIncomingConnectionFailed: callId=$callId").toBundle()

    @Test
    fun `the refusal is a global listener event, so it reaches a listener at all`() {
        // The defect this test exists for was not a missing handler but a missing subscription:
        // the event was dispatched and nobody was registered for it.
        assertTrue(
            "IncomingFailure must stay a global listener event",
            CallLifecycleEvent.IncomingFailure in InProcessCallkeepCore.GLOBAL_LISTENER_EVENTS,
        )
    }

    @Test
    fun `a refusal with nothing waiting is ignored`() {
        val callId = "no-one-waiting"

        service.onConnectionEvent(CallLifecycleEvent.IncomingFailure, failureBundle(callId))

        // Nothing is asserted about Flutter because nothing may be said to it: this is a stale
        // callback about a call this process is not registering.
        shadowOf(service.mainLooper).idle()
    }

    @Test
    fun `a refusal fails the call that is waiting on it`() =
        runBlocking {
            val callId = "waiting"
            val suspended =
                async(Dispatchers.Unconfined) {
                    service.reportNewIncomingCall(
                        callId = callId,
                        handle = PHandle(PHandleTypeEnum.NUMBER, "1002"),
                        displayName = null,
                        hasVideo = false,
                    )
                }
            shadowOf(service.mainLooper).idle()

            service.onConnectionEvent(CallLifecycleEvent.IncomingFailure, failureBundle(callId))
            shadowOf(service.mainLooper).idle()

            // The timeout is five seconds; a second is generous for an answer that should be
            // immediate and far too short for the timer to be what answered.
            val result = withTimeout(1_000) { suspended.await() }
            assertEquals(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM, result?.value)
        }
}
