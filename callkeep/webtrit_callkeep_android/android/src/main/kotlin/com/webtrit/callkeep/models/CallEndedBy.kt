package com.webtrit.callkeep.models

/**
 * Who ended a call, carried to the Flutter `performEndCall` so the app does not have to guess
 * whether the user declined or something else ended the call.
 *
 * A local type, like [CallConnectionState]: it travels inside [CallMetadata] bundles across the
 * process boundary and through `startService` intents as its [name], and becomes
 * `PEndedByEnum` only at the Pigeon boundary ([toPEndedBy]).
 */
enum class CallEndedBy {
    /**
     * A person on this device: the system call UI, a headset or the notification's Decline, or
     * the app asking on the user's behalf.
     */
    USER,

    /** The app on its own: a teardown, a queued call dropped, a release. */
    APP,

    /** The platform (ring timeout, Telecom refusal, a synthesized hang-up) or an initiator not known. */
    SYSTEM,
    ;

    companion object {
        /** Reads a value stored by [name]; an absent or unknown one is [SYSTEM], the initiator not known. */
        fun fromNameOrSystem(name: String?): CallEndedBy = entries.firstOrNull { it.name == name } ?: SYSTEM

        fun fromNameOrNull(name: String?): CallEndedBy? = entries.firstOrNull { it.name == name }
    }
}
