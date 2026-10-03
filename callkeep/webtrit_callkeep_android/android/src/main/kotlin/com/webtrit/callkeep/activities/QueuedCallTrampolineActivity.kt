package com.webtrit.callkeep.activities

import android.app.Activity
import android.os.Bundle
import com.webtrit.callkeep.common.ActivityHolder
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.common.Log
import com.webtrit.callkeep.services.core.CallkeepCore

/**
 * Invisible activity behind the Answer action of a waiting call's notification.
 *
 * Answering a waiting call ends the call that rings and answers this one as soon as it rings,
 * and the user has to land on the call screen. The launch privilege belongs to the user's tap,
 * so, like [AnswerCallTrampolineActivity], the action targets this activity: it hands the
 * answer to the core, brings the host app up and finishes.
 */
class QueuedCallTrampolineActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ContextHolder.init(applicationContext)

        val callId = intent?.getStringExtra(EXTRA_CALL_ID)
        if (callId == null) {
            Log.w(TAG, "onCreate: no call id in the intent, nothing to answer")
        } else if (!CallkeepCore.instance.answerQueuedCall(callId)) {
            Log.w(TAG, "onCreate: $callId is no longer waiting")
        } else {
            Log.i(TAG, "onCreate: answering waiting call $callId")
        }

        ActivityHolder.start(this)
        finish()
    }

    companion object {
        private const val TAG = "QueuedCallTrampolineActivity"

        const val EXTRA_CALL_ID = "com.webtrit.callkeep.QUEUED_CALL_ID"
    }
}
