package com.webtrit.callkeep.services.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class MainProcessConnectionTrackerGroupTest {
    private val tracker = MainProcessConnectionTracker()

    @Test
    fun `two calls form a group and a third grows it`() {
        tracker.declareGroup("room", listOf("a", "b"))
        tracker.declareGroup("room", listOf("a", "b", "c"))
        assertEquals(listOf("a", "b", "c"), tracker.groupMembersWith("c"))
    }

    @Test
    fun `a call that ends leaves its group and a lone member is no group`() {
        // Termination is the one end path: every way a call ends lands in markTerminated.
        tracker.declareGroup("room", listOf("a", "b", "c"))
        tracker.markTerminated("c")
        assertEquals(listOf("a", "b"), tracker.groupMembersWith("a"))
        tracker.markTerminated("b")
        assertFalse(tracker.isGrouped("a"))
    }

    @Test
    fun `one call named as the whole membership takes the group apart for everyone`() {
        tracker.declareGroup("room", listOf("a", "b", "c"))
        tracker.declareGroup("room", listOf("a"))
        assertFalse(tracker.isGrouped("a"))
        assertFalse(tracker.isGrouped("b"))
        assertFalse(tracker.isGrouped("c"))
    }

    @Test
    fun `release takes the named calls out and keeps the rest grouped`() {
        tracker.declareGroup("room", listOf("a", "b", "c"))
        tracker.releaseFromGroup(listOf("c"))
        assertTrue(tracker.isGrouped("a"))
        assertFalse(tracker.isGrouped("c"))
        assertEquals(listOf("a", "b"), tracker.groupMembersWith("b"))
    }

    @Test
    fun `there is one group at a time`() {
        tracker.declareGroup("room", listOf("a", "b"))
        tracker.declareGroup("room", listOf("c", "d"))
        assertFalse(tracker.isGrouped("a"))
        assertEquals(listOf("c", "d"), tracker.groupMembersWith("c"))
    }

    @Test
    fun `an empty membership changes nothing`() {
        tracker.declareGroup("room", listOf("a", "b"))
        tracker.declareGroup("room", emptyList())
        assertTrue(tracker.isGrouped("a"))
    }

    @Test
    fun `the live group keeps its name until it falls apart`() {
        tracker.declareGroup("room", listOf("a", "b"))
        assertEquals("room", tracker.currentGroupId())
        tracker.markTerminated("a")
        assertNull(tracker.currentGroupId())
        tracker.declareGroup("other", listOf("b", "c"))
        assertEquals("other", tracker.currentGroupId())
    }

    @Test
    fun `the session clear takes the groups with it`() {
        tracker.declareGroup("room", listOf("a", "b"))
        tracker.clear()
        assertFalse(tracker.isGrouped("a"))
        assertNull(tracker.currentGroupId())
    }
}
