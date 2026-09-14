package com.webtrit.callkeep.notifications

import android.os.Build
import com.webtrit.callkeep.models.CallMetadata
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Unit tests for the name shown by the standalone ongoing-call notification.
 *
 * There is a single notification id on the standalone path, so a group of calls has to be one
 * entry naming everyone in it rather than one entry per call, each overwriting the last.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class StandaloneActiveCallNotificationNameTest {
    private val unknown = "Unknown caller"

    // CallMetadata.name is derived: the display name, falling back to the number, null when
    // neither is known.
    private fun call(
        callId: String,
        name: String?,
    ) = CallMetadata(callId = callId, displayName = name)

    @Test
    fun `an ungrouped call shows its own caller`() {
        val result =
            StandaloneActiveCallNotificationBuilder.notificationName(
                call = call("A", "Alice"),
                groupMembers = emptyList(),
                unknownCaller = unknown,
            )
        assertEquals("Alice", result)
    }

    @Test
    fun `a caller with no name falls back to the unknown label`() {
        val result =
            StandaloneActiveCallNotificationBuilder.notificationName(
                call = call("A", null),
                groupMembers = emptyList(),
                unknownCaller = unknown,
            )
        assertEquals(unknown, result)
    }

    @Test
    fun `a group names everyone in it`() {
        val result =
            StandaloneActiveCallNotificationBuilder.notificationName(
                call = call("A", "Alice"),
                groupMembers = listOf(call("A", "Alice"), call("B", "Bob"), call("C", "Carol")),
                unknownCaller = unknown,
            )
        assertEquals("Alice, Bob, Carol", result)
    }

    @Test
    fun `a nameless member of a group still appears`() {
        val result =
            StandaloneActiveCallNotificationBuilder.notificationName(
                call = call("A", "Alice"),
                groupMembers = listOf(call("A", "Alice"), call("B", null)),
                unknownCaller = unknown,
            )
        assertEquals("Alice, $unknown", result)
    }

    @Test
    fun `a membership of one is not a group`() {
        // The same two-member floor the service applies when assigning calls to groups.
        val result =
            StandaloneActiveCallNotificationBuilder.notificationName(
                call = call("A", "Alice"),
                groupMembers = listOf(call("B", "Bob")),
                unknownCaller = unknown,
            )
        assertEquals("Alice", result)
    }
}
