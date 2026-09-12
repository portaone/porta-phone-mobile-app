package com.webtrit.callkeep.common

import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import android.util.Log as AndroidLog

/**
 * Severity of a log line.
 *
 * Local to this file on purpose. The severity used to come from the generated pigeon
 * code, left over from a delegate API that relayed log lines to Dart; that API is gone
 * from the pigeon definition and from the Dart side, so it is plain Kotlin now.
 */
enum class LogType {
    DEBUG,
    INFO,
    WARN,
    ERROR,
    VERBOSE,
}

/**
 * A logging utility that can be instantiated with a specific tag or used statically.
 */
class Log(
    private val tag: String,
) {
    fun e(
        message: String,
        throwable: Throwable? = null,
    ) = log(LogType.ERROR, tag, message, throwable)

    fun d(message: String) = log(LogType.DEBUG, tag, message)

    fun i(message: String) = log(LogType.INFO, tag, message)

    fun v(message: String) = log(LogType.VERBOSE, tag, message)

    fun w(
        message: String,
        throwable: Throwable? = null,
    ) = log(LogType.WARN, tag, message, throwable)

    companion object {
        private const val GLOBAL_PREFIX = "WebtritCallkeep"

        private val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US)

        @Volatile
        private var logFilePath: String? = null

        fun setLogFilePath(path: String) {
            logFilePath = path
            AndroidLog.d(GLOBAL_PREFIX, "setLogFilePath: $path")
        }

        fun clearLogFilePath() {
            logFilePath = null
            AndroidLog.d(GLOBAL_PREFIX, "clearLogFilePath")
        }

        fun initFromContext(context: android.content.Context) {
            val path = StorageDelegate.Logging.getLogFilePath(context)
            AndroidLog.d(GLOBAL_PREFIX, "initFromContext: getLogFilePath=$path pid=${android.os.Process.myPid()}")
            if (path != null) {
                logFilePath = path
            }
        }

        private fun log(
            type: LogType,
            tag: String,
            message: String,
            throwable: Throwable? = null,
        ) {
            if (logFilePath != null) {
                writeToFile(type, tag, message, throwable)
            } else {
                // logFilePath not yet configured — fall back to logcat directly
                val prefixedTag = "$GLOBAL_PREFIX.$tag"
                when (type) {
                    LogType.DEBUG -> AndroidLog.d(prefixedTag, message, throwable)
                    LogType.INFO -> AndroidLog.i(prefixedTag, message, throwable)
                    LogType.WARN -> AndroidLog.w(prefixedTag, message, throwable)
                    LogType.ERROR -> AndroidLog.e(prefixedTag, message, throwable)
                    LogType.VERBOSE -> AndroidLog.v(prefixedTag, message, throwable)
                }
            }
        }

        private fun writeToFile(
            type: LogType,
            tag: String,
            message: String,
            throwable: Throwable?,
        ) {
            val path = logFilePath ?: return
            try {
                val logFile = File(path)
                val lockFile = File("$path.lock")
                val level =
                    when (type) {
                        LogType.DEBUG -> "D"
                        LogType.INFO -> "I"
                        LogType.WARN -> "W"
                        LogType.ERROR -> "E"
                        LogType.VERBOSE -> "V"
                    }
                val timestamp = dateFormat.format(Date())
                val line =
                    if (throwable != null) {
                        "$timestamp $level $tag: $message\n${AndroidLog.getStackTraceString(throwable)}\n"
                    } else {
                        "$timestamp $level $tag: $message\n"
                    }
                val bytes = line.toByteArray(Charsets.UTF_8)
                // Lock on a dedicated lock file so rotation and write are atomic
                // across OS processes (main + callkeep_core). FileChannel.lock() is
                // OS-level and works across processes, unlike @Synchronized.
                FileOutputStream(lockFile, true).use { lockFos ->
                    lockFos.channel.lock().use {
                        LogFileRotator.rotateIfNeeded(logFile)
                        FileOutputStream(logFile, true).use { fos ->
                            fos.write(bytes)
                            fos.flush()
                            if (type == LogType.ERROR || type == LogType.WARN) {
                                fos.fd.sync()
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                AndroidLog.e(GLOBAL_PREFIX, "writeToFile failed for $path", e)
            }
        }

        @JvmStatic
        fun e(
            tag: String,
            message: String,
            throwable: Throwable? = null,
        ) = log(LogType.ERROR, tag, message, throwable)

        @JvmStatic
        fun d(
            tag: String,
            message: String,
        ) = log(LogType.DEBUG, tag, message)

        @JvmStatic
        fun i(
            tag: String,
            message: String,
        ) = log(LogType.INFO, tag, message)

        @JvmStatic
        fun w(
            tag: String,
            message: String,
            throwable: Throwable? = null,
        ) = log(LogType.WARN, tag, message, throwable)

        @JvmStatic
        fun v(
            tag: String,
            message: String,
        ) = log(LogType.VERBOSE, tag, message)
    }
}
