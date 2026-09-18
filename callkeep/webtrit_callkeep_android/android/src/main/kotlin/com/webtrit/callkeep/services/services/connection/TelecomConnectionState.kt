package com.webtrit.callkeep.services.services.connection

import android.telecom.Connection
import com.webtrit.callkeep.models.CallConnectionState

/** Maps only the framework states represented by Callkeep's lifecycle model. */
internal fun telecomConnectionState(state: Int): CallConnectionState? =
    when (state) {
        Connection.STATE_INITIALIZING -> CallConnectionState.INITIALIZING
        Connection.STATE_NEW -> CallConnectionState.NEW
        Connection.STATE_RINGING -> CallConnectionState.RINGING
        Connection.STATE_DIALING -> CallConnectionState.DIALING
        Connection.STATE_ACTIVE -> CallConnectionState.ACTIVE
        Connection.STATE_HOLDING -> CallConnectionState.HOLDING
        Connection.STATE_DISCONNECTED -> CallConnectionState.DISCONNECTED
        else -> null
    }
