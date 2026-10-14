package com.webtrit.callkeep.services.services.active_call

import android.Manifest
import android.app.Application
import android.app.Notification
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Bundle
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.models.CallMetadata
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements
import org.robolectric.shadows.ShadowService

/**
 * The foreground service types [ActiveCallService] asks for, and what it does when the system
 * refuses the microphone type.
 *
 * The microphone type is what keeps the app's microphone recording while the app is in the
 * background during a call. Since Android 14 it is a "while-in-use" type: the system grants it
 * only to a service started while the app is visible, and throws SecurityException otherwise.
 * Some vendor builds (Samsung One UI) also cut the microphone off when the screen goes dark if
 * the type is missing, so the type is requested whenever the RECORD_AUDIO permission is held -
 * not only when an audio device is known. A refusal must not crash the service: it falls back to
 * the phone-call type, which is not restricted.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE], shadows = [ShadowMicrophoneRefusingService::class])
class ActiveCallServiceForegroundTypeTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private val application get() = shadowOf(context as Application)

    @Before
    fun setUp() {
        ShadowMicrophoneRefusingService.refuseMicrophone = false
    }

    @After
    fun tearDown() {
        ShadowMicrophoneRefusingService.refuseMicrophone = false
    }

    private fun startWith(vararg calls: CallMetadata): ActiveCallService {
        val service = Robolectric.buildService(ActiveCallService::class.java).create().get()
        val intent =
            Intent(context, ActiveCallService::class.java).apply {
                putParcelableArrayListExtra(
                    ActiveCallService.EXTRA_CALLS_METADATA,
                    ArrayList<Bundle>(calls.map { it.toBundle() }),
                )
            }
        service.onStartCommand(intent, 0, 1)
        return service
    }

    private fun Service.foregroundType(): Int = foregroundServiceType

    @Test
    fun `audio call with the microphone permission runs as phone call and microphone`() {
        application.grantPermissions(Manifest.permission.RECORD_AUDIO)

        val service = startWith(CallMetadata(callId = "a"))

        assertEquals(
            ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
            service.foregroundType(),
        )
    }

    @Test
    fun `microphone type does not wait for a known audio device`() {
        application.grantPermissions(Manifest.permission.RECORD_AUDIO)

        // No audio device and no device list in the metadata, as at the very start of a call.
        val service = startWith(CallMetadata(callId = "a", audioDevice = null, audioDevices = emptyList()))

        assertEquals(
            ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
            service.foregroundType() and ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
        )
    }

    @Test
    fun `without the microphone permission only the phone call type is requested`() {
        application.denyPermissions(Manifest.permission.RECORD_AUDIO)

        val service = startWith(CallMetadata(callId = "a"))

        assertEquals(ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL, service.foregroundType())
    }

    @Test
    fun `video call with the camera permission adds the camera type`() {
        application.grantPermissions(Manifest.permission.RECORD_AUDIO, Manifest.permission.CAMERA)

        val service = startWith(CallMetadata(callId = "a", hasVideo = true))

        assertEquals(
            ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL or
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE or
                ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA,
            service.foregroundType(),
        )
    }

    @Test
    fun `video call without the camera permission gets no camera type`() {
        application.grantPermissions(Manifest.permission.RECORD_AUDIO)
        application.denyPermissions(Manifest.permission.CAMERA)

        val service = startWith(CallMetadata(callId = "a", hasVideo = true))

        assertEquals(0, service.foregroundType() and ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA)
    }

    @Test
    fun `audio call never asks for the camera type`() {
        application.grantPermissions(Manifest.permission.RECORD_AUDIO, Manifest.permission.CAMERA)

        val service = startWith(CallMetadata(callId = "a", hasVideo = false))

        assertEquals(0, service.foregroundType() and ServiceInfo.FOREGROUND_SERVICE_TYPE_CAMERA)
    }

    @Test
    fun `refused microphone type falls back to the phone call type and keeps the service`() {
        application.grantPermissions(Manifest.permission.RECORD_AUDIO)
        ShadowMicrophoneRefusingService.refuseMicrophone = true

        val service = startWith(CallMetadata(callId = "a"))

        assertEquals(ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL, service.foregroundType())
        assertFalse("service must keep running", shadowOf(service).isStoppedBySelf)
        assertFalse("foreground must stay", shadowOf(service).isForegroundStopped)
    }
}

/**
 * Plays the system's refusal of the "while-in-use" microphone type for a service started while
 * the app is not visible: startForeground with a type that includes the microphone throws
 * SecurityException, any other type is accepted as usual.
 */
@Implements(Service::class)
class ShadowMicrophoneRefusingService : ShadowService() {
    @Implementation
    override fun startForeground(
        id: Int,
        notification: Notification,
        foregroundServiceType: Int,
    ) {
        if (refuseMicrophone && foregroundServiceType and ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE != 0) {
            throw SecurityException("Starting FGS with type microphone requires the app to be visible")
        }
        super.startForeground(id, notification, foregroundServiceType)
    }

    companion object {
        @JvmStatic
        var refuseMicrophone = false
    }
}
