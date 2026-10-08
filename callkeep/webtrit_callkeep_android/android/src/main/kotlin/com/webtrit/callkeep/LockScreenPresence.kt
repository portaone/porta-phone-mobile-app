package com.webtrit.callkeep

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import com.webtrit.callkeep.common.Log
import com.webtrit.callkeep.common.Platform
import com.webtrit.callkeep.common.TelephonyUtils
import com.webtrit.callkeep.common.setShowWhenLockedCompat
import com.webtrit.callkeep.common.setTurnScreenOnCompat
import com.webtrit.callkeep.services.core.CallkeepCore

/**
 * Callkeep's part in showing the host Activity over the keyguard.
 *
 * The app owns the show-when-locked and turn-screen-on flags while it runs: it shows its call
 * screen over the keyguard and clears the flags when that screen goes (ActivityControlApi). One
 * moment is beyond it: the incoming-call alert's full-screen intent opening the Activity on a
 * locked phone. Behind the keyguard a Flutter view draws no frames, so the app never builds the
 * call screen that would let it in, and the call is never seen. Callkeep lets the Activity in at
 * that moment and the app takes over from there.
 *
 * Only an Activity opened by that alert qualifies. One started from the launcher during a call
 * shows whatever screen the app is on - the keypad, the contacts - and must stay behind the
 * keyguard; deciding by "a call exists" let exactly that screen over it.
 *
 * On the standalone call path the same moment may also need the screen woken, see [needsWake].
 */
object LockScreenPresence {
    /** Extra on the incoming-call alert's full-screen intent. */
    const val EXTRA_OPENED_BY_CALL_ALERT = "com.webtrit.callkeep.OPENED_BY_CALL_ALERT"

    private const val TAG = "LockScreenPresence"

    private const val WAKE_LOCK_TAG = "callkeep:call-alert"

    /**
     * How long the waking lock is held. Acquiring it is what turns the screen on; from then on
     * the screen follows the device's own timeout, so the lock has nothing to hold for.
     */
    private const val WAKE_LOCK_HOLD_MS = 1000L

    /** True when [intent] is the call alert's, the phone is locked and a call is there to show. */
    fun isCallAlertLaunch(
        intent: Intent?,
        isLocked: Boolean,
        hasCalls: Boolean,
    ): Boolean = isLocked && hasCalls && intent?.getBooleanExtra(EXTRA_OPENED_BY_CALL_ALERT, false) == true

    /**
     * True when the call alert opened the Activity for a call and the screen is still off, on a
     * device whose calls run on the standalone path.
     *
     * The turn-screen-on window flag acts only when a window goes from hidden to shown. An
     * Activity that was on top when the device went to sleep with no keyguard up - the screen
     * timed out and the lock delay has not passed, or there is no lock screen at all - is still
     * shown as far as the window manager goes, so the alert reopening it wakes nothing and the
     * call rings behind a dark screen (Android 7). Where the system wakes the device for a
     * full-screen intent itself the screen is already on by now and this is false.
     *
     * The Telecom path is left as it is: nobody has looked at this state there.
     */
    fun needsWake(
        intent: Intent?,
        hasCalls: Boolean,
        isInteractive: Boolean,
        isTelecomSupported: Boolean,
    ): Boolean =
        !isTelecomSupported &&
            !isInteractive &&
            hasCalls &&
            intent?.getBooleanExtra(EXTRA_OPENED_BY_CALL_ALERT, false) == true

    /**
     * Shows [activity] for the call when [intent], the one that opened it, came from the call
     * alert: wakes the screen where nothing else will, and lets the Activity over the keyguard.
     */
    fun onActivityIntent(
        activity: Activity,
        intent: Intent?,
    ) {
        val core = CallkeepCore.instance
        val hasCalls = core.getAll().isNotEmpty() || core.getPendingCallIds().isNotEmpty()
        val power = activity.getSystemService(Context.POWER_SERVICE) as PowerManager
        if (needsWake(intent, hasCalls, power.isInteractive, TelephonyUtils.isTelecomSupported(activity))) {
            Log.i(TAG, "opened by the call alert with the screen off: waking it")
            // The one way to wake the device that exists on every supported release; the
            // non-deprecated Activity.setTurnScreenOn is API 27+ and has the same limit as the flag.
            @Suppress("DEPRECATION")
            power
                .newWakeLock(
                    PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                    WAKE_LOCK_TAG,
                ).acquire(WAKE_LOCK_HOLD_MS)
        }
        val isLocked = Platform.isLockScreen(activity)
        if (!isCallAlertLaunch(intent, isLocked, hasCalls)) return
        Log.i(TAG, "opened by the call alert on a locked phone: showing over the keyguard")
        activity.setShowWhenLockedCompat(true)
        activity.setTurnScreenOnCompat(true)
    }

    /**
     * Takes [activity] back behind the keyguard once the last call has ended. The app clears the
     * flags when its call screen goes; a call that ended before that screen was built leaves them
     * to callkeep.
     */
    fun release(activity: Activity?) {
        activity ?: return
        Log.i(TAG, "no call left: behind the keyguard again")
        activity.setShowWhenLockedCompat(false)
        activity.setTurnScreenOnCompat(false)
    }
}
