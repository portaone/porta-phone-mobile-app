package com.webtrit.callkeep.services.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import com.webtrit.callkeep.common.AssetCacheManager
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.common.Log
import com.webtrit.callkeep.common.StorageDelegate
import com.webtrit.callkeep.models.CallHandle
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.core.CallkeepCore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.net.URLDecoder

class IncomingCallSmsTriggerReceiver : BroadcastReceiver() {
    override fun onReceive(
        context: Context,
        intent: Intent,
    ) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        ContextHolder.init(context)
        AssetCacheManager.init(context)

        val prefix = StorageDelegate.IncomingCallSmsConfig.getSmsPrefix(context) ?: return
        val pattern = StorageDelegate.IncomingCallSmsConfig.getRegexPattern(context) ?: return
        val regex =
            runCatching { Regex(pattern) }.getOrElse {
                Log.e(TAG, "Invalid regex: $pattern, error: ${it.message}")
                return
            }

        val validMessages = extractValidSmsMessages(context, intent, prefix, regex)
        if (validMessages.isEmpty()) {
            Log.e(TAG, "No valid SMS messages found with prefix: $prefix and regex: $regex")
            return
        }

        // The registration waits for Telecom's answer, at most the core's deadline, so the
        // broadcast is kept alive until it is known rather than ended on dispatch.
        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.Main.immediate).launch {
            try {
                validMessages.forEach { registerCall(it) }
            } finally {
                pendingResult.finish()
            }
        }
    }

    /**
     * Registers an SMS-triggered call through the same core operation as push and signaling,
     * so it joins a report of the same call already waiting, is refused when that call already
     * ended, and its refusal or deadline is settled by the core.
     */
    internal suspend fun registerCall(
        metadata: CallMetadata,
        core: CallkeepCore = CallkeepCore.instance,
    ) {
        try {
            val error = core.registerIncomingCall(metadata, SmsClient)
            if (error == null) {
                Log.d(TAG, "Incoming call registered: ${metadata.callId}")
            } else {
                Log.w(TAG, "Incoming call not registered: ${metadata.callId}, ${error.value}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception registering call ${metadata.callId}: ${e.message}")
        }
    }

    private fun extractValidSmsMessages(
        context: Context,
        intent: Intent,
        prefix: String,
        regex: Regex,
    ): List<CallMetadata> {
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return emptyList()

        val fullBody = messages.joinToString(separator = "") { it.messageBody ?: "" }
        if (!fullBody.contains(prefix)) return emptyList()

        val match = regex.find(fullBody) ?: return emptyList()

        val (callId, handleValue, displayNameEncoded, hasVideoStr) = match.destructured

        return listOf(
            CallMetadata(
                callId = callId,
                handle = CallHandle(handleValue),
                displayName = URLDecoder.decode(displayNameEncoded, "UTF-8"),
                hasVideo = hasVideoStr == "true",
                ringtonePath = StorageDelegate.Sound.getRingtonePath(context),
            ),
        )
    }

    /** Waiter identity of SMS-triggered registrations; no bridge ever detaches it. */
    private object SmsClient

    companion object {
        private const val TAG = "SmsReceiver"
    }
}
