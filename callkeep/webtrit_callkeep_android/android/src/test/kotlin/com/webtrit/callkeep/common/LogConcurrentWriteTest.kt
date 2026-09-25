package com.webtrit.callkeep.common

import android.os.Build
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLog
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Several threads of one process write to the native log file at the same moment - in
 * production the main Looper and the endpoint-change executor both log on every audio
 * route switch. Every line must reach the file, whole and with a well-formed timestamp.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.UPSIDE_DOWN_CAKE])
class LogConcurrentWriteTest {
    @get:Rule
    val folder = TemporaryFolder()

    private lateinit var logFile: File

    @Before
    fun setUp() {
        ShadowLog.clear()
        logFile = File(folder.root, "app_logs_native.log")
        Log.setLogFilePath(logFile.path)
    }

    @After
    fun tearDown() {
        Log.clearLogFilePath()
    }

    @Test
    fun `concurrent writers from one process lose no lines`() {
        val threads = 8
        val linesPerThread = 200
        val start = CountDownLatch(1)
        val pool = Executors.newFixedThreadPool(threads)
        repeat(threads) { t ->
            pool.execute {
                start.await()
                repeat(linesPerThread) { i -> Log.d(TAG, "t$t-$i") }
            }
        }
        start.countDown()
        pool.shutdown()
        assertTrue(pool.awaitTermination(30, TimeUnit.SECONDS))

        val lines = logFile.readLines()
        val expected = (0 until threads).flatMap { t -> (0 until linesPerThread).map { "t$t-$it" } }.toSet()
        val writeFailures = ShadowLog.getLogsForTag("WebtritCallkeep").filter { it.msg.startsWith("writeToFile failed") }
        val missing = expected - lines.map { it.substringAfter("$TAG: ") }.toSet()
        assertTrue(
            "${missing.size} of ${expected.size} lines lost, ${writeFailures.size} write failures, " +
                "first: ${writeFailures.firstOrNull()?.throwable}",
            missing.isEmpty() && writeFailures.isEmpty(),
        )
        assertEquals(threads * linesPerThread, lines.size)
        lines.forEach { assertTrue("malformed line: $it", LINE.matches(it)) }
    }

    private companion object {
        const val TAG = "LogConcurrentWriteTest"
        val LINE = Regex("""\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3} D $TAG: t\d+-\d+""")
    }
}
