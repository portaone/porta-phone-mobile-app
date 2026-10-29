package com.webtrit.callkeep

import android.content.Context
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.models.CallEndedBy
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.core.CallkeepCore
import com.webtrit.callkeep.services.services.foreground.ForegroundService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.mock
import org.mockito.Mockito.mockingDetails
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.android.controller.ServiceController
import org.robolectric.annotation.Config

/**
 * Who ended a call reaches the app's performEndCall: the initiator an endCall names travels to
 * the backend with the request, and the end event the backend sends back carries it.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class ForegroundServiceEndedByTest {
    private lateinit var controller: ServiceController<ForegroundService>
    private lateinit var service: ForegroundService
    private val delegate = mock(PDelegateFlutterApi::class.java)
    private val app get() = ApplicationProvider.getApplicationContext<Context>()
    private val core get() = CallkeepCore.instance
    private val scope = CoroutineScope(Dispatchers.Unconfined)

    @Before
    fun prepare() {
        ContextHolder.init(app)
        controller = Robolectric.buildService(ForegroundService::class.java).create()
        service = controller.get()
        service.flutterDelegateApi = delegate
    }

    @After
    fun tearDown() {
        scope.cancel()
        core.clear()
    }

    private fun idle() = shadowOf(service.mainLooper).idle()

    private fun ringing(callId: String) {
        scope.launch { service.reportNewIncomingCall(callId, PHandle(PHandleTypeEnum.NUMBER, "1002"), null, false, null) }
        idle()
        core.notifyConnectionEvent(CallLifecycleEvent.IncomingConnectionReported, CallMetadata(callId = callId).toBundle())
        idle()
    }

    /** The initiator of the end request the service sent to the backend for [callId]. */
    private fun requestedEndedBy(callId: String): CallEndedBy? {
        val shadow = shadowOf(ApplicationProvider.getApplicationContext<android.app.Application>())
        val requests = generateSequence { shadow.nextStartedService }.toList()
        return requests
            .mapNotNull { intent -> intent.extras?.let { CallMetadata.fromBundleOrNull(it) } }
            .last { it.callId == callId }
            .endedBy
    }

    private fun performEndCalls(): List<Pair<Any?, Any?>> =
        mockingDetails(delegate)
            .invocations
            .filter { it.method.name == "performEndCall" }
            .map { it.arguments[0] to it.arguments[1] }

    @Test
    fun `an endCall on the user's behalf asks the backend for the user's end`() {
        ringing("c")

        scope.launch { service.endCall("c", PEndedByEnum.USER) }
        idle()

        assertEquals(CallEndedBy.USER, requestedEndedBy("c"))
    }

    @Test
    fun `an endCall of the app's own asks the backend for the app's end`() {
        ringing("c")

        scope.launch { service.endCall("c", PEndedByEnum.APP) }
        idle()

        assertEquals(CallEndedBy.APP, requestedEndedBy("c"))
    }

    @Test
    fun `the end event's initiator reaches performEndCall`() {
        ringing("c")

        core.notifyConnectionEvent(CallLifecycleEvent.HungUp, CallMetadata(callId = "c", endedBy = CallEndedBy.USER).toBundle())
        idle()

        assertEquals(listOf("c" to PEndedByEnum.USER), performEndCalls())
    }

    @Test
    fun `an end event that names nobody reaches performEndCall as the system's`() {
        ringing("c")

        core.notifyConnectionEvent(CallLifecycleEvent.HungUp, CallMetadata(callId = "c").toBundle())
        idle()

        assertEquals(listOf("c" to PEndedByEnum.SYSTEM), performEndCalls())
    }

    @Test
    fun `an endCall for a call Telecom already ended answers with the request's initiator`() {
        // The app falls back to the initiator it asked with on UNKNOWN_CALL_UUID; the one end the
        // platform sends for the call must not name another.
        ringing("c")
        core.markTerminated("c")

        scope.launch { service.endCall("c", PEndedByEnum.USER) }
        idle()

        assertEquals(listOf("c" to PEndedByEnum.USER), performEndCalls())
    }

    @Test
    fun `a teardown ends every call as the app's`() {
        ringing("c")

        scope.launch { service.tearDown() }
        idle()

        assertEquals(listOf("c" to PEndedByEnum.APP), performEndCalls())
    }
}
