package com.webtrit.callkeep.services.services.incoming_call

import android.content.Context
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.PEndCallReasonEnum
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.common.PendingBroadcastQueue
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.models.toPCallkeepIncomingCallData
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.core.CallkeepCore
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
import org.robolectric.shadows.ShadowLooper
import java.util.concurrent.TimeUnit

/**
 * The incoming-call service shows one call, and the release it receives is broadcast on the end
 * of any call. It must act only on a release naming the call it shows: acting on another one
 * tore the ringing call's notification and service down while that call was still ringing
 * (a second incoming call refused by Telecom).
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

    /** The push session's side of the bridge: records whether it was asked to end a call. */
    private class RecordingCommunicator : FlutterIsolateCommunicator {
        val endCallIds = mutableListOf<String>()

        override fun performAnswer(
            callId: String,
            onSuccess: () -> Unit,
            onFailure: (Throwable) -> Unit,
        ) = onSuccess()

        override fun performEndCall(
            callId: String,
            onSuccess: () -> Unit,
            onFailure: (Throwable) -> Unit,
        ) {
            endCallIds += callId
            onSuccess()
        }

        override fun syncPushIsolate(
            callData: com.webtrit.callkeep.PCallkeepIncomingCallData?,
            onSuccess: () -> Unit,
            onFailure: (Throwable) -> Unit,
        ) = onSuccess()
    }

    @Test
    fun `the session finishing for the shown call releases the service`() {
        show("A")

        service.onSessionFinished("A")
        ShadowLooper.idleMainLooper(5, TimeUnit.SECONDS)

        assertTrue(stopped())
    }

    @Test
    fun `the session finishing for another call leaves the shown call alone`() {
        show("A")

        service.onSessionFinished("B")
        ShadowLooper.idleMainLooper(5, TimeUnit.SECONDS)

        assertFalse("A still rings; an earlier session's return must not end it", stopped())
    }

    @Test
    fun `the session finishing after it released the call changes nothing`() {
        show("A")
        release("A", IncomingCallRelease.IC_RELEASE_ENDED)

        service.onSessionFinished("A")
        ShadowLooper.idleMainLooper(5, TimeUnit.SECONDS)

        assertTrue(stopped())
    }

    @Test
    fun `an end the app reported is not sent to the session as performEndCall`() {
        show("A")
        val session = RecordingCommunicator().also { service.getCallLifecycleHandler().flutterApi = it }
        CallkeepCore.instance.reportCallEnded(CallMetadata(callId = "A"), PEndCallReasonEnum.MISSED_WHILE_CONNECTING)

        release("A", IncomingCallRelease.IC_RELEASE_ENDED)

        assertTrue("the app reported this end; the session must not decline the call on the server again", session.endCallIds.isEmpty())
        assertTrue(stopped())
    }

    @Test
    fun `an end nobody reported is sent to the session once as performEndCall`() {
        show("A")
        val session = RecordingCommunicator().also { service.getCallLifecycleHandler().flutterApi = it }

        release("A", IncomingCallRelease.IC_RELEASE_ENDED)

        assertEquals(listOf("A"), session.endCallIds)
        assertTrue(stopped())
    }

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
    fun `release before any call is shown is kept for that call with its reason`() {
        release("B", IncomingCallRelease.IC_RELEASE_HANDED_OVER)

        assertFalse(stopped())
        assertEquals(
            "an answer handed over before IC_INITIALIZE must not come back as an end",
            IncomingCallRelease.IC_RELEASE_HANDED_OVER,
            service.takeEarlyRelease("B"),
        )
    }

    @Test
    fun `early releases for other calls do not outlive the service`() {
        release("C", IncomingCallRelease.IC_RELEASE_ENDED)
        release("B", IncomingCallRelease.IC_RELEASE_ENDED)

        assertEquals(IncomingCallRelease.IC_RELEASE_ENDED, service.takeEarlyRelease("B"))
        assertNull("C was never shown here; its release is dropped", service.takeEarlyRelease("C"))
        assertFalse(
            "nothing is left in the process-wide queue",
            PendingBroadcastQueue.consume(PendingBroadcastQueue.incomingReleaseKey("C")),
        )
    }

    @Test
    fun `an end posted before the service ran is an end`() {
        PendingBroadcastQueue.post(PendingBroadcastQueue.incomingReleaseKey("B"))

        assertEquals(IncomingCallRelease.IC_RELEASE_ENDED, service.takeEarlyRelease("B"))
    }

    @Test
    fun `answer before any call is shown is acted on`() {
        service.onConnectionEvent(CallLifecycleEvent.AnswerCall, CallMetadata(callId = "B").toBundle())

        assertTrue(CallkeepCore.instance.isAnswered("B"))
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
