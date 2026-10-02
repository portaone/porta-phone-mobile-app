package com.webtrit.callkeep

import android.content.Context
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.models.CallHandle
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.core.CallkeepCore
import com.webtrit.callkeep.services.services.foreground.ForegroundService
import com.webtrit.callkeep.services.services.incoming_call.IncomingCallRelease
import com.webtrit.callkeep.services.services.incoming_call.IncomingCallService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
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
 * A call given to the app by the incoming-call service is presented to the delegate and
 * nothing more. The ringing notification is the call UI while the app is in the background, so
 * the presentation must not confirm a handoff: that release silences and stops the service. A
 * replay to a freshly attached delegate (a push session handing over) still confirms it.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class ForegroundServiceLiveAppCallTest {
    private lateinit var controller: ServiceController<ForegroundService>
    private lateinit var service: ForegroundService
    private val delegate = mock(PDelegateFlutterApi::class.java)
    private val app get() = ApplicationProvider.getApplicationContext<Context>()

    @Before
    fun prepare() {
        ContextHolder.init(app)
        controller = Robolectric.buildService(ForegroundService::class.java).create()
        service = controller.get()
        service.flutterDelegateApi = delegate
        // An incoming-call service is up and showing the call.
        incomingCallServiceRunning(true)
    }

    @After
    fun tearDown() {
        incomingCallServiceRunning(false)
        ForegroundService.isDelegateReady = false
        scope.cancel()
        CallkeepCore.instance.clear()
    }

    @Test
    fun `a call handed to a live app is presented without a handoff release`() {
        replay("bg-call", presentOnly = true)

        assertEquals(1, presentations())
        assertFalse("the ringing service must keep ringing", handoffReleaseSent())
    }

    @Test
    fun `a replay to a freshly attached delegate still confirms the handoff`() {
        replay("handed-over", presentOnly = false)

        assertEquals(1, presentations())
        assertTrue(handoffReleaseSent())
    }

    @Test
    fun `the delegate is ready from onDelegateSet until onDelegateCleared or the service goes`() {
        assertFalse(ForegroundService.isDelegateReady)

        service.onDelegateSet()
        assertTrue(ForegroundService.isDelegateReady)

        service.onDelegateCleared()
        assertFalse(ForegroundService.isDelegateReady)

        service.onDelegateSet()
        controller.destroy()
        assertFalse(ForegroundService.isDelegateReady)
    }

    @Test
    fun `a call the app reports through its bridge is the app's`() {
        scope.launch { service.reportNewIncomingCall("app-call", PHandle(PHandleTypeEnum.NUMBER, "1002"), null, false) }
        shadowOf(service.mainLooper).idle()

        assertTrue(CallkeepCore.instance.isReportedByApp("app-call"))
    }

    private val scope = CoroutineScope(Dispatchers.Unconfined)

    private fun replay(
        callId: String,
        presentOnly: Boolean,
    ) {
        val extras =
            CallMetadata(callId = callId, handle = CallHandle("1002")).toBundle().apply {
                if (presentOnly) putBoolean(ForegroundService.PRESENT_ONLY, true)
            }
        CallkeepCore.instance.notifyConnectionEvent(CallLifecycleEvent.ReplayIncomingCall, extras)
        shadowOf(service.mainLooper).idle()
    }

    private fun presentations() = mockingDetails(delegate).invocations.count { it.method.name == "didPresentIncomingCall" }

    private fun handoffReleaseSent() = shadowOf(service.application).broadcastIntents.any { it.action == IncomingCallRelease.IC_RELEASE_HANDED_OVER.name }

    private fun incomingCallServiceRunning(running: Boolean) {
        IncomingCallService::class.java.getDeclaredField("isRunning").apply {
            isAccessible = true
            setBoolean(null, running)
        }
    }
}
