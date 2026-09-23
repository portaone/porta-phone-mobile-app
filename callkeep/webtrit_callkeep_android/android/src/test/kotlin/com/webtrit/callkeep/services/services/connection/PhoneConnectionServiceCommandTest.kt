package com.webtrit.callkeep.services.services.connection

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.services.broadcaster.CallCommandEvent
import com.webtrit.callkeep.services.core.CallkeepCore
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * A command the system refuses to start is lost, and the one loss that leaves a caller waiting
 * has to be paid for by the sender: [ForegroundService.tearDown] blocks on
 * [CallCommandEvent.TearDownComplete] until its timeout, so a refused
 * [ServiceAction.TearDownConnections] must produce that ack itself. No other refused command
 * may produce it - an ack for a teardown that was never asked for would end a session early.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class PhoneConnectionServiceCommandTest {
    private lateinit var app: Context
    private val acks = mutableListOf<String?>()
    private val ackReceiver =
        object : BroadcastReceiver() {
            override fun onReceive(
                context: Context?,
                intent: Intent?,
            ) {
                acks += intent?.action
            }
        }

    /** A context on which every service start is refused, the way a background-start restriction refuses it. */
    private val refusing =
        object : ContextWrapper(ApplicationProvider.getApplicationContext<Context>()) {
            override fun startService(service: Intent): ComponentName? = throw IllegalStateException("Not allowed to start service ${service.action}")
        }

    @Before
    fun prepare() {
        app = ApplicationProvider.getApplicationContext()
        ContextHolder.init(app)
        CallkeepCore.instance.registerConnectionEvents(app, listOf(CallCommandEvent.TearDownComplete), ackReceiver)
    }

    @After
    fun tearDown() {
        CallkeepCore.instance.unregisterConnectionEvents(app, ackReceiver)
        CallkeepCore.instance.clear()
    }

    @Test
    fun `a refused TearDownConnections acks itself`() {
        PhoneConnectionService.sendTearDownConnections(refusing)

        assertEquals(listOf(CallCommandEvent.TearDownComplete.name), acks)
    }

    @Test
    fun `no other refused command acks a teardown`() {
        PhoneConnectionService.tearDown(refusing)
        PhoneConnectionService.sendReserveAnswer(refusing, "call-1")
        PhoneConnectionService.sendCleanConnections(refusing)
        PhoneConnectionService.replayAudioState(refusing)
        PhoneConnectionService.replayConnectionStates(refusing)
        PhoneConnectionService.startCallGroup(refusing, ServiceAction.SetCallGroup, listOf("call-1", "call-2"))

        assertEquals(emptyList<String?>(), acks)
    }
}
