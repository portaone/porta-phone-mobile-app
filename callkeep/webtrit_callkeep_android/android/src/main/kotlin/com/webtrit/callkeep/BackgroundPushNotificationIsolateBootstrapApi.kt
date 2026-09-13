package com.webtrit.callkeep

import android.content.Context
import com.webtrit.callkeep.common.Log
import com.webtrit.callkeep.common.StorageDelegate
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.models.toCallHandle
import com.webtrit.callkeep.services.core.CallkeepCore
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

class BackgroundPushNotificationIsolateBootstrapApi(
    private val context: Context,
) : PHostBackgroundPushNotificationIsolateBootstrapApi {
    override suspend fun initializePushNotificationCallback(
        callbackDispatcher: Long,
        onNotificationSync: Long,
    ) {
        StorageDelegate.IncomingCallService.setCallbackDispatcher(context, callbackDispatcher)
        StorageDelegate.IncomingCallService.setOnNotificationSync(context, onNotificationSync)
    }

    override suspend fun reportNewIncomingCall(
        callId: String,
        handle: PHandle,
        displayName: String?,
        hasVideo: Boolean,
    ): PIncomingCallError? {
        Log.d(TAG, "reportNewIncomingCall: $callId, $handle, $displayName, $hasVideo")
        val ringtonePath = StorageDelegate.Sound.getRingtonePath(context)

        val metadata =
            CallMetadata(
                callId = callId,
                handle = handle.toCallHandle(),
                displayName = displayName,
                hasVideo = hasVideo,
                ringtonePath = ringtonePath,
            )

        return suspendCancellableCoroutine { continuation ->
            CallkeepCore.instance.startIncomingCall(
                metadata = metadata,
                onSuccess = { continuation.resume(null) },
                onError = { error -> continuation.resume(error) },
            )
        }
    }

    companion object {
        const val TAG = "PigeonPushNotificationIsolateApi"
    }
}
