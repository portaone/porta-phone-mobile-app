package com.webtrit.callkeep.services.core

import android.os.Handler
import android.os.Looper
import com.webtrit.callkeep.PIncomingCallError
import com.webtrit.callkeep.PIncomingCallErrorEnum
import com.webtrit.callkeep.models.CallMetadata
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.suspendCancellableCoroutine

/**
 * One pending operation per call, confined to the platform thread.
 *
 * The core owns dispatch and call-state transitions; this class owns waiters and deadlines.
 * A Registration is also the identity of an attempt: a late dispatch callback cannot complete
 * a newer attempt that reused its call id. Completion removes the attempt and its timer before
 * updating call state and answering callers, which may immediately reenter the core.
 */
internal class IncomingRegistrations(
    private val handler: Handler,
    private val timeoutMs: () -> Long,
    private val onTimeout: (Registration) -> Unit,
) {
    internal class Registration(
        val metadata: CallMetadata,
    ) {
        val callId get() = metadata.callId
        internal val waiters = mutableListOf<Waiter>()
        internal lateinit var timeout: Runnable
    }

    internal class Waiter(
        val client: Any,
        val joined: Boolean,
        val continuation: CancellableContinuation<PIncomingCallError?>,
    ) {
        fun answer(result: Result<PIncomingCallError?>) {
            if (!continuation.isActive) return
            continuation.resumeWith(
                result.map { if (joined) it ?: PIncomingCallError(PIncomingCallErrorEnum.CALL_ID_ALREADY_EXISTS) else it },
            )
        }
    }

    private val registrations = mutableMapOf<String, Registration>()

    // State broadcasts can arrive after a refusal, even ACTIVE before a deferred AnswerCall.
    // Keep that refusal separate from the mirrored Telecom state until an actual new attempt.
    private val rejectedCallIds = mutableSetOf<String>()

    fun markRejected(callId: String) {
        rejectedCallIds += callId
    }

    fun wasRejected(callId: String): Boolean = callId in rejectedCallIds

    fun allowRetry(callId: String) {
        rejectedCallIds.remove(callId)
    }

    fun clearRejections() {
        rejectedCallIds.clear()
    }

    operator fun get(callId: String): Registration? = registrations[callId]

    fun isCurrent(registration: Registration): Boolean = registrations[registration.callId] === registration

    fun snapshot(): List<Registration> = registrations.values.toList()

    suspend fun await(
        metadata: CallMetadata,
        client: Any,
        dispatch: (Registration) -> Unit,
    ): PIncomingCallError? =
        suspendCancellableCoroutine { continuation ->
            check(Looper.myLooper() == handler.looper) { "Incoming registration must run on the platform thread" }
            val existing = registrations[metadata.callId]
            val registration = existing ?: Registration(metadata).also { registrations[it.callId] = it }
            val waiter = Waiter(client, joined = existing != null, continuation)
            registration.waiters += waiter
            continuation.invokeOnCancellation {
                // Cancellation releases this caller, not the backend call or other callers. It can
                // originate on another thread; all mutation of the operation stays on the main looper.
                if (Looper.myLooper() == handler.looper) {
                    registration.waiters.remove(waiter)
                } else {
                    handler.post { registration.waiters.remove(waiter) }
                }
            }
            if (existing == null) {
                allowRetry(metadata.callId)
                registration.timeout = Runnable { onTimeout(registration) }
                handler.postDelayed(registration.timeout, timeoutMs())
                dispatch(registration)
            }
        }

    fun complete(
        registration: Registration,
        result: Result<PIncomingCallError?>,
        rejected: Boolean = false,
        beforeAnswer: () -> Unit = {},
    ): Boolean {
        if (!isCurrent(registration)) return false
        registrations.remove(registration.callId)
        handler.removeCallbacks(registration.timeout)
        if (rejected) markRejected(registration.callId)
        beforeAnswer()
        val waiters = registration.waiters.toList()
        registration.waiters.clear()
        waiters.forEach { it.answer(result) }
        return true
    }

    fun hasClient(
        registration: Registration,
        client: Any,
    ): Boolean = registration.waiters.any { it.client === client }

    fun hasOtherClients(
        registration: Registration,
        client: Any,
    ): Boolean = registration.waiters.any { it.client !== client }

    fun detach(
        registration: Registration,
        client: Any,
    ) {
        val detached = registration.waiters.filter { it.client === client }
        registration.waiters.removeAll(detached)
        val rejected = Result.success(PIncomingCallError(PIncomingCallErrorEnum.CALL_REJECTED_BY_SYSTEM))
        detached.forEach { it.answer(rejected) }
    }
}
