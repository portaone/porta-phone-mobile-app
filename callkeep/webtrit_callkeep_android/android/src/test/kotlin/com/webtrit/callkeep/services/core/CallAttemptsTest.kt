package com.webtrit.callkeep.services.core

import com.webtrit.callkeep.services.core.CallAttempts.Decision
import com.webtrit.callkeep.services.core.CallAttempts.OfferTime
import com.webtrit.callkeep.services.core.CallAttempts.OfferTimeSource
import com.webtrit.callkeep.services.core.CallAttempts.Via
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.long
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * [CallAttempts] on the shared cases of `callkeep/call_attempt_vectors.json`, which the iOS
 * registry runs as well, and the cases only this implementation has (limits, a second end).
 */
class CallAttemptsTest {
    private var clock = 0L
    private var nextId = 0

    private fun attempts(limit: Int = CallAttempts.ENDED_LIMIT) = CallAttempts(now = { clock }, newInstanceId = { "i${++nextId}" }, endedLimit = limit)

    @Test
    fun `every shared case gives the decisions it names`() {
        val file = vectorsFile()
        val cases = Json.parseToJsonElement(file.readText()).jsonObject["cases"]!!.jsonArray
        assertTrue("no cases in $file", cases.isNotEmpty())
        for (case in cases) runCase(case.jsonObject)
    }

    private fun runCase(case: JsonObject) {
        val name = case["name"]!!.jsonPrimitive.content
        clock = 0L
        val registry = attempts()
        val named = HashMap<String, String>()
        for ((index, element) in case["steps"]!!.jsonArray.withIndex()) {
            val step = element.jsonObject
            val at = step["at"]?.jsonPrimitive?.long
            val where = "$name, step ${index + 1}"
            when (val op = step["op"]!!.jsonPrimitive.content) {
                "clock" -> {
                    clock = at!!
                }

                "end" -> {
                    clock = maxOf(clock, at!!)
                    val id = named.getValue(step["attempt"]!!.jsonPrimitive.content)
                    registry.end(id, at)
                }

                "offer" -> {
                    val from = step["from"]?.jsonPrimitive?.content
                    val offeredAt = if (at != null && from != null) OfferTime(at, source(from)) else null
                    val decision = registry.resolve(step["callId"]!!.jsonPrimitive.content, offeredAt, via(step["via"]!!.jsonPrimitive.content))
                    assertEquals(where, step["expect"]!!.jsonPrimitive.content, kind(decision))
                    step["as"]?.jsonPrimitive?.content?.let { label ->
                        assertTrue("$where: '$label' names an existing attempt", label !in named)
                        assertTrue("$where: a new attempt gets a new instance id", decision.attempt.instanceId !in named.values)
                        named[label] = decision.attempt.instanceId
                    }
                    step["of"]?.jsonPrimitive?.content?.let { label ->
                        assertEquals("$where: the attempt '$label'", named.getValue(label), decision.attempt.instanceId)
                    }
                }

                else -> {
                    error("$where: unknown op $op")
                }
            }
        }
    }

    @Test
    fun `an ended attempt over the limit is forgotten, the newest kept`() {
        val registry = attempts(limit = 2)
        val ids = (1..3).map { n -> registry.resolve("C$n", OfferTime(n.toLong(), OfferTimeSource.CORE), Via.SOCKET).attempt.instanceId }
        ids.forEach { registry.end(it, 10) }

        assertNull(registry.get(ids[0]))
        assertTrue(registry.resolve("C1", OfferTime(1, OfferTimeSource.CORE), Via.PUSH) is Decision.New)
        assertTrue(registry.resolve("C3", OfferTime(3, OfferTimeSource.CORE), Via.PUSH) is Decision.Ghost)
    }

    @Test
    fun `a second end of an attempt changes nothing, and does not end a newer attempt of the id`() {
        val registry = attempts()
        val first = registry.resolve("X", OfferTime(1000, OfferTimeSource.CORE), Via.SOCKET).attempt
        registry.end(first.instanceId, 2000)
        val second = registry.resolve("X", OfferTime(3000, OfferTimeSource.CORE), Via.PUSH).attempt

        registry.end(first.instanceId, 4000)

        assertEquals(2000L, registry.get(first.instanceId)!!.endedAtMs)
        assertEquals(second, registry.liveFor("X"))
        assertNotEquals(first.instanceId, second.instanceId)
    }

    @Test
    fun `the ended attempt a later end of the call id supersedes is forgotten`() {
        val registry = attempts()
        val first = registry.resolve("X", OfferTime(1000, OfferTimeSource.CORE), Via.SOCKET).attempt
        registry.end(first.instanceId, 2000)
        val second = registry.resolve("X", OfferTime(3000, OfferTimeSource.CORE), Via.SOCKET).attempt
        registry.end(second.instanceId, 4000)

        assertNull(registry.get(first.instanceId))
        assertEquals(4000L, registry.get(second.instanceId)!!.endedAtMs)
    }

    @Test
    fun `clear forgets every attempt`() {
        val registry = attempts()
        val attempt = registry.resolve("X", OfferTime(1000, OfferTimeSource.CORE), Via.SOCKET).attempt
        registry.end(attempt.instanceId, 2000)

        registry.clear()

        assertNull(registry.get(attempt.instanceId))
        assertTrue(registry.resolve("X", OfferTime(1000, OfferTimeSource.CORE), Via.PUSH) is Decision.New)
    }

    private fun vectorsFile(): File {
        // Gradle runs the unit tests in the module directory (callkeep/webtrit_callkeep_android/android).
        var dir: File? = File("").absoluteFile
        while (dir != null) {
            val candidate = File(dir, "call_attempt_vectors.json")
            if (candidate.isFile) return candidate
            dir = dir.parentFile
        }
        error("call_attempt_vectors.json not found above ${File("").absolutePath}")
    }

    private fun source(name: String) =
        when (name) {
            "core" -> OfferTimeSource.CORE
            "fcm" -> OfferTimeSource.FCM
            "device" -> OfferTimeSource.DEVICE
            else -> error("unknown source $name")
        }

    private fun via(name: String) =
        when (name) {
            "socket" -> Via.SOCKET
            "push" -> Via.PUSH
            "handshake" -> Via.HANDSHAKE
            else -> Via.OTHER
        }

    private fun kind(decision: Decision) =
        when (decision) {
            is Decision.Same -> "same"
            is Decision.New -> "new"
            is Decision.Ghost -> "ghost"
            is Decision.Unconfirmed -> "unconfirmed"
        }
}
