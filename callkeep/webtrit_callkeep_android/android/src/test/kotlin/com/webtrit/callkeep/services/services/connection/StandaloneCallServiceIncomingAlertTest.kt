package com.webtrit.callkeep.services.services.connection

import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.managers.NotificationChannelManager.FOREGROUND_CALL_NOTIFICATION_CHANNEL_ID
import com.webtrit.callkeep.managers.NotificationChannelManager.INCOMING_CALL_NOTIFICATION_CHANNEL_ID
import com.webtrit.callkeep.models.CallGroup
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.core.CallkeepCore
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * The incoming call notification has to reach the system as a new notification.
 *
 * The system sends a full-screen intent only for a notification it has not shown yet. Posted
 * under the id of the placeholder the service starts its foreground state with, the incoming
 * call notification is an update of that placeholder: the call alert never opens the app, and on
 * a sleeping device the call rings behind a dark screen.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class StandaloneCallServiceIncomingAlertTest {
    private val app get() = ApplicationProvider.getApplicationContext<Context>()
    private lateinit var service: StandaloneCallService
    private val caller = CallMetadata(callId = "incoming", displayName = "Caller")

    @Before
    fun setUp() {
        ContextHolder.init(app)
        clearStandalone()
        registerLauncherActivity()
        service = Robolectric.buildService(StandaloneCallService::class.java).create().get()
    }

    @After
    fun tearDown() {
        clearStandalone()
        CallkeepCore.instance.clear()
    }

    @Test
    fun `the incoming call notification is posted beside the placeholder, not over it`() {
        incomingCall()

        val posted = shadowOf(app.getSystemService(NotificationManager::class.java)).activeNotifications
        val placeholder = posted.single { it.notification.channelId == FOREGROUND_CALL_NOTIFICATION_CHANNEL_ID }
        val incoming = posted.single { it.notification.channelId == INCOMING_CALL_NOTIFICATION_CHANNEL_ID }
        assertNotEquals(placeholder.id, incoming.id)
        assertEquals(incoming.id, shadowOf(service).lastForegroundNotificationId)
    }

    private fun incomingCall() {
        service.onStartCommand(
            Intent(service, StandaloneCallService::class.java).apply {
                action = StandaloneServiceAction.IncomingCall.action
                putExtras(caller.toBundle())
            },
            0,
            1,
        )
    }

    private fun clearStandalone() {
        StandaloneCallService.connections.clear()
        StandaloneCallService.pendingAnswers.clear()
        StandaloneCallService.ringingIncomingCallIds.clear()
        StandaloneCallService.cancelledIncomingCallIds.clear()
        StandaloneCallService.callGroup = CallGroup.empty
    }

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
}
