package com.webtrit.callkeep.services.core

import android.content.Context
import android.os.Build
import androidx.test.core.app.ApplicationProvider
import com.webtrit.callkeep.PCallkeepConnectionState
import com.webtrit.callkeep.common.ContextHolder
import com.webtrit.callkeep.models.CallMetadata
import com.webtrit.callkeep.services.services.connection.ConnectionManager
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.mock
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Unit tests for [InProcessCallkeepCore]: the [InProcessCallkeepCore.clearAndMarkEndCallDispatched]
 * composite (tracker + main-process ConnectionManager reservation + dispatch dedup) and answer
 * routing. Incoming registration, including its pending reservation, is covered by
 * [IncomingRegistrationTest].
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class InProcessCallkeepCoreTest {
    private lateinit var tracker: MainProcessConnectionTracker
    private lateinit var router: CallServiceRouter
    private lateinit var core: InProcessCallkeepCore

    private fun metadata(callId: String = "call-1") = CallMetadata(callId = callId)

    @Before
    fun setUp() {
        ContextHolder.init(ApplicationProvider.getApplicationContext<Context>())
        tracker = MainProcessConnectionTracker()
        router = mock(CallServiceRouter::class.java)
        core = InProcessCallkeepCore(tracker = tracker, routerInit = { router })
    }

    // ----------------------------------------------------------------------
    // clearAndMarkEndCallDispatched (composite mutation)
    // ----------------------------------------------------------------------

    @Test
    fun `clearAndMarkEndCallDispatched — terminates, drops the CM reservation, dedups the dispatch`() {
        // The composite touches TWO objects: the tracker (markTerminated + endCallDispatched)
        // and the main-process ConnectionManager.instance, whose pendingCallIds
        // reservation (created by checkAndReservePending during startIncomingCall) must be
        // dropped from the main process — otherwise a blind transfer-back reusing the same
        // callId is permanently rejected as CALL_ID_ALREADY_EXISTS. This is the ONE sanctioned
        // main-process connectionManager touch (see docs/connection-tracker.md).
        //
        // Swap in a fresh ConnectionManager so the process-wide singleton state cannot leak
        // between tests.
        val cm = ConnectionManager()
        val previousCm = ConnectionManager.instance
        ConnectionManager.instance = cm
        try {
            // Full registration: CM reservation + tracker lifecycle up to a promoted call.
            assertNull(cm.checkAndReservePending("call-1"))
            tracker.addPending("call-1")
            tracker.promote("call-1", metadata(), PCallkeepConnectionState.STATE_RINGING)

            // First dispatch: returns true.
            assertTrue(core.clearAndMarkEndCallDispatched("call-1"))

            // Tracker side: fully terminated, no active record left.
            assertTrue(tracker.isTerminated("call-1"))
            assertFalse(tracker.exists("call-1"))
            assertFalse(tracker.isPending("call-1"))
            // CM side: the reservation is gone — the same callId can be reserved again
            // (transfer-back), instead of bouncing off CALL_ID_ALREADY_EXISTS.
            assertNull(cm.checkAndReservePending("call-1"))

            // Second dispatch for the same callId: already dispatched, returns false.
            assertFalse(core.clearAndMarkEndCallDispatched("call-1"))
        } finally {
            ConnectionManager.instance = previousCm
        }
    }

    // ----------------------------------------------------------------------
    // Answer routing in the dual-state window
    // ----------------------------------------------------------------------

    @Test
    fun `routeAnswerCall — registered-and-pending call routes to AnswerImmediately`() {
        // The push-path re-registration window: a promoted call becomes pending again
        // for the duration of the backend round-trip. exists wins over isPending, so
        // an answer during the window goes to the live connection, not the
        // deferred-answer path.
        tracker.promote("call-1", metadata(), PCallkeepConnectionState.STATE_RINGING)
        tracker.addPending("call-1")
        assertTrue(core.routeAnswerCall("call-1") is AnswerCallRoute.AnswerImmediately)
    }
}
