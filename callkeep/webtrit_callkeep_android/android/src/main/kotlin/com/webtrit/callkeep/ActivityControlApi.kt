package com.webtrit.callkeep

import android.app.Activity
import com.webtrit.callkeep.common.Log
import com.webtrit.callkeep.common.isDeviceLockedCompat
import com.webtrit.callkeep.common.moveTaskToBackCompat
import com.webtrit.callkeep.common.setShowWhenLockedCompat
import com.webtrit.callkeep.common.setTurnScreenOnCompat

/**
 * Implements the Pigeon API for controlling Android Activity behavior
 * by delegating logic to Activity/Context extensions.
 *
 * Every method runs on the main thread: pigeon dispatches host calls on
 * [kotlinx.coroutines.Dispatchers.Main], which is where the window flags
 * below must be touched anyway.
 *
 * @param activity The current foreground Activity.
 */
class ActivityControlApi(
    private val activity: Activity,
) : PHostActivityControlApi {
    companion object {
        private const val TAG = "ActivityControlApi"
        private val logger = Log(TAG)
    }

    /**
     * Allows the app's activity to be shown over the device lock screen.
     */
    override suspend fun showOverLockscreen(enable: Boolean) {
        logger.d("showOverLockscreen(enable: $enable) called")
        try {
            activity.setShowWhenLockedCompat(enable)
            logger.d("showOverLockscreen success")
        } catch (e: Exception) {
            logger.e("showOverLockscreen error: ${e.message}")
            throw e
        }
    }

    /**
     * Turns the screen on when the app's window is shown.
     */
    override suspend fun wakeScreenOnShow(enable: Boolean) {
        logger.d("wakeScreenOnShow(enable: $enable) called")
        try {
            activity.setTurnScreenOnCompat(enable)
            logger.d("wakeScreenOnShow success")
        } catch (e: Exception) {
            logger.e("wakeScreenOnShow error: ${e.message}")
            throw e
        }
    }

    /**
     * Moves the entire task (app) to the background.
     */
    override suspend fun sendToBackground(): Boolean {
        logger.d("sendToBackground() called")
        try {
            val result = activity.moveTaskToBackCompat()
            logger.d("sendToBackground success, result: $result")
            return result
        } catch (e: Exception) {
            logger.e("sendToBackground error: ${e.message}")
            throw e
        }
    }

    /**
     * Checks if the device screen is currently locked (keyguard is active).
     */
    override suspend fun isDeviceLocked(): Boolean {
        logger.d("isDeviceLocked() called")
        try {
            val isLocked = activity.isDeviceLockedCompat()
            logger.d("isDeviceLocked success, result: $isLocked")
            return isLocked
        } catch (e: Exception) {
            logger.e("isDeviceLocked error: ${e.message}")
            throw e
        }
    }
}
