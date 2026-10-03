package com.webtrit.callkeep.services.core

import com.webtrit.callkeep.models.CallMetadata

/** Shows and removes the notification of a call waiting in the core's queue. */
interface QueuedCallNotifier {
    fun show(metadata: CallMetadata)

    fun cancel(callId: String)
}
