package com.webtrit.phone_link

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.ContextCompat
import androidx.wear.remote.interactions.RemoteActivityHelper
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Opens a link on the phone the watch is paired with, through the Wear OS remote activity helper.
 *
 * Answers true once the phone has taken the intent, false when it could not be delivered - no
 * phone paired or in reach, or the phone refused it. Nothing is opened on the watch itself.
 */
class PhoneLinkPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private companion object {
        const val CHANNEL_NAME = "phone_link"
        const val METHOD_OPEN = "open"
    }

    private lateinit var context: Context
    private lateinit var channel: MethodChannel

    // One helper for the plugin's life, on a thread of its own as the library asks; the answer goes back to
    // Flutter on the main thread.
    private lateinit var executor: ExecutorService
    private lateinit var helper: RemoteActivityHelper

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        executor = Executors.newSingleThreadExecutor()
        helper = RemoteActivityHelper(context, executor)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != METHOD_OPEN) {
            result.notImplemented()
            return
        }
        val url = call.arguments as? String
        if (url == null) {
            result.error("bad_argument", "open takes a url", null)
            return
        }
        val intent = Intent(Intent.ACTION_VIEW)
            .addCategory(Intent.CATEGORY_BROWSABLE)
            .setData(Uri.parse(url))
        val mainExecutor = ContextCompat.getMainExecutor(context)
        try {
            val future = helper.startRemoteActivity(intent)
            future.addListener({
                val delivered = try {
                    future.get()
                    true
                } catch (e: Exception) {
                    false
                }
                result.success(delivered)
            }, mainExecutor)
        } catch (e: Exception) {
            result.success(false)
        }
    }
}
