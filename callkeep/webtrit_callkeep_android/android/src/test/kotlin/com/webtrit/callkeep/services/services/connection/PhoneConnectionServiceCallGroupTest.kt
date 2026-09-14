package com.webtrit.callkeep.services.services.connection

import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.telecom.PhoneAccountHandle
import com.webtrit.callkeep.common.CallDataConst
import com.webtrit.callkeep.models.CallMetadata
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
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
        PhoneConnectionService.connectionManager = ConnectionManager()
        service = Robolectric.buildService(PhoneConnectionService::class.java).create().get()
        calls =
            listOf("A", "B", "C", "D").associateWith { id ->
                PhoneConnection(service, { _, _ -> }, CallMetadata(callId = id), {}).also {
                    it.setActive()
                    PhoneConnectionService.connectionManager.addConnection(id, it)
                }
            }
    }

    private fun initialGroup(vararg ids: String): PhoneConference {
        val account = PhoneAccountHandle(ComponentName(service, PhoneConnectionService::class.java), "review")
        return PhoneConference(account).also { group -> ids.forEach { group.addConnection(calls.getValue(it)) } }
    }

    private fun declare(vararg ids: String) {
        service.onStartCommand(
            Intent(service, PhoneConnectionService::class.java).apply {
                action = ServiceAction.SetCallGroup.action
                putExtra(CallDataConst.CALL_IDS, ids)
            },
            0,
            1,
        )
    }

    @Test
    fun `Telecom declaring one member of three dissolves the conference`() {
        initialGroup("A", "B", "C")
        declare("A")
        assertNull("The named member must be removed by the handler", calls.getValue("A").conference)
        assertNull("B must stand alone", calls.getValue("B").conference)
        assertNull("C must stand alone", calls.getValue("C").conference)
    }

    @Test
    fun `restating the group adds the listed and removes the omitted`() {
        initialGroup("A", "B", "C")
        declare("A", "B", "D")
        val group = calls.getValue("A").conference
        assertNotNull(group)
        assertSame(group, calls.getValue("B").conference)
        assertSame(group, calls.getValue("D").conference)
        assertNull("C was omitted and must leave", calls.getValue("C").conference)
    }

    @Test
    fun `Telecom disjoint replacement removes the previous conference`() {
        initialGroup("A", "B")
        declare("C", "D")
        assertNotNull("The replacement group must actually be created", calls.getValue("C").conference)
        assertSame(calls.getValue("C").conference, calls.getValue("D").conference)
        assertNull("A was omitted and must leave", calls.getValue("A").conference)
        assertNull("B was omitted and must leave", calls.getValue("B").conference)
    }
}
