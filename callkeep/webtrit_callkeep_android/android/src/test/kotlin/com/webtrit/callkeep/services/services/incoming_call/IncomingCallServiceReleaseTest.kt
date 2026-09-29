package com.webtrit.callkeep.services.services.incoming_call

import android.content.Context
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.common.PendingBroadcastQueue
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.models.toPCallkeepIncomingCallData
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.core.CallkeepCore
import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.android.controller.ServiceController
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLooper
import java.util.concurrent.TimeUnit

/**
 * The incoming-call service shows one call, and the release it receives is broadcast on the end
 * of any call. It must act only on a release naming the call it shows: acting on another one
 * tore the ringing call's notification and service down while that call was still ringing
 * (a second incoming call refused by Telecom, WT-2029).
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class IncomingCallServiceReleaseTest {
    private lateinit var context: Context
    private lateinit var controller: ServiceController<IncomingCallService>
    private lateinit var service: IncomingCallService

    @Before
    fun prepare() {
        context = ApplicationProvider.getApplicationContext()
        ContextHolder.init(context)
        shadowOf(ApplicationProvider.getApplicationContext<android.app.Application>())
            .grantPermissions("${context.packageName}.INTERNAL_BROADCAST")
        PendingBroadcastQueue.clear()
        CallkeepCore.instance.clear()
        controller = Robolectric.buildService(IncomingCallService::class.java).create()
        service = controller.get()
    }

    @After
    fun tearDown() {
        controller.destroy()
        PendingBroadcastQueue.clear()
        CallkeepCore.instance.clear()
    }

    private fun show(callId: String) {
        service.getCallLifecycleHandler().currentCallData =
            CallMetadata(callId = callId, displayName = callId).toPCallkeepIncomingCallData()
    }

    private fun release(
        callId: String,
        reason: IncomingCallRelease,
    ) {
        IncomingCallService.release(context, callId, reason)
        ShadowLooper.idleMainLooper(5, TimeUnit.SECONDS)
    }

    private fun stopped() = shadowOf(service).isStoppedBySelf

    @Test
    fun `release for another call leaves the shown call alone`() {
        show("A")

        release("B", IncomingCallRelease.IC_RELEASE_HANDED_OVER)
        release("B", IncomingCallRelease.IC_RELEASE_ENDED)

        assertFalse("the service showing A keeps running", stopped())
        assertFalse(
            "a release for B is not parked while A is shown",
            PendingBroadcastQueue.consume(PendingBroadcastQueue.incomingReleaseKey("B")),
        )
    }

    @Test
    fun `release handed over for the shown call stops the service`() {
        show("A")

        release("A", IncomingCallRelease.IC_RELEASE_HANDED_OVER)

        assertTrue(stopped())
    }

    @Test
    fun `release ended for the shown call stops the service`() {
        show("A")

        // No push isolate here: performEndCall falls back to releasing directly.
        release("A", IncomingCallRelease.IC_RELEASE_ENDED)

        assertTrue(stopped())
    }

    @Test
    fun `release before any call is shown is parked for that call`() {
        release("B", IncomingCallRelease.IC_RELEASE_ENDED)

        assertFalse(stopped())
        assertTrue(
            "handleLaunch finds it when B's IC_INITIALIZE arrives",
            PendingBroadcastQueue.consume(PendingBroadcastQueue.incomingReleaseKey("B")),
        )
    }

    @Test
    fun `answer of another call does not answer the shown one`() {
        show("A")

        service.onConnectionEvent(CallLifecycleEvent.AnswerCall, CallMetadata(callId = "B").toBundle())

        assertFalse("B's answer is not taken as A's", CallkeepCore.instance.isAnswered("B"))
        assertFalse(CallkeepCore.instance.isAnswered("A"))
    }

    @Test
    fun `answer of the shown call is acted on`() {
        show("A")

        service.onConnectionEvent(CallLifecycleEvent.AnswerCall, CallMetadata(callId = "A").toBundle())

        // No push isolate here: the answer is recorded directly.
        assertTrue(CallkeepCore.instance.isAnswered("A"))
    }
}
