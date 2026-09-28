package com.webtrit.callkeep.services.services.connection

import android.os.Build
import android.os.Looper
import android.telecom.Connection
import android.telecom.DisconnectCause
import com.webtrit.callkeep.models.CallMetadata
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.time.Duration

/**
 * A call outside a group never goes active while a member is, and the group takes the active
 * place back once nothing outside holds it: Telecom arbitrates between two active calls of ours,
 * and on EMUI 12 it disconnected the member held since before the merge to make room.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class PhoneConnectionGroupHoldTest {
    private lateinit var service: PhoneConnectionService

    @Before
    fun setUp() {
        ConnectionManager.instance = ConnectionManager()
        service = Robolectric.buildService(PhoneConnectionService::class.java).create().get()
    }

    private fun call(id: String): PhoneConnection =
        PhoneConnection(service, { _, _ -> }, CallMetadata(callId = id), {}).also {
            ConnectionManager.instance.addConnection(id, it)
        }

    /** A room of two as the merge leaves it: A active, B still held from when A was placed. */
    private fun room(): Pair<PhoneConnection, PhoneConnection> {
        val a = call("A").apply { setActive() }
        val b =
            call("B").apply {
                setActive()
                setOnHold()
            }
        PhoneConnectionService.applyCallGroup(setOf("A", "B"))
        return a to b
    }

    private fun settle() = shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(PhoneConnectionService.GROUP_FOCUS_SETTLE_MS))

    @Test
    fun `a call outside going active holds the group first and goes active after the focus settles`() {
        val (a, b) = room()
        val outside =
            call("C").apply {
                setActive()
                setOnHold()
            }

        outside.onUnhold()

        assertEquals("the active member is held before anything else", Connection.STATE_HOLDING, a.state)
        assertEquals(Connection.STATE_HOLDING, b.state)
        assertEquals("the call outside waits for the focus to leave the member", Connection.STATE_HOLDING, outside.state)
        settle()
        assertEquals(Connection.STATE_ACTIVE, outside.state)
        assertEquals(Connection.STATE_HOLDING, a.state)
    }

    @Test
    fun `holding the call outside gives the place back to one member`() {
        val (a, b) = room()
        a.setOnHold()
        val outside = call("C").apply { setActive() }

        outside.onHold()
        assertEquals("nothing moves before the focus settles", Connection.STATE_HOLDING, a.state)
        settle()

        assertEquals("one member is made active", Connection.STATE_ACTIVE, a.state)
        assertEquals("and only one: a second would make Telecom hold the first again", Connection.STATE_HOLDING, b.state)
    }

    @Test
    fun `the end of the call outside gives the place back too`() {
        val (a, _) = room()
        a.setOnHold()
        val outside = call("C").apply { setActive() }

        outside.setDisconnected(DisconnectCause(DisconnectCause.REMOTE))
        settle()

        assertEquals(Connection.STATE_ACTIVE, a.state)
    }

    @Test
    fun `nothing is resumed while another call outside is still active`() {
        val (a, b) = room()
        a.setOnHold()
        val outside = call("C").apply { setActive() }
        call("D").apply { setActive() }

        outside.onHold()
        settle()

        assertEquals(Connection.STATE_HOLDING, a.state)
        assertEquals(Connection.STATE_HOLDING, b.state)
    }

    @Test
    fun `a call outside goes active at once when no member is active`() {
        val (a, _) = room()
        a.setOnHold()
        val outside =
            call("C").apply {
                setActive()
                setOnHold()
            }

        outside.onUnhold()

        assertEquals(Connection.STATE_ACTIVE, outside.state)
    }

    @Test
    fun `a call held again while it waited to go active stays held and the group comes back`() {
        val (a, _) = room()
        val outside =
            call("C").apply {
                setActive()
                setOnHold()
            }
        settle()
        assertEquals("the hold of C gave the place to a member", Connection.STATE_ACTIVE, a.state)

        outside.onUnhold()
        assertEquals("the resume is waiting for the focus", Connection.STATE_HOLDING, outside.state)
        outside.onHold()
        settle()
        settle()

        assertEquals("the last command was a hold", Connection.STATE_HOLDING, outside.state)
        assertEquals("and the group has the place again", Connection.STATE_ACTIVE, a.state)
    }

    @Test
    fun `a call ended while it waited to go active gives the place back`() {
        val (a, _) = room()
        val outside =
            call("C").apply {
                setActive()
                setOnHold()
            }
        settle()

        outside.onUnhold()
        outside.setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
        settle()
        settle()

        assertEquals(Connection.STATE_ACTIVE, a.state)
    }
}
