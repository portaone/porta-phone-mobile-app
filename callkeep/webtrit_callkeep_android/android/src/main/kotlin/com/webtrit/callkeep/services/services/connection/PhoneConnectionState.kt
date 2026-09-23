package com.webtrit.callkeep.services.services.connection

/**
 * Whether the proximity sensor should be listened to for the calls this backend holds.
 *
 * Owned by [PhoneConnectionService] and read by [ProximitySensorManager], which decides the
 * screen wakelock from it.
 */
class PhoneConnectionConsts {
    private var shouldListenProximity: Boolean = false

    fun setShouldListenProximity(shouldListen: Boolean) {
        shouldListenProximity = shouldListen
    }

    fun shouldListenProximity(): Boolean = shouldListenProximity
}
