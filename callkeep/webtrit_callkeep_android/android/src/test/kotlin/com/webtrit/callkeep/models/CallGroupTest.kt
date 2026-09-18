package com.webtrit.callkeep.models

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Shared membership contract, exercised without an Android service. */
class CallGroupTest {
    private var sequence = 0
    private val nextId: () -> String = { "group-${++sequence}" }

    private fun CallGroup.groupOf(callId: String): String? = id.takeIf { callId in this }

    @Test
    fun `grouping two calls puts both in one new group`() {
        val result = CallGroup.empty.declare(listOf("A", "B"), nextId)

        assertEquals(setOf("A", "B"), result.members)
        assertEquals(result.groupOf("A"), result.groupOf("B"))
    }

    @Test
    fun `adding a third call reuses the group rather than making a new one`() {
        val first = CallGroup.empty.declare(listOf("A", "B"), nextId)

        val result = first.declare(listOf("A", "B", "C"), nextId)

        assertEquals(setOf("A", "B", "C"), result.members)
        assertEquals(first.id, result.id)
        assertEquals(first.groupOf("A"), result.groupOf("C"))
    }

    @Test
    fun `restating the same membership changes nothing`() {
        val first = CallGroup.empty.declare(listOf("A", "B"), nextId)

        val result = first.declare(listOf("A", "B"), nextId)

        assertEquals(first, result)
    }

    @Test
    fun `a member left off the list leaves the group`() {
        // The request is the whole membership, so C dropping off the list takes it out, and the
        // two that remain keep the group.
        val first = CallGroup.empty.declare(listOf("A", "B", "C"), nextId)

        val result = first.declare(listOf("A", "B"), nextId)

        assertEquals(setOf("A", "B"), result.members)
        assertEquals(first.groupOf("A"), result.groupOf("B"))
    }

    @Test
    fun `naming a single call takes its group apart`() {
        // One call cannot be a group, so saying A is the whole membership leaves nobody grouped.
        val first = CallGroup.empty.declare(listOf("A", "B"), nextId)

        val result = first.declare(listOf("A"), nextId)

        assertTrue(result.isEmpty)
    }

    @Test
    fun `an empty membership names no group and changes nothing`() {
        val first = CallGroup.empty.declare(listOf("A", "B"), nextId)

        val result = first.declare(emptyList(), nextId)

        assertEquals(first, result)
    }

    @Test
    fun `there is one group at a time - declaring another replaces it`() {
        val first = CallGroup.empty.declare(listOf("A", "B"), nextId)

        val result = first.declare(listOf("C", "D"), nextId)

        assertEquals(setOf("C", "D"), result.members)
        assertEquals(result.groupOf("C"), result.groupOf("D"))
        org.junit.Assert.assertNotEquals(first.id, result.id)
    }

    @Test
    fun `a member left off the list leaves, whatever it was grouped with`() {
        val three = CallGroup.empty.declare(listOf("A", "B", "C"), nextId)

        val result = three.declare(listOf("A", "C"), nextId)

        assertEquals(setOf("A", "C"), result.members)
        assertEquals(three.groupOf("A"), result.groupOf("A"))
    }

    @Test
    fun `ungrouping one of three leaves the other two grouped`() {
        val first = CallGroup.empty.declare(listOf("A", "B", "C"), nextId)

        val result = first.without(listOf("C"))

        assertEquals(setOf("A", "B"), result.members)
        assertEquals(first.groupOf("A"), result.groupOf("B"))
    }

    @Test
    fun `ungrouping one of two takes the whole group apart`() {
        // B would be left alone, and one call is not a group.
        val first = CallGroup.empty.declare(listOf("A", "B"), nextId)

        val result = first.without(listOf("A"))

        assertTrue(result.isEmpty)
    }

    @Test
    fun `ungrouping every member takes the group apart`() {
        val first = CallGroup.empty.declare(listOf("A", "B", "C"), nextId)

        val result = first.without(listOf("A", "B", "C"))

        assertTrue(result.isEmpty)
    }

    @Test
    fun `ungrouping an empty list does nothing`() {
        // The guard that stops a caller computing an empty list from dissolving a group.
        val first = CallGroup.empty.declare(listOf("A", "B"), nextId)

        val result = first.without(emptyList())

        assertEquals(first, result)
    }

    @Test
    fun `ungrouping a call that is in no group changes nothing`() {
        val first = CallGroup.empty.declare(listOf("A", "B"), nextId)

        val result = first.without(listOf("Z"))

        assertEquals(first, result)
    }

    @Test
    fun `ungrouping calls outside the group changes nothing`() {
        val two = CallGroup.empty.declare(listOf("A", "B"), nextId)

        val result = two.without(listOf("C", "D"))

        assertEquals(setOf("A", "B"), result.members)
    }

    @Test
    fun `the input assignment is never mutated`() {
        val first = CallGroup.empty.declare(listOf("A", "B"), nextId)
        val snapshot = first

        first.declare(listOf("A", "B", "C"), nextId)
        first.without(listOf("A"))

        assertEquals(snapshot, first)
    }

    @Test
    fun `duplicate ids do not form a group`() {
        assertTrue(CallGroup.empty.declare(listOf("A", "A"), nextId).isEmpty)
    }

    @Test
    fun `caller cannot mutate a group through its input or output set`() {
        val input = mutableSetOf("A", "B")
        val group = CallGroup.of("room", input)
        input.clear()
        assertEquals(setOf("A", "B"), group.members)
        org.junit.Assert.assertThrows(UnsupportedOperationException::class.java) {
            (group.members as MutableSet<String>).clear()
        }
    }

    @Test
    fun `a disconnected member and explicit removal use the same dissolution rule`() {
        val group = CallGroup.empty.declare(listOf("A", "B", "C"), nextId)
        val two = group.without(listOf("C"))
        assertEquals(setOf("A", "B"), two.members)
        assertTrue(two.without(listOf("B")).isEmpty)
    }
}
