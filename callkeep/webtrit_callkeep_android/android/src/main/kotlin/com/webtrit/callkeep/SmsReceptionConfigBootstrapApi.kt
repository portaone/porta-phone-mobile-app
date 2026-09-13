package com.webtrit.callkeep

import android.content.Context
import android.util.Log
import com.webtrit.callkeep.common.StorageDelegate

class SmsReceptionConfigBootstrapApi(
    private val context: Context,
) : PHostSmsReceptionConfigApi {
    override suspend fun initializeSmsReception(
        messagePrefix: String,
        regexPattern: String,
    ) {
        Log.i(TAG, "initializeSmsReception: prefix = $messagePrefix, regex = $regexPattern")
        try {
            Regex(regexPattern)
        } catch (e: Exception) {
            Log.e(TAG, "Invalid regex pattern: ${e.message}")
            throw e
        }

        StorageDelegate.IncomingCallSmsConfig.setSmsPrefix(context, messagePrefix)
        StorageDelegate.IncomingCallSmsConfig.setRegexPattern(context, regexPattern)
    }

    companion object {
        const val TAG = "SmsRelayBootstrapApi"
    }
}
