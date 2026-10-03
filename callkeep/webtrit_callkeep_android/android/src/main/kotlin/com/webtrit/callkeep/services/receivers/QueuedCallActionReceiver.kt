package com.webtrit.callkeep.services.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.common.Log
import com.webtrit.callkeep.services.core.CallkeepCore

/**
 * Receives the Decline current action of a waiting call's notification: the core ends the call
 * that rings, the same way the decline button of that call's own notification does, and the
 * queue then puts the oldest waiting call through.
 */
class QueuedCallActionReceiver : BroadcastReceiver() {
    override fun onReceive(
        context: Context,
        intent: Intent,
    ) {
        if (intent.action != ACTION_DECLINE_RINGING) return
        ContextHolder.init(context.applicationContext)
        Log.i(TAG, "onReceive: declining the ringing call for the queue")
        CallkeepCore.instance.declineRingingCalls()
    }

    companion object {
        private const val TAG = "QueuedCallActionReceiver"

        const val ACTION_DECLINE_RINGING = "com.webtrit.callkeep.QUEUED_CALL_DECLINE_RINGING"
    }
}
