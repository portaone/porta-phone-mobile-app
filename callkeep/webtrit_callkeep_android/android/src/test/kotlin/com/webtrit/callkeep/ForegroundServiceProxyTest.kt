package com.webtrit.callkeep

import android.os.Build
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.ArgumentMatchers.any
import org.mockito.Mockito.doAnswer
import org.mockito.Mockito.mock
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLog
import java.nio.ByteBuffer

/**
 * setUp() through the real pigeon handler, which runs the call on the main looper one step
 * after the message arrives. The activity may detach in that step, or while setUp() waits for
 * the service to bind; Dart must then get an error, never a success from a service the
 * activity no longer holds.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class ForegroundServiceProxyTest {
    private class FakeService : PHostApi {
        val setUps = mutableListOf<POptions>()

        override fun isSetUp(): Boolean = setUps.isNotEmpty()

        override suspend fun setUp(options: POptions) {
            setUps.add(options)
        }

        override suspend fun tearDown() = Unit

        override suspend fun reportNewIncomingCall(
            callId: String,
            handle: PHandle,
            displayName: String?,
            hasVideo: Boolean,
        ): PIncomingCallError? = null

        override suspend fun reportConnectingOutgoingCall(callId: String) = Unit

        override suspend fun reportConnectedOutgoingCall(callId: String) = Unit

        override suspend fun reportUpdateCall(
            callId: String,
            handle: PHandle?,
            displayName: String?,
            hasVideo: Boolean?,
            proximityEnabled: Boolean?,
        ) = Unit

        override suspend fun reportEndCall(
            callId: String,
            displayName: String,
            reason: PEndCallReason,
        ) = Unit

        override suspend fun startCall(
            callId: String,
            handle: PHandle,
            displayNameOrContactIdentifier: String?,
            video: Boolean,
            proximityEnabled: Boolean,
        ): PCallRequestError? = null

        override suspend fun answerCall(callId: String): PCallRequestError? = null

        override suspend fun endCall(callId: String): PCallRequestError? = null

        override suspend fun setHeld(
            callId: String,
            onHold: Boolean,
        ): PCallRequestError? = null

        override suspend fun setMuted(
            callId: String,
            muted: Boolean,
        ): PCallRequestError? = null

        override suspend fun setSpeaker(
            callId: String,
            enabled: Boolean,
        ): PCallRequestError? = null

        override suspend fun setAudioDevice(
            callId: String,
            device: PAudioDevice,
        ): PCallRequestError? = null

        override suspend fun sendDTMF(
            callId: String,
            key: String,
        ): PCallRequestError? = null

        override suspend fun setCallGroup(
            groupId: String,
            callIds: List<String>,
        ): PCallRequestError? = null

        override suspend fun unsetCallGroup(callIds: List<String>): PCallRequestError? = null

        override fun onDelegateSet() = Unit
    }

    private val handlers = mutableMapOf<String, BinaryMessenger.BinaryMessageHandler>()
    private lateinit var proxy: ForegroundServiceProxy
    private val options =
        POptions(
            ios =
                PIOSOptions(
                    localizedName = "test",
                    maximumCallGroups = 1,
                    maximumCallsPerCallGroup = 1,
                    supportsVideo = false,
                    includesCallsInRecents = false,
                    driveIdleTimerDisabled = false,
                ),
            android = PAndroidOptions(),
        )

    @Before
    fun setUp() {
        ShadowLog.stream = System.out
        val messenger = mock(BinaryMessenger::class.java)
        doAnswer { invocation ->
            val name = invocation.getArgument<String>(0)
            val handler = invocation.getArgument<BinaryMessenger.BinaryMessageHandler?>(1)
            if (handler == null) handlers.remove(name) else handlers[name] = handler
            null
        }.`when`(messenger).setMessageHandler(any(String::class.java), any())
        doAnswer { invocation ->
            val name = invocation.getArgument<String>(0)
            val handler = invocation.getArgument<BinaryMessenger.BinaryMessageHandler?>(1)
            if (handler == null) handlers.remove(name) else handlers[name] = handler
            null
        }.`when`(messenger).setMessageHandler(any(String::class.java), any(), any())
        proxy = ForegroundServiceProxy()
        PHostApi.setUp(messenger, proxy)
    }

    /** Send setUp(options) the way Dart does; the reply arrives once the main looper runs. */
    private fun sendSetUp(): () -> List<Any?>? {
        val handler = handlers.getValue("dev.flutter.pigeon.webtrit_callkeep_android.PHostApi.setUp")
        var reply: List<Any?>? = null
        val message = PHostApi.codec.encodeMessage(listOf(options))!!.also { it.rewind() }
        handler.onMessage(message) { bytes: ByteBuffer? ->
            bytes!!.rewind()
            @Suppress("UNCHECKED_CAST")
            reply = PHostApi.codec.decodeMessage(bytes) as List<Any?>
        }
        return { reply }
    }

    private fun runMainLooper() = shadowOf(Looper.getMainLooper()).idle()

    private fun assertError(reply: List<Any?>?) {
        assertTrue("expected an error reply, got $reply", reply != null && reply.size == 3)
        assertEquals("IllegalStateException", reply!![0])
    }

    @Test
    fun `setUp after the service bound reaches it`() {
        val service = FakeService()
        proxy.connected(service)
        val reply = sendSetUp()
        runMainLooper()
        assertEquals(listOf(null), reply())
        assertEquals(listOf(options), service.setUps)
    }

    @Test
    fun `setUp before the service binds waits for it`() {
        val service = FakeService()
        val reply = sendSetUp()
        runMainLooper()
        assertNull("must still be waiting", reply())
        proxy.connected(service)
        runMainLooper()
        assertEquals(listOf(null), reply())
        assertEquals(listOf(options), service.setUps)
    }

    @Test
    fun `setUp that arrives after a detach fails`() {
        // The service bound and the activity detached before the call was dispatched: the
        // deferred completed earlier must not hand the old service to a late call.
        val service = FakeService()
        proxy.connected(service)
        proxy.disconnected()
        val reply = sendSetUp()
        runMainLooper()
        assertError(reply())
        assertTrue(service.setUps.isEmpty())
    }

    @Test
    fun `setUp dispatched after a detach fails`() {
        // The message arrived while bound; the looper step that runs it came after the detach.
        val service = FakeService()
        proxy.connected(service)
        val reply = sendSetUp()
        proxy.disconnected()
        runMainLooper()
        assertError(reply())
        assertTrue(service.setUps.isEmpty())
    }

    @Test
    fun `setUp waiting for the service fails when the activity detaches first`() {
        val reply = sendSetUp()
        runMainLooper()
        assertNull(reply())
        proxy.disconnected()
        runMainLooper()
        assertError(reply())
    }

    @Test
    fun `setUp during a rebind waits for the new service`() {
        // The activity detached and attached again; the bind is in flight when setUp arrives.
        val first = FakeService()
        proxy.connected(first)
        proxy.disconnected()
        proxy.binding()
        val reply = sendSetUp()
        runMainLooper()
        assertNull("must wait for the new service, not fail on the old detach", reply())
        val second = FakeService()
        proxy.connected(second)
        runMainLooper()
        assertEquals(listOf(null), reply())
        assertTrue(first.setUps.isEmpty())
        assertEquals(listOf(options), second.setUps)
    }

    @Test
    fun `setUp during a rebind fails when the activity detaches again first`() {
        proxy.connected(FakeService())
        proxy.disconnected()
        proxy.binding()
        val reply = sendSetUp()
        runMainLooper()
        assertNull(reply())
        proxy.disconnected()
        runMainLooper()
        assertError(reply())
    }

    @Test
    fun `a rebind after a detach serves the next setUp`() {
        val first = FakeService()
        proxy.connected(first)
        proxy.disconnected()
        val second = FakeService()
        proxy.connected(second)
        val reply = sendSetUp()
        runMainLooper()
        assertEquals(listOf(null), reply())
        assertTrue(first.setUps.isEmpty())
        assertEquals(listOf(options), second.setUps)
    }
}
