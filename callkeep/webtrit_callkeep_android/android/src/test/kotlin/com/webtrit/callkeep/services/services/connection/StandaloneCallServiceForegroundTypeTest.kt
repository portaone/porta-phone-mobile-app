package com.webtrit.callkeep.services.services.connection

import android.app.Notification
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.models.CallGroup
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.core.CallkeepCore
import com.webtrit.callkeep.services.services.active_call.ShadowMicrophoneRefusingService
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * The foreground service types of the call backend used where the system has no Telecom.
 *
 * This service holds the call itself, so its foreground type decides whether the app keeps the
 * microphone in the background. An incoming call may ring while the app is in the background
 * (it arrives by push), and since Android 14 the microphone type cannot be granted to a service
 * started there: it rings with the phone-call type only. An outgoing call is placed from the app,
 * which is visible then, so it takes the microphone type at setup. Once a call is answered or
 * established it runs with the microphone type; whenever the system refuses that type, the call
 * carries on with the phone-call type instead of crashing the service. A type the service already
 * holds is never taken away: neither by a second call that starts to ring, nor by a refused
 * repeat request at the answer.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE], shadows = [ShadowMicrophoneRefusingService::class])
class StandaloneCallServiceForegroundTypeTest {
    private val app get() = ApplicationProvider.getApplicationContext<Context>()
    private lateinit var service: StandaloneCallService
    private val call = CallMetadata(callId = "call", displayName = "Peer")

    private val phoneCall = ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL
    private val phoneCallAndMicrophone =
        ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE

    @Before
    fun setUp() {
        ContextHolder.init(app)
        clearStandalone()
        registerLauncherActivity()
        ShadowMicrophoneRefusingService.refuseMicrophone = false
        service = Robolectric.buildService(StandaloneCallService::class.java).create().get()
    }

    @After
    fun tearDown() {
        ShadowMicrophoneRefusingService.refuseMicrophone = false
        clearStandalone()
        CallkeepCore.instance.clear()
    }

    private fun send(
        action: StandaloneServiceAction,
        metadata: CallMetadata = call,
    ) {
        service.onStartCommand(
            Intent(service, StandaloneCallService::class.java).apply {
                this.action = action.action
                putExtras(metadata.toBundle())
            },
            0,
            1,
        )
    }

    @Test
    fun `ringing incoming call runs with the phone call type only`() {
        send(StandaloneServiceAction.IncomingCall)

        assertEquals(phoneCall, service.foregroundServiceType)
    }

    @Test
    fun `outgoing call being set up takes the microphone type at once`() {
        send(StandaloneServiceAction.OutgoingCall)

        assertEquals(phoneCallAndMicrophone, service.foregroundServiceType)
    }

    @Test
    fun `refused microphone type at outgoing setup keeps the call on the phone call type`() {
        ShadowMicrophoneRefusingService.refuseMicrophone = true

        send(StandaloneServiceAction.OutgoingCall)

        assertEquals(phoneCall, service.foregroundServiceType)
        assertFalse("service must keep running", shadowOf(service).isStoppedBySelf)
    }

    @Test
    fun `established outgoing call adds the microphone type`() {
        send(StandaloneServiceAction.OutgoingCall)
        send(StandaloneServiceAction.EstablishCall)

        assertEquals(phoneCallAndMicrophone, service.foregroundServiceType)
    }

    @Test
    fun `answered incoming call adds the microphone type`() {
        send(StandaloneServiceAction.IncomingCall)
        send(StandaloneServiceAction.AnswerCall)

        assertEquals(phoneCallAndMicrophone, service.foregroundServiceType)
    }

    @Test
    fun `refused microphone type on an answered call keeps the call on the phone call type`() {
        send(StandaloneServiceAction.IncomingCall)
        ShadowMicrophoneRefusingService.refuseMicrophone = true

        send(StandaloneServiceAction.AnswerCall)

        assertEquals(phoneCall, service.foregroundServiceType)
        assertFalse("service must keep running", shadowOf(service).isStoppedBySelf)
    }

    @Test
    fun `refused repeat at the answer keeps the microphone type taken at dial-out`() {
        send(StandaloneServiceAction.OutgoingCall)
        ShadowMicrophoneRefusingService.refuseMicrophone = true

        send(StandaloneServiceAction.EstablishCall)

        assertEquals(phoneCallAndMicrophone, service.foregroundServiceType)
        assertFalse("service must keep running", shadowOf(service).isStoppedBySelf)
        assertNotNull("the ongoing call is still shown", shownNotification(StandaloneCallService.NOTIFICATION_ID))
    }

    @Test
    fun `call notification left beside the placeholder goes with the service`() {
        send(StandaloneServiceAction.OutgoingCall)
        ShadowMicrophoneRefusingService.refuseMicrophone = true
        send(StandaloneServiceAction.EstablishCall)

        service.onDestroy()

        assertNull(shownNotification(StandaloneCallService.NOTIFICATION_ID))
    }

    @Test
    fun `call ringing while another is dialing keeps the microphone type`() {
        send(StandaloneServiceAction.OutgoingCall)

        send(StandaloneServiceAction.IncomingCall, CallMetadata(callId = "second", displayName = "Second"))

        assertEquals(phoneCallAndMicrophone, service.foregroundServiceType)
    }

    @Test
    fun `call ringing during an answered call keeps the microphone type`() {
        send(StandaloneServiceAction.IncomingCall)
        send(StandaloneServiceAction.AnswerCall)

        send(StandaloneServiceAction.IncomingCall, CallMetadata(callId = "second", displayName = "Second"))

        assertEquals(phoneCallAndMicrophone, service.foregroundServiceType)
    }

    @Test
    fun `refused microphone type for a second ringing call keeps the call in progress on it`() {
        send(StandaloneServiceAction.OutgoingCall)
        ShadowMicrophoneRefusingService.refuseMicrophone = true

        send(StandaloneServiceAction.IncomingCall, CallMetadata(callId = "second", displayName = "Second"))

        assertEquals(phoneCallAndMicrophone, service.foregroundServiceType)
        assertFalse("service must keep running", shadowOf(service).isStoppedBySelf)
    }

    private fun shownNotification(id: Int): Notification? = shadowOf(app.getSystemService(NotificationManager::class.java)).getNotification(id)

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
