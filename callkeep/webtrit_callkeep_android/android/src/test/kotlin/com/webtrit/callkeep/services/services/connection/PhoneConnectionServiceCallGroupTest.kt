package com.webtrit.callkeep.services.services.connection

import android.content.Intent
import android.os.Build
import com.webtrit.callkeep.common.CallDataConst
import com.webtrit.callkeep.models.CallMetadata
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class PhoneConnectionServiceCallGroupTest {
    private lateinit var service: PhoneConnectionService
    private lateinit var calls: Map<String, PhoneConnection>

    @Before
    fun setUp() {
        ConnectionManager.instance = ConnectionManager()
        service = Robolectric.buildService(PhoneConnectionService::class.java).create().get()
        calls =
            listOf("A", "B", "C", "D").associateWith { id ->
                PhoneConnection(service, { _, _ -> }, CallMetadata(callId = id), {}).also {
                    it.setActive()
                    ConnectionManager.instance.addConnection(id, it)
                }
            }
    }

    private fun initialGroup(vararg ids: String) {
        PhoneConnectionService.applyCallGroup(ids.toSet())
    }

    private fun declare(vararg ids: String) = send(ServiceAction.SetCallGroup, *ids)

    private fun withdraw(vararg ids: String) = send(ServiceAction.UnsetCallGroup, *ids)

    private fun send(
        action: ServiceAction,
        vararg ids: String,
    ) {
        service.onStartCommand(
            Intent(service, PhoneConnectionService::class.java).apply {
                this.action = action.action
                putExtra(CallDataConst.CALL_IDS, ids)
            },
            0,
            1,
        )
    }

    private fun grouped(): Set<String> = calls.filterValues { it.isGrouped }.keys

    @Test
    fun `Telecom declaring one member of three dissolves the group`() {
        initialGroup("A", "B", "C")
        declare("A")
        assertEquals("A membership of one is no group for anyone in it", emptySet<String>(), grouped())
    }

    @Test
    fun `restating the group adds the listed and removes the omitted`() {
        initialGroup("A", "B", "C")
        declare("A", "B", "D")
        assertEquals(setOf("A", "B", "D"), grouped())
    }

    @Test
    fun `Telecom disjoint replacement removes the previous group`() {
        initialGroup("A", "B")
        declare("C", "D")
        assertEquals(setOf("C", "D"), grouped())
    }

    @Test
    fun `an empty membership changes nothing`() {
        initialGroup("A", "B")
        declare()
        assertEquals(setOf("A", "B"), grouped())
    }

    @Test
    fun `withdrawing one of three keeps the rest grouped`() {
        initialGroup("A", "B", "C")
        withdraw("C")
        assertEquals(setOf("A", "B"), grouped())
    }

    @Test
    fun `withdrawing all but one takes the group apart`() {
        initialGroup("A", "B", "C")
        withdraw("B", "C")
        assertEquals(emptySet<String>(), grouped())
    }

    @Test
    fun `a held call leaving the group stays held while another call is active`() {
        initialGroup("A", "B")
        // What the sequencer does to a member: the hold is answered and goes no further, so
        // Telecom holds a call the application still believes is speaking.
        calls.getValue("B").onHold()
        withdraw("A", "B")
        assertEquals(
            "Taking it off hold while another call is active makes Telecom disconnect it",
            android.telecom.Connection.STATE_HOLDING,
            calls.getValue("B").state,
        )
    }

    @Test
    fun `the survivor of a group is left as Telecom holds it`() {
        listOf("C", "D").forEach { calls.getValue(it).setDisconnected(localCause()) }
        initialGroup("A", "B")
        calls.getValue("B").onHold()
        calls.getValue("A").setDisconnected(localCause())
        assertFalse("The group is over", calls.getValue("B").isGrouped)
        assertEquals(
            "A call whose connection has just ended is still active for Telecom, and taking the " +
                "survivor off hold in that window makes Telecom disconnect it",
            android.telecom.Connection.STATE_HOLDING,
            calls.getValue("B").state,
        )
    }

    @Test
    fun `an ended member leaves the group and a lone survivor is no group`() {
        initialGroup("A", "B", "C")
        calls.getValue("C").setDisconnected(localCause())
        assertEquals(setOf("A", "B"), grouped())
        calls.getValue("B").setDisconnected(localCause())
        assertFalse("One call left is not a group", calls.getValue("A").isGrouped)
    }

    private fun localCause() = android.telecom.DisconnectCause(android.telecom.DisconnectCause.LOCAL)

    @Test
    fun `Telecom is never told about the group`() {
        initialGroup("A", "B")
        // A self-managed application cannot have a self-managed Conference: Telecom masks the
        // property off anything it did not mark itself, so a conference would be filed as a
        // managed call and the platform dialer would draw the room.
        assertTrue(calls.values.all { it.conference == null })
    }

    @Test
    fun `duplicate ids cannot keep a lone member grouped`() {
        initialGroup("A", "B")
        declare("A", "A")
        assertEquals(emptySet<String>(), grouped())
    }

    @Test
    fun `unresolved declaration ends the current group`() {
        initialGroup("A", "B")
        declare("missing")
        assertEquals(emptySet<String>(), grouped())
    }
}
