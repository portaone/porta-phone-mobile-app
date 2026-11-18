package com.webtrit.callkeep.services.core

import com.webtrit.callkeep.POfferTimeSource
import com.webtrit.callkeep.POfferVia

// The Pigeon names of where an offer time comes from and how an offer arrived, in the terms of
// CallAttempts. TEMPORARY(old Core without offered_at): fcm and device.

internal fun POfferTimeSource.toOfferTimeSource(): CallAttempts.OfferTimeSource =
    when (this) {
        POfferTimeSource.CORE -> CallAttempts.OfferTimeSource.CORE
        POfferTimeSource.FCM -> CallAttempts.OfferTimeSource.FCM
        POfferTimeSource.DEVICE -> CallAttempts.OfferTimeSource.DEVICE
    }

internal fun POfferVia.toVia(): CallAttempts.Via =
    when (this) {
        POfferVia.SOCKET -> CallAttempts.Via.SOCKET
        POfferVia.PUSH -> CallAttempts.Via.PUSH
        POfferVia.HANDSHAKE -> CallAttempts.Via.HANDSHAKE
        POfferVia.OTHER -> CallAttempts.Via.OTHER
    }
