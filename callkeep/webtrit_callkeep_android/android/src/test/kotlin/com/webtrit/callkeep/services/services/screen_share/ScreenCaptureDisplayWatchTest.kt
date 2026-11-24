package com.webtrit.callkeep.services.services.screen_share

import android.hardware.display.DisplayManager
import android.os.Handler
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.shadows.ShadowDisplayManager

/**
 * The end of a screen capture seen by its display going away: only the capture's own display,
 * and only one the watch saw appear, counts.
 */
@RunWith(RobolectricTestRunner::class)
class ScreenCaptureDisplayWatchTest {
    private val displayManager =
        ApplicationProvider.getApplicationContext<android.content.Context>().getSystemService(DisplayManager::class.java)
    private var ended = 0

    private fun watch(isCapture: (Int) -> Boolean) = ScreenCaptureDisplayWatch(displayManager, isCapture) { ended++ }.also { it.start(Handler(Looper.getMainLooper())) }

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    @Test
    fun `the capture display going away ends the capture`() {
        watch { true }
        val capture = ShadowDisplayManager.addDisplay("w100dp-h200dp")
        idle()

        ShadowDisplayManager.removeDisplay(capture)
        idle()

        assertEquals(1, ended)
    }

    @Test
    fun `a display there before the watch is not the capture`() {
        val earlier = ShadowDisplayManager.addDisplay("w100dp-h200dp")
        idle()
        watch { true }

        ShadowDisplayManager.removeDisplay(earlier)
        idle()

        assertEquals(0, ended)
    }

    @Test
    fun `another display going away is not the capture`() {
        watch { false }
        val other = ShadowDisplayManager.addDisplay("w100dp-h200dp")
        idle()

        ShadowDisplayManager.removeDisplay(other)
        idle()

        assertEquals(0, ended)
    }

    @Test
    fun `a stopped watch reports nothing`() {
        val watch = watch { true }
        val capture = ShadowDisplayManager.addDisplay("w100dp-h200dp")
        idle()
        watch.stop()

        ShadowDisplayManager.removeDisplay(capture)
        idle()

        assertEquals(0, ended)
    }
}
