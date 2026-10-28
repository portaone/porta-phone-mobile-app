package com.webtrit.callkeep.models

import android.os.Build
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** The initiator crosses the process boundary inside the metadata bundle, so it must survive it. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class CallMetadataEndedByTest {
    @Test
    fun `endedBy survives the bundle roundtrip`() {
        CallEndedBy.entries.forEach { endedBy ->
            val restored = CallMetadata.fromBundle(CallMetadata(callId = "c", endedBy = endedBy).toBundle())
            assertEquals(endedBy, restored.endedBy)
        }
    }

    @Test
    fun `metadata without endedBy reads back without one`() {
        assertNull(CallMetadata.fromBundle(CallMetadata(callId = "c").toBundle()).endedBy)
    }

    @Test
    fun `merge takes a newer endedBy and keeps the old one when the newer has none`() {
        val base = CallMetadata(callId = "c", endedBy = CallEndedBy.USER)

        assertEquals(CallEndedBy.SYSTEM, base.mergeWith(CallMetadata(callId = "c", endedBy = CallEndedBy.SYSTEM)).endedBy)
        assertEquals(CallEndedBy.USER, base.mergeWith(CallMetadata(callId = "c")).endedBy)
    }

    @Test
    fun `an absent or unknown stored name reads as the system's`() {
        assertEquals(CallEndedBy.SYSTEM, CallEndedBy.fromNameOrSystem(null))
        assertEquals(CallEndedBy.SYSTEM, CallEndedBy.fromNameOrSystem("NOBODY"))
        assertEquals(CallEndedBy.USER, CallEndedBy.fromNameOrSystem("USER"))
    }

    @Test
    fun `the Pigeon enum maps both ways`() {
        CallEndedBy.entries.forEach { assertEquals(it, it.toPEndedBy().toCallEndedBy()) }
    }
}
