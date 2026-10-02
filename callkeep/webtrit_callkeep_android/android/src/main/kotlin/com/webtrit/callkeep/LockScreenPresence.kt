package com.webtrit.callkeep

import android.app.Activity
import android.content.Intent
import com.webtrit.callkeep.common.Log
import com.webtrit.callkeep.common.Platform
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
 */
object LockScreenPresence {
    /** Extra on the incoming-call alert's full-screen intent. */
    const val EXTRA_OPENED_BY_CALL_ALERT = "com.webtrit.callkeep.OPENED_BY_CALL_ALERT"

    private const val TAG = "LockScreenPresence"

    /** True when [intent] is the call alert's, the phone is locked and a call is there to show. */
    fun isCallAlertLaunch(
        intent: Intent?,
        isLocked: Boolean,
        hasCalls: Boolean,
    ): Boolean = isLocked && hasCalls && intent?.getBooleanExtra(EXTRA_OPENED_BY_CALL_ALERT, false) == true

    /** Lets [activity] over the keyguard when [intent], the one that opened it, came from the call alert. */
    fun onActivityIntent(
        activity: Activity,
        intent: Intent?,
    ) {
        val core = CallkeepCore.instance
        val hasCalls = core.getAll().isNotEmpty() || core.getPendingCallIds().isNotEmpty()
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
