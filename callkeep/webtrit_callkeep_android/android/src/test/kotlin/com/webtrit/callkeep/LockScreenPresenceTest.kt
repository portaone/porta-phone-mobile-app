package com.webtrit.callkeep

import android.app.Activity
import android.app.KeyguardManager
import android.app.Notification
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.notifications.NotificationBuilder
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
import org.robolectric.annotation.Config

/**
 * Only the incoming-call alert may take the Activity over the keyguard on callkeep's side. An
 * Activity opened from the launcher during a call shows the app's ordinary screens, and letting it
 * over the keyguard because "a call exists" put the keypad and the contacts in front of anyone
 * holding the locked phone.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class LockScreenPresenceTest {
    private val app get() = ApplicationProvider.getApplicationContext<Context>()
    private lateinit var activity: Activity

    @Before
    fun setUp() {
        ContextHolder.init(app)
        activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    }

    @After
    fun tearDown() {
        CallkeepCore.instance.clear()
    }

    @Test
    fun `the call alert on a locked phone with a call shows the activity over the keyguard`() {
        locked(true)
        ringing("c1")

        LockScreenPresence.onActivityIntent(activity, alertIntent())

        assertTrue(shadowOf(activity).showWhenLocked)
        assertTrue(shadowOf(activity).turnScreenOn)
    }

    @Test
    fun `an activity opened from the launcher during a call stays behind the keyguard`() {
        locked(true)
        ringing("c1")

        LockScreenPresence.onActivityIntent(activity, Intent(Intent.ACTION_MAIN))

        assertFalse(shadowOf(activity).showWhenLocked)
        assertFalse(shadowOf(activity).turnScreenOn)
    }

    @Test
    fun `the call alert on an unlocked phone leaves the flags to the app`() {
        locked(false)
        ringing("c1")

        LockScreenPresence.onActivityIntent(activity, alertIntent())

        assertFalse(shadowOf(activity).showWhenLocked)
    }

    @Test
    fun `a stale call alert with no call left shows nothing`() {
        locked(true)

        LockScreenPresence.onActivityIntent(activity, alertIntent())

        assertFalse(shadowOf(activity).showWhenLocked)
    }

    @Test
    fun `release takes the activity back behind the keyguard`() {
        locked(true)
        ringing("c1")
        LockScreenPresence.onActivityIntent(activity, alertIntent())

        LockScreenPresence.release(activity)

        assertFalse(shadowOf(activity).showWhenLocked)
        assertFalse(shadowOf(activity).turnScreenOn)
    }

    @Test
    fun `the alert intent is marked even when the content intent was made first`() {
        // Both open the app; a pending intent differing only in extras would be the content
        // intent's, unmarked, if they shared a request code.
        registerLauncherActivity()
        val builder = TestBuilder()
        val content = builder.openApp()
        val alert = builder.callAlert()

        assertFalse(shadowOf(content).savedIntent.hasExtra(LockScreenPresence.EXTRA_OPENED_BY_CALL_ALERT))
        assertTrue(shadowOf(alert).savedIntent.getBooleanExtra(LockScreenPresence.EXTRA_OPENED_BY_CALL_ALERT, false))
    }

    private fun alertIntent() = Intent(Intent.ACTION_MAIN).putExtra(LockScreenPresence.EXTRA_OPENED_BY_CALL_ALERT, true)

    private fun registerLauncherActivity() {
        val launcher = ComponentName(app.packageName, "com.example.MainActivity")
        shadowOf(app.packageManager).apply {
            addActivityIfNotPresent(launcher)
            addIntentFilterForActivity(
                launcher,
                IntentFilter(Intent.ACTION_MAIN).apply { addCategory(Intent.CATEGORY_LAUNCHER) },
            )
        }
    }

    private fun locked(value: Boolean) {
        shadowOf(app.getSystemService(KeyguardManager::class.java)).setKeyguardLocked(value)
    }

    private fun ringing(callId: String) {
        CallkeepCore.instance.promote(callId, CallMetadata(callId = callId), PCallkeepConnectionState.STATE_RINGING)
    }

    private inner class TestBuilder : NotificationBuilder() {
        fun openApp() = buildOpenAppIntent(app)

        fun callAlert() = buildCallAlertIntent(app)

        override fun build(): Notification = throw UnsupportedOperationException()
    }
}
