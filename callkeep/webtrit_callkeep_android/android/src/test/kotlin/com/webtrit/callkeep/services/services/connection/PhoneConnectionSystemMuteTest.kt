package com.webtrit.callkeep.services.services.connection

import android.content.Context
import android.os.Build
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.managers.AudioManager
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.broadcaster.CallMediaEvent
import com.webtrit.callkeep.services.services.connection.models.PerformDispatchHandle
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.mock
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

/**
 * Telecom's mute is the system's own and the app's mute never reaches it, so Telecom
 * re-announces a stale "unmuted" whenever it re-describes a call - a call leaving its group,
 * measured on a Pixel. Only a change of the system's value may reach the call.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class PhoneConnectionSystemMuteTest {
    private val context: Context = RuntimeEnvironment.getApplication()
    private val reported = mutableListOf<Boolean?>()
    private val recording: PerformDispatchHandle = { event, data ->
        if (event == CallMediaEvent.AudioMuting) reported += data?.hasMute
    }

    @Before
    fun setUp() {
        ContextHolder.init(context)
        ConnectionManager.instance = ConnectionManager()
    }

    private fun connection(): PhoneConnection =
        PhoneConnection(
            context = context,
            dispatcher = recording,
            metadata = CallMetadata(callId = "room-leg"),
            onDisconnectCallback = {},
            audioManager = mock(AudioManager::class.java),
        )

    @Test
    fun `a repeated system unmute keeps the app's mute`() {
        val connection = connection()

        connection.changeMuteState(true)
        connection.onMuteStateChanged(false)

        assertTrue(connection.hasMute)
        assertEquals(listOf<Boolean?>(true), reported)
    }

    @Test
    fun `a system mute and unmute both reach the call`() {
        val connection = connection()

        connection.onMuteStateChanged(true)
        connection.onMuteStateChanged(false)

        assertFalse(connection.hasMute)
        assertEquals(listOf<Boolean?>(true, false), reported)
    }

    @Test
    fun `a repeated system mute keeps the app's unmute`() {
        val connection = connection()

        connection.onMuteStateChanged(true)
        connection.changeMuteState(false)
        connection.onMuteStateChanged(true)

        assertFalse(connection.hasMute)
        assertEquals(listOf<Boolean?>(true, false), reported)
    }
}
