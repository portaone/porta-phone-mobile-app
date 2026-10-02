package com.webtrit.callkeep

import android.app.Activity
import android.content.Context
import android.os.Build
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.common.ActivityHolder
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.broadcaster.CallLifecycleEvent
import com.webtrit.callkeep.services.core.CallkeepCore
import com.webtrit.callkeep.services.services.foreground.ForegroundService
import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * The app on the lock screen shows every call, so it is sent back only when the call that
 * ended was the last live one - not when a second incoming call Telecom refused ends while
 * the first still rings.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class ForegroundServiceLastCallTest {
    private lateinit var service: ForegroundService
    private val core get() = CallkeepCore.instance

    @Before
    fun prepare() {
        ContextHolder.init(ApplicationProvider.getApplicationContext<Context>())
        core.clear()
        service = Robolectric.buildService(ForegroundService::class.java).create().get()
    }

    @After
    fun tearDown() {
        ActivityHolder.setActivity(null)
        service.onDestroy()
        core.clear()
    }

    private fun ringing(callId: String) = core.promote(callId, CallMetadata(callId = callId), PCallkeepConnectionState.STATE_RINGING)

    @Test
    fun `the only call ending is the last call`() {
        ringing("A")
        core.markTerminated("A")

        assertTrue(service.isLastCall("A"))
    }

    @Test
    fun `a refused call ending while another rings is not the last call`() {
        ringing("A")
        // B was reported and refused by Telecom: pending, then dropped, never registered.
        core.addPending("B")
        core.removePending("B")
        core.markTerminated("B")

        assertFalse("A still rings", service.isLastCall("B"))
    }

    @Test
    fun `the ringing call ending after a refused one is the last call`() {
        core.addPending("B")
        core.removePending("B")
        ringing("A")
        core.markTerminated("A")

        assertTrue(service.isLastCall("A"))
    }

    @Test
    fun `an ended call does not count as live`() {
        ringing("A")
        ringing("B")
        core.markTerminated("B")
        core.markTerminated("A")

        assertTrue(service.isLastCall("A"))
    }

    @Test
    fun `a call still on its way to Telecom keeps the app up`() {
        ringing("A")
        core.markTerminated("A")
        core.addPending("B")

        assertFalse("B was reported and its screen is coming", service.isLastCall("A"))
    }

    @Test
    fun `the last call ending takes the activity back behind the keyguard`() {
        // The call alert let the activity over the keyguard; the call ended before the app
        // built its call screen, so the app never clears the flags itself.
        val activity = overKeyguard()
        ringing("A")

        core.notifyConnectionEvent(CallLifecycleEvent.HungUp, CallMetadata(callId = "A").toBundle())
        shadowOf(Looper.getMainLooper()).idle()

        assertFalse(shadowOf(activity).showWhenLocked)
        assertFalse(shadowOf(activity).turnScreenOn)
    }

    @Test
    fun `a call ending while another rings keeps the activity over the keyguard`() {
        val activity = overKeyguard()
        ringing("A")
        ringing("B")

        core.notifyConnectionEvent(CallLifecycleEvent.HungUp, CallMetadata(callId = "B").toBundle())
        shadowOf(Looper.getMainLooper()).idle()

        assertTrue("A still rings", shadowOf(activity).showWhenLocked)
    }

    private fun overKeyguard(): Activity =
        Robolectric.buildActivity(Activity::class.java).setup().get().also {
            it.setShowWhenLocked(true)
            it.setTurnScreenOn(true)
            ActivityHolder.setActivity(it)
        }
}
