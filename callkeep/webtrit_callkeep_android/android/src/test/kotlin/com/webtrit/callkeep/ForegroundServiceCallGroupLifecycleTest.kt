package com.webtrit.callkeep

import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.common.CallDataConst
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.core.CallkeepCore
import com.webtrit.callkeep.services.services.connection.StandaloneCallService
import com.webtrit.callkeep.services.services.connection.StandaloneServiceAction
import com.webtrit.callkeep.services.services.foreground.ForegroundService
import com.webtrit.callkeep.services.services.incoming_call.IncomingCallService
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * The group state lives with the calls in the core: a member that ends leaves its group
 * whichever way it ended, so the partner left behind is not refused a hold, and the state
 * outlives the activity's bridge service as the calls do.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class ForegroundServiceCallGroupLifecycleTest {
    private lateinit var service: ForegroundService

    @Before
    fun prepare() {
        ContextHolder.init(ApplicationProvider.getApplicationContext<Context>())
        service = Robolectric.buildService(ForegroundService::class.java).create().get()
        for (id in listOf("A", "B")) {
            CallkeepCore.instance.promote(id, CallMetadata(callId = id), PCallkeepConnectionState.STATE_ACTIVE)
            CallkeepCore.instance.markAnswered(id)
        }
    }

    @After
    fun clean() {
        service.onDestroy()
        CallkeepCore.instance.clear()
    }

    @Test
    fun `a member ended by the system leaves the group`() =
        runBlocking {
            assertNull(service.setCallGroup("room", listOf("A", "B")))
            assertEquals(PCallRequestErrorEnum.CALL_IS_GROUPED, service.setHeld("B", true)?.value)
            service.onConnectionEvent(CallLifecycleEvent.HungUp, CallMetadata(callId = "A").toBundle())
            assertTrue("the handler marks A terminated", CallkeepCore.instance.isTerminated("A"))
            assertNull("A ended through the system; B is alone and may be held", service.setHeld("B", true))
        }

    @Test
    fun `a member ended by the application leaves the group`() =
        runBlocking {
            assertNull(service.setCallGroup("room", listOf("A", "B")))
            service.reportEndCall("A", "Alice", PEndCallReason(PEndCallReasonEnum.REMOTE_ENDED))
            assertNull(service.setHeld("B", true))
        }

    @Test
    fun `a second group is refused while one is live`() =
        runBlocking {
            assertNull(service.setCallGroup("room", listOf("A", "B")))
            assertEquals(
                PCallRequestErrorEnum.MAXIMUM_CALL_GROUPS_REACHED,
                service.setCallGroup("other", listOf("A", "B"))?.value,
            )
            assertNull("the same name restates the live group", service.setCallGroup("room", listOf("A", "B")))
            service.reportEndCall("A", "Alice", PEndCallReason(PEndCallReasonEnum.REMOTE_ENDED))
            assertNull("the group fell apart, so its name is free", service.setCallGroup("other", listOf("B", "B")))
        }

    @Test
    fun `a member that ends while the bridge is away leaves the group`() =
        runBlocking {
            // The activity detached; the standalone backend keeps running and A ends there.
            // Nobody is listening, so the core itself has to take A out of its group, or the
            // next bridge would refuse to hold B for a group that no longer exists.
            StandaloneCallService.callMetadataMap.clear()
            StandaloneCallService.callGroupIds.clear()
            StandaloneCallService.answeredCallIds.clear()
            StandaloneCallService.ringingIncomingCallIds.clear()
            StandaloneCallService.pendingAnswers.clear()
            val backend = Robolectric.buildService(StandaloneCallService::class.java).create().get()
            for (id in listOf("A", "B")) {
                StandaloneCallService.callMetadataMap[id] = CallMetadata(callId = id, displayName = id)
                StandaloneCallService.answeredCallIds.add(id)
            }
            assertNull(service.setCallGroup("room", listOf("A", "B")))
            backend.onStartCommand(
                Intent(backend, StandaloneCallService::class.java).apply {
                    action = StandaloneServiceAction.SetCallGroup.action
                    putExtra(CallDataConst.CALL_IDS, arrayOf("A", "B"))
                },
                0,
                1,
            )
            service.onDestroy()
            backend.onStartCommand(
                Intent(backend, StandaloneCallService::class.java).apply {
                    action = StandaloneServiceAction.HungUpCall.action
                    putExtras(CallMetadata(callId = "A", displayName = "A").toBundle())
                },
                0,
                2,
            )
            assertTrue("A ended in the backend", CallkeepCore.instance.isTerminated("A"))
            service = Robolectric.buildService(ForegroundService::class.java).create().get()
            assertNull("A is gone; B is alone and may be held", service.setHeld("B", true))
            backend.onDestroy()
        }

    @Test
    fun `a member that ends while only the incoming-call service listens leaves the group`() =
        runBlocking {
            // The activity detached but a call is ringing, so the incoming-call service is
            // still a listener of the core. It handles AnswerCall and nothing else: its presence
            // must not switch off the core's own handling of A's end, or the next bridge would
            // refuse to hold B for a group that no longer exists.
            val incoming = Robolectric.buildService(IncomingCallService::class.java).create().get()
            StandaloneCallService.callMetadataMap.clear()
            StandaloneCallService.callGroupIds.clear()
            StandaloneCallService.answeredCallIds.clear()
            StandaloneCallService.ringingIncomingCallIds.clear()
            StandaloneCallService.pendingAnswers.clear()
            val backend = Robolectric.buildService(StandaloneCallService::class.java).create().get()
            for (id in listOf("A", "B")) {
                StandaloneCallService.callMetadataMap[id] = CallMetadata(callId = id, displayName = id)
                StandaloneCallService.answeredCallIds.add(id)
            }
            assertNull(service.setCallGroup("room", listOf("A", "B")))
            service.onDestroy()
            backend.onStartCommand(
                Intent(backend, StandaloneCallService::class.java).apply {
                    action = StandaloneServiceAction.HungUpCall.action
                    putExtras(CallMetadata(callId = "A", displayName = "A").toBundle())
                },
                0,
                1,
            )
            assertTrue("A ended in the backend", CallkeepCore.instance.isTerminated("A"))
            service = Robolectric.buildService(ForegroundService::class.java).create().get()
            assertNull("A is gone; B is alone and may be held", service.setHeld("B", true))
            backend.onDestroy()
            incoming.onDestroy()
        }

    @Test
    fun `the registry outlives the bridge service while the calls do`() =
        runBlocking {
            // The activity detaching destroys this service; the calls and their group live on
            // in the backend, and the next service must still refuse to hold a member and
            // must still know the group's name.
            assertNull(service.setCallGroup("room", listOf("A", "B")))
            service.onDestroy()
            assertEquals(listOf("A", "B"), CallkeepCore.instance.groupMembersWith("A"))
            service = Robolectric.buildService(ForegroundService::class.java).create().get()
            assertEquals(PCallRequestErrorEnum.CALL_IS_GROUPED, service.setHeld("B", true)?.value)
            assertEquals(
                PCallRequestErrorEnum.MAXIMUM_CALL_GROUPS_REACHED,
                service.setCallGroup("other", listOf("A", "B"))?.value,
            )
        }
}
