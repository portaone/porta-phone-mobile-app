package com.webtrit.callkeep.services.services.connection

import android.os.Build
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * Unit tests for the group reconciliation in [StandaloneCallService], which turns a declared
 * membership into an assignment of calls to groups.
 *
 * The standalone backend has no Telecom conference to hold that structure, so it keeps the
 * assignment itself. Both functions are pure, so the rules that matter - a declared membership is
 * exact, and a group needs two calls - are tested without a service.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class StandaloneCallServiceCallGroupTest {
    private var sequence = 0
    private val nextId: () -> String = { "group-${++sequence}" }

    private fun Map<String, String>.groupOf(callId: String): String? = this[callId]

    @Test
    fun `grouping two calls puts both in one new group`() {
        val result = StandaloneCallService.withCallGroup(emptyMap(), listOf("A", "B"), nextId)

        assertEquals(setOf("A", "B"), result.keys)
        assertEquals(result.groupOf("A"), result.groupOf("B"))
    }

    @Test
    fun `adding a third call reuses the group rather than making a new one`() {
        val first = StandaloneCallService.withCallGroup(emptyMap(), listOf("A", "B"), nextId)

        val result = StandaloneCallService.withCallGroup(first, listOf("A", "B", "C"), nextId)

        assertEquals(setOf("A", "B", "C"), result.keys)
        assertEquals(1, result.values.toSet().size)
        assertEquals(first.groupOf("A"), result.groupOf("C"))
    }

    @Test
    fun `restating the same membership changes nothing`() {
        val first = StandaloneCallService.withCallGroup(emptyMap(), listOf("A", "B"), nextId)

        val result = StandaloneCallService.withCallGroup(first, listOf("A", "B"), nextId)

        assertEquals(first, result)
    }

    @Test
    fun `a member left off the list leaves the group`() {
        // The request is the whole membership, so C dropping off the list takes it out, and the
        // two that remain keep the group.
        val first = StandaloneCallService.withCallGroup(emptyMap(), listOf("A", "B", "C"), nextId)

        val result = StandaloneCallService.withCallGroup(first, listOf("A", "B"), nextId)

        assertEquals(setOf("A", "B"), result.keys)
        assertEquals(first.groupOf("A"), result.groupOf("B"))
    }

    @Test
    fun `naming a single call takes its group apart`() {
        // One call cannot be a group, so saying A is the whole membership leaves nobody grouped.
        val first = StandaloneCallService.withCallGroup(emptyMap(), listOf("A", "B"), nextId)

        val result = StandaloneCallService.withCallGroup(first, listOf("A"), nextId)

        assertTrue(result.isEmpty())
    }

    @Test
    fun `an empty membership names no group and changes nothing`() {
        val first = StandaloneCallService.withCallGroup(emptyMap(), listOf("A", "B"), nextId)

        val result = StandaloneCallService.withCallGroup(first, emptyList(), nextId)

        assertEquals(first, result)
    }

    @Test
    fun `there is one group at a time - declaring another replaces it`() {
        val first = StandaloneCallService.withCallGroup(emptyMap(), listOf("A", "B"), nextId)

        val result = StandaloneCallService.withCallGroup(first, listOf("C", "D"), nextId)

        assertEquals(setOf("C", "D"), result.keys)
        assertEquals(1, result.values.toSet().size)
    }

    @Test
    fun `a member left off the list leaves, whatever it was grouped with`() {
        val three = StandaloneCallService.withCallGroup(emptyMap(), listOf("A", "B", "C"), nextId)

        val result = StandaloneCallService.withCallGroup(three, listOf("A", "C"), nextId)

        assertEquals(setOf("A", "C"), result.keys)
        assertEquals(three.groupOf("A"), result.groupOf("A"))
    }

    @Test
    fun `ungrouping one of three leaves the other two grouped`() {
        val first = StandaloneCallService.withCallGroup(emptyMap(), listOf("A", "B", "C"), nextId)

        val result = StandaloneCallService.withoutCallGroup(first, listOf("C"))

        assertEquals(setOf("A", "B"), result.keys)
        assertEquals(first.groupOf("A"), result.groupOf("B"))
    }

    @Test
    fun `ungrouping one of two takes the whole group apart`() {
        // B would be left alone, and one call is not a group.
        val first = StandaloneCallService.withCallGroup(emptyMap(), listOf("A", "B"), nextId)

        val result = StandaloneCallService.withoutCallGroup(first, listOf("A"))

        assertTrue(result.isEmpty())
    }

    @Test
    fun `ungrouping every member takes the group apart`() {
        val first = StandaloneCallService.withCallGroup(emptyMap(), listOf("A", "B", "C"), nextId)

        val result = StandaloneCallService.withoutCallGroup(first, listOf("A", "B", "C"))

        assertTrue(result.isEmpty())
    }

    @Test
    fun `ungrouping an empty list does nothing`() {
        // The guard that stops a caller computing an empty list from dissolving a group.
        val first = StandaloneCallService.withCallGroup(emptyMap(), listOf("A", "B"), nextId)

        val result = StandaloneCallService.withoutCallGroup(first, emptyList())

        assertEquals(first, result)
    }

    @Test
    fun `ungrouping a call that is in no group changes nothing`() {
        val first = StandaloneCallService.withCallGroup(emptyMap(), listOf("A", "B"), nextId)

        val result = StandaloneCallService.withoutCallGroup(first, listOf("Z"))

        assertEquals(first, result)
    }

    @Test
    fun `ungrouping calls outside the group changes nothing`() {
        val two = StandaloneCallService.withCallGroup(emptyMap(), listOf("A", "B"), nextId)

        val result = StandaloneCallService.withoutCallGroup(two, listOf("C", "D"))

        assertEquals(setOf("A", "B"), result.keys)
    }

    @Test
    fun `the input assignment is never mutated`() {
        val first = StandaloneCallService.withCallGroup(emptyMap(), listOf("A", "B"), nextId)
        val snapshot = first.toMap()

        StandaloneCallService.withCallGroup(first, listOf("A", "B", "C"), nextId)
        StandaloneCallService.withoutCallGroup(first, listOf("A"))

        assertEquals(snapshot, first)
    }
}
