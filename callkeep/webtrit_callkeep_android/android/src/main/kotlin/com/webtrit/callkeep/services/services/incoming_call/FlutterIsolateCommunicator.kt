package com.webtrit.callkeep.services.services.incoming_call

import android.content.Context
import com.webtrit.callkeep.PCallkeepIncomingCallData
import com.webtrit.callkeep.PDelegateBackgroundRegisterFlutterApi
import com.webtrit.callkeep.PDelegateBackgroundServiceFlutterApi
import com.webtrit.callkeep.common.syncPushIsolate
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

interface FlutterIsolateCommunicator {
    fun performAnswer(
        callId: String,
        onSuccess: () -> Unit,
        onFailure: (Throwable) -> Unit,
    )

    fun performEndCall(
        callId: String,
        onSuccess: () -> Unit,
        onFailure: (Throwable) -> Unit,
    )

    fun syncPushIsolate(
        callData: PCallkeepIncomingCallData?,
        onSuccess: () -> Unit,
        onFailure: (Throwable) -> Unit,
    )
}

/**
 * Bridges the callback-style [FlutterIsolateCommunicator] to the suspend functions pigeon
 * generates for the push-isolate Flutter APIs. Calls are launched on
 * [Dispatchers.Main.immediate], so a call made on the main thread is sent to Dart before
 * the caller continues, as the callback-style generated code used to.
 */
class DefaultFlutterIsolateCommunicator(
    private val context: Context,
    private val serviceApi: PDelegateBackgroundServiceFlutterApi?,
    private val registerApi: PDelegateBackgroundRegisterFlutterApi?,
    private val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate),
) : FlutterIsolateCommunicator {
    override fun performAnswer(
        callId: String,
        onSuccess: () -> Unit,
        onFailure: (Throwable) -> Unit,
    ) {
        val api = serviceApi ?: return onFailure(IllegalStateException("Service API unavailable"))
        relay(onSuccess, onFailure) { api.performAnswerCall(callId) }
    }

    override fun performEndCall(
        callId: String,
        onSuccess: () -> Unit,
        onFailure: (Throwable) -> Unit,
    ) {
        val api = serviceApi ?: return onFailure(IllegalStateException("Service API unavailable"))
        relay(onSuccess, onFailure) { api.performEndCall(callId) }
    }

    override fun syncPushIsolate(
        callData: PCallkeepIncomingCallData?,
        onSuccess: () -> Unit,
        onFailure: (Throwable) -> Unit,
    ) {
        val api = registerApi ?: return onFailure(IllegalStateException("Register API unavailable"))
        relay(onSuccess, onFailure) { api.syncPushIsolate(context, callData) }
    }

    private fun relay(
        onSuccess: () -> Unit,
        onFailure: (Throwable) -> Unit,
        block: suspend () -> Unit,
    ) {
        scope.launch {
            runCatching { block() }.onSuccess { onSuccess() }.onFailure { onFailure(it) }
        }
    }
}
