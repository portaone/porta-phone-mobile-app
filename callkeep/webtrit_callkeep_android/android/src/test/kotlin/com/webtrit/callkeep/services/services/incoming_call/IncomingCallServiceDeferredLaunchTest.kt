package com.webtrit.callkeep.services.services.incoming_call

import android.app.Application
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.PCallkeepConnectionState
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.common.PendingBroadcastQueue
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.core.CallkeepCore
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.android.controller.ServiceController
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLooper

/**
 * The service shows one call at a time. The core puts a waiting call through as soon as the
 * ringing one is over, while this service still finishes the first call; that call must be
 * shown by the next instance, not dropped.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class IncomingCallServiceDeferredLaunchTest {
    private lateinit var context: Context
    private lateinit var controller: ServiceController<IncomingCallService>

    @Before
    fun prepare() {
        context = ApplicationProvider.getApplicationContext()
        ContextHolder.init(context)
        shadowOf(ApplicationProvider.getApplicationContext<Application>())
            .grantPermissions("${context.packageName}.INTERNAL_BROADCAST")
        PendingBroadcastQueue.clear()
        CallkeepCore.instance.clear()
        controller = Robolectric.buildService(IncomingCallService::class.java).create()
    }

    @After
    fun tearDown() {
        PendingBroadcastQueue.clear()
        CallkeepCore.instance.clear()
    }

    private fun launch(callId: String) {
        controller.withIntent(launchIntent(callId)).startCommand(0, 0)
        ShadowLooper.idleMainLooper()
    }

    private fun launchIntent(callId: String) =
        Intent(context, IncomingCallService::class.java).apply {
            action = PushNotificationServiceEnums.IC_INITIALIZE.name
            CallMetadata(callId = callId, displayName = callId).toBundle().let(::putExtras)
        }

    private fun nextStart(): Intent? = shadowOf(ApplicationProvider.getApplicationContext<Application>()).nextStartedService

    private fun drainStarts() {
        while (nextStart() != null) Unit
    }

    @Test
    fun `a call launched while another is shown is launched again once the service stops`() {
        launch("A")
        CallkeepCore.instance.promote("B", CallMetadata(callId = "B"), PCallkeepConnectionState.STATE_RINGING)
        launch("B")
        drainStarts()

        controller.destroy()
        ShadowLooper.idleMainLooper()

        val next = nextStart()
        assertEquals(PushNotificationServiceEnums.IC_INITIALIZE.name, next?.action)
        assertEquals("B", next?.extras?.let(CallMetadata::fromBundle)?.callId)
    }

    @Test
    fun `a deferred call that ended meanwhile is not launched`() {
        launch("A")
        launch("B")
        drainStarts()

        controller.destroy()
        ShadowLooper.idleMainLooper()

        assertNull(nextStart())
    }

    @Test
    fun `a deferred call answered meanwhile is not launched`() {
        launch("A")
        CallkeepCore.instance.promote("B", CallMetadata(callId = "B"), PCallkeepConnectionState.STATE_ACTIVE)
        launch("B")
        drainStarts()

        controller.destroy()
        ShadowLooper.idleMainLooper()

        assertNull("an answered call has nothing to ring for", nextStart())
    }

    @Test
    fun `a repeated launch of the shown call is not launched again`() {
        launch("A")
        CallkeepCore.instance.promote("A", CallMetadata(callId = "A"), PCallkeepConnectionState.STATE_RINGING)
        launch("A")
        drainStarts()

        controller.destroy()
        ShadowLooper.idleMainLooper()

        assertNull(nextStart())
    }
}
