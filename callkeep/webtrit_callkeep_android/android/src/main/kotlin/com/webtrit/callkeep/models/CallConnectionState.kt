package com.webtrit.callkeep.models

/** Callkeep-owned lifecycle states, independent of Telecom and generated Pigeon types. */
enum class CallConnectionState {
    INITIALIZING,
    NEW,
    RINGING,
    DIALING,
    ACTIVE,
    HOLDING,
    DISCONNECTED,
}
