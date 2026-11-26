package com.webtrit.callkeep.services.services.screen_share

import android.hardware.display.DisplayManager
import android.os.Handler

/**
 * Sees the screen capture end by the display it draws into going away.
 *
 * The capture draws into a virtual display it makes from the projection. When the system ends the
 * projection - its own stop control, another capture taking over - it releases that display, and
 * the WebRTC plugin, which alone holds the projection, tells the app nothing: the far end would be
 * left with the last frame. The display's removal is the one trace of that end the app can see.
 *
 * Only displays added while the watch runs and recognised by [isCaptureDisplay] count; a display
 * the watch did not see appear is never taken for the capture's.
 */
internal class ScreenCaptureDisplayWatch(
    private val displayManager: DisplayManager,
    private val isCaptureDisplay: (displayId: Int) -> Boolean,
    private val onCaptureEnded: () -> Unit,
) : DisplayManager.DisplayListener {
    private val captureDisplays = mutableSetOf<Int>()

    fun start(handler: Handler) {
        displayManager.registerDisplayListener(this, handler)
    }

    fun stop() {
        displayManager.unregisterDisplayListener(this)
        captureDisplays.clear()
    }

    override fun onDisplayAdded(displayId: Int) {
        if (isCaptureDisplay(displayId)) captureDisplays += displayId
    }

    override fun onDisplayRemoved(displayId: Int) {
        if (captureDisplays.remove(displayId)) onCaptureEnded()
    }

    override fun onDisplayChanged(displayId: Int) = Unit
}
