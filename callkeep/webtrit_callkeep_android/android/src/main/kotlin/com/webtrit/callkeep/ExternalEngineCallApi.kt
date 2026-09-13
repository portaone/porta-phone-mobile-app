package com.webtrit.callkeep

import com.webtrit.callkeep.common.Log
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.core.CallkeepCore

/**
 * [PHostBackgroundPushNotificationIsolateApi] implementation used when callkeep is hosted on a
 * Flutter engine it did not create itself, registered via [WebtritCallkeep.attachToEngine].
 *
 * It is decoupled from [com.webtrit.callkeep.services.services.incoming_call.IncomingCallService]
 * and the push pathway: call-control requests are routed straight to [CallkeepCore], which owns
 * the active Telecom/standalone connection.
 */
internal class ExternalEngineCallApi : PHostBackgroundPushNotificationIsolateApi {
    override suspend fun releaseCall(callId: String) {
        try {
            CallkeepCore.instance.startDeclineCall(CallMetadata(callId = callId))
        } catch (e: Exception) {
            Log.e(TAG, "releaseCall failed for callId=$callId", e)
            throw e
        }
    }

    override suspend fun endCall(callId: String) {
        try {
            CallkeepCore.instance.startDeclineCall(CallMetadata(callId = callId))
        } catch (e: Exception) {
            Log.e(TAG, "endCall failed for callId=$callId", e)
            throw e
        }
    }

    override suspend fun endAllCalls() {
        try {
            CallkeepCore.instance.sendTearDownConnections()
        } catch (e: Exception) {
            Log.e(TAG, "endAllCalls failed", e)
            throw e
        }
    }

    override suspend fun handoffCall(callId: String) {
        // The host engine owns the WebSocket in persistent/socket mode; handoff is not applicable.
    }

    companion object {
        private const val TAG = "ExternalEngineCallApi"
    }
}
